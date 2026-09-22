package com.cranear.crane_ar.ar

import android.content.Context
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.opengl.Matrix
import com.google.ar.core.Frame
import com.google.ar.core.Plane
import com.google.ar.core.TrackingFailureReason
import com.google.ar.core.TrackingState
import com.google.ar.core.exceptions.CameraNotAvailableException
import com.google.ar.core.exceptions.NotYetAvailableException
import kotlin.math.sqrt
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

/**
 * AR render loop with three user-triggered actions:
 *   1. Tap ground -> place the crane slew-centre anchor.
 *   2. Centre-capture -> cast a ray from the screen centre and solve for
 *      the boom tip position (given L), then derive the elevation angle.
 *   3. Continuously render the work-radius and boundary circles.
 */
class ArRenderer(
    private val context: Context,
    private val sessionManager: ArSessionManager,
    private val sceneState: ArSceneState
) : GLSurfaceView.Renderer {

    private val backgroundRenderer = BackgroundRenderer()
    private val planeRenderer = PlaneRenderer()
    private val sceneRenderer = SceneRenderer()

    private val viewMatrix = FloatArray(16)
    private val projectionMatrix = FloatArray(16)
    private val viewProjectionMatrix = FloatArray(16)

    private var viewportWidth = 1
    private var viewportHeight = 1

    private var lastReportedSignature: String = ""
    private var lastReportMillis: Long = 0L

    private var lastDepthReliableRatio: Float = 1.0f
    private var lastDepthWarningShown: Boolean = false

    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES20.glClearColor(0f, 0f, 0f, 1f)
        backgroundRenderer.createOnGlThread()
        planeRenderer.createOnGlThread()
        sceneRenderer.createOnGlThread()
        sessionManager.displayRotationHelper.onSurfaceChanged(viewportWidth, viewportHeight)
    }

    override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        viewportWidth = width
        viewportHeight = height
        GLES20.glViewport(0, 0, width, height)
        sessionManager.displayRotationHelper.onSurfaceChanged(width, height)
    }

    override fun onDrawFrame(gl: GL10?) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)

        val session = sessionManager.session ?: return
        sessionManager.displayRotationHelper.updateSessionIfNeeded(session)

        try {
            session.setCameraTextureName(backgroundRenderer.textureId)
            val frame = session.update()
            val camera = frame.camera

            lastDepthReliableRatio = measureDepthReliability(frame)
            maybeEmitDepthWarning()

            if (camera.trackingState == TrackingState.PAUSED) {
                reportStatus(frame, horizontalPlaneCount(frame), false)
                return
            }

            // 1. Draw camera feed
            backgroundRenderer.draw(frame)

            // 2. Compute matrices
            camera.getProjectionMatrix(projectionMatrix, 0, 0.05f, 100f)
            camera.getViewMatrix(viewMatrix, 0)
            Matrix.multiplyMM(
                viewProjectionMatrix, 0, projectionMatrix, 0, viewMatrix, 0
            )

            // 3. Handle user input
            processPendingInput(frame)

            // 4. Draw planes + scene
            planeRenderer.draw(frame, viewProjectionMatrix)

            val anchor = sceneState.referenceAnchor
            var referenceTracking = false
            if (anchor != null) {
                referenceTracking = anchor.trackingState == TrackingState.TRACKING
                sceneRenderer.draw(anchor, sceneState, viewProjectionMatrix)
            }

            reportStatus(
                frame,
                horizontalPlaneCount(frame),
                anchor != null,
                referenceTracking
            )
        } catch (e: CameraNotAvailableException) {
            emitStatus(
                "TRACKING_LOST", "NO_GROUND_DETECTED", 0,
                sceneState.referenceAnchor != null, false, true
            )
        }
    }

    // -------------------------------------------------------------------
    // Input handling
    // -------------------------------------------------------------------

    private fun processPendingInput(frame: Frame) {
        // Priority 1: boom tip capture
        if (sceneState.pendingBoomTipCapture) {
            sceneState.pendingBoomTipCapture = false
            captureBoomTip(frame)
            return
        }

        // Priority 2: place slew centre at screen centre
        if (sceneState.pendingCentreHitTest) {
            sceneState.pendingCentreHitTest = false
            placeReference(frame, viewportWidth / 2f, viewportHeight / 2f)
            return
        }

        // Priority 3: user tap
        val tap = sceneState.consumeTap() ?: return
        placeReference(frame, tap.first, tap.second)
    }

    private fun placeReference(frame: Frame, xPx: Float, yPx: Float) {
        try {
            val hits = frame.hitTest(xPx, yPx)
            for (hit in hits) {
                val trackable = hit.trackable
                if (trackable is Plane) {
                    val validPose =
                        trackable.isPoseInPolygon(hit.hitPose) ||
                        trackable.isPoseInExtents(hit.hitPose)
                    if (validPose &&
                        trackable.type == Plane.Type.HORIZONTAL_UPWARD_FACING &&
                        trackable.trackingState == TrackingState.TRACKING
                    ) {
                        sceneState.referenceAnchor?.detach()
                        sceneState.referenceAnchor = hit.createAnchor()
                        sceneState.boomAngleDegrees = 0f
                        sceneState.boomTipOffsetY = 0f
                        ArCoreHolder.currentView?.onReferenceEstablished()
                        return
                    }
                }
            }
        } catch (e: NotYetAvailableException) {
            // drop
        } catch (e: Exception) {
            // drop
        }
    }

    /**
     * Cast a ray from the screen centre and find where it meets a sphere
     * of radius L (boom length) centred on the slew anchor. The intersection
     * point is the boom tip. From it we derive the elevation angle θ.
     */
    private fun captureBoomTip(frame: Frame) {
        val anchor = sceneState.referenceAnchor ?: return
        if (anchor.trackingState != TrackingState.TRACKING) return

        val camera = frame.camera
        val pose = camera.pose

        // Camera world position
        val camX = pose.tx()
        val camY = pose.ty()
        val camZ = pose.tz()

        // Slew-centre world position
        val slew = anchor.pose
        val sx = slew.tx()
        val sy = slew.ty()
        val sz = slew.tz()

        // Ray direction in camera space (through screen centre -> (0,0,-1))
        // Then rotate to world space using the camera quaternion.
        val qx = pose.qx()
        val qy = pose.qy()
        val qz = pose.qz()
        val qw = pose.qw()

        // For screen centre, camera-space direction is simply (0, 0, -1).
        val dirLocalX = 0f
        val dirLocalY = 0f
        val dirLocalZ = -1f

        // Rotate (0,0,-1) by quaternion (qx,qy,qz,qw)
        val w = qw
        val wx = dirLocalX
        val wy = dirLocalY
        val wz = dirLocalZ
        val dx = w * wx + qy * wz - qz * wy
        val dy = w * wy + qz * wx - qx * wz
        val dz = w * wz + qx * wy - qy * wx
        val dw = -qx * wx - qy * wy - qz * wz
        val worldDirX = dx * w + dw * -qx + dy * -qz - dz * -qy
        val worldDirY = dy * w + dw * -qy + dz * -qx - dx * -qz
        val worldDirZ = dz * w + dw * -qz + dx * -qy - dy * -qx

        val len = sqrt(
            (worldDirX * worldDirX + worldDirY * worldDirY + worldDirZ * worldDirZ)
                .toDouble()
        ).toFloat()
        if (len < 1e-6f) return
        val nx = worldDirX / len
        val ny = worldDirY / len
        val nz = worldDirZ / len

        // Solve |camPos + t*dir - slewCentre| = L for t > 0.
        val kx = camX - sx
        val ky = camY - sy
        val kz = camZ - sz

        val b = kx * nx + ky * ny + kz * nz
        val c = kx * kx + ky * ky + kz * kz - sceneState.boomLength * sceneState.boomLength

        val disc = b * b - c
        if (disc < 0f) return

        val sq = sqrt(disc.toDouble()).toFloat()
        val t1 = -b + sq
        val t2 = -b - sq
        val t = if (t1 > 0f) t1 else t2
        if (t <= 0f) return

        // Boom tip world position
        val tipX = camX + t * nx
        val tipY = camY + t * ny
        val tipZ = camZ + t * nz

        // Displacement from slew centre
        val ex = tipX - sx
        val ey = tipY - sy
        val ez = tipZ - sz

        val horizontal = sqrt((ex * ex + ez * ez).toDouble()).toFloat()
        val angleRad = kotlin.math.atan2(ey, horizontal)
        val angleDeg = angleRad * 180f / Math.PI.toFloat()

        val clampedAngle = angleDeg.coerceIn(0f, 90f)

        sceneState.boomAngleDegrees = clampedAngle
        sceneState.boomTipOffsetY = ey
        sceneState.workRadius = sceneState.boomLength * kotlin.math.cos(angleRad)
        sceneState.boundaryRadius = sceneState.workRadius + sceneState.boundaryRadiusExtra

        ArCoreHolder.currentView?.postStatus(
            mapOf(
                "event" to "boomTip",
                "boomAngleDegrees" to clampedAngle,
                "boomTipHeight" to ey,
                "workRadius" to sceneState.workRadius,
                "boundaryRadius" to sceneState.boundaryRadius
            )
        )
    }

    // -------------------------------------------------------------------
    // Depth reliability
    // -------------------------------------------------------------------

    private fun measureDepthReliability(frame: Frame): Float {
        return try {
            val depthImage = frame.acquireRawDepthImage16Bits()
            val confidenceImage = frame.acquireRawDepthConfidenceImage()

            val confidenceBuffer = confidenceImage.planes[0].buffer
            val bytes = ByteArray(confidenceBuffer.remaining())
            confidenceBuffer.get(bytes)

            var reliable = 0
            for (b in bytes) {
                if ((b.toInt() and 0xFF) >= 128) reliable++
            }

            depthImage.close()
            confidenceImage.close()

            if (bytes.isNotEmpty())
                reliable.toFloat() / bytes.size.toFloat() else 0f
        } catch (e: Exception) {
            1.0f
        }
    }

    private fun maybeEmitDepthWarning() {
        val unreliable = lastDepthReliableRatio < 0.20f
        if (unreliable && !lastDepthWarningShown) {
            lastDepthWarningShown = true
            ArCoreHolder.currentView?.postStatus(
                mapOf(
                    "event" to "depthWarning",
                    "message" to "Surface texture too low for accurate depth."
                )
            )
        } else if (!unreliable && lastDepthWarningShown) {
            lastDepthWarningShown = false
            ArCoreHolder.currentView?.postStatus(
                mapOf("event" to "depthOk", "message" to "Depth reliability restored.")
            )
        }
    }

    // -------------------------------------------------------------------
    // Status reporting
    // -------------------------------------------------------------------

    private fun horizontalPlaneCount(frame: Frame): Int {
        var count = 0
        for (plane in frame.getUpdatedTrackables(Plane::class.java)) {
            if (plane.trackingState == TrackingState.TRACKING &&
                plane.type == Plane.Type.HORIZONTAL_UPWARD_FACING
            ) count++
        }
        return count
    }

    private fun reportStatus(
        frame: Frame,
        planeCount: Int,
        hasReference: Boolean,
        referenceTracking: Boolean = false
    ) {
        val camera = frame.camera
        val tracking: String = when (camera.trackingState) {
            TrackingState.TRACKING ->
                if (camera.trackingFailureReason == TrackingFailureReason.NONE) "GOOD" else "LIMITED"
            TrackingState.PAUSED -> "LIMITED"
            TrackingState.STOPPED -> "TRACKING_LOST"
            else -> "TRACKING_LOST"
        }
        val ground = when {
            tracking == "TRACKING_LOST" -> "NO_GROUND_DETECTED"
            planeCount > 0 -> "DETECTED"
            else -> "NO_GROUND_DETECTED"
        }
        emitStatus(tracking, ground, planeCount, hasReference, referenceTracking)
    }

    private fun emitStatus(
        tracking: String,
        ground: String,
        planes: Int,
        hasReference: Boolean,
        referenceTracking: Boolean,
        force: Boolean = false
    ) {
        val now = System.currentTimeMillis()
        val signature = "$tracking|$ground|$planes|$hasReference|$referenceTracking"
        if (!force && signature == lastReportedSignature && now - lastReportMillis < 800L) return
        lastReportedSignature = signature
        lastReportMillis = now

        ArCoreHolder.currentView?.postStatus(
            mapOf(
                "event" to "status",
                "tracking" to tracking,
                "ground" to ground,
                "horizontalPlanes" to planes,
                "hasReference" to hasReference,
                "referenceTracking" to referenceTracking,
                "depthReliability" to lastDepthReliableRatio
            )
        )
    }
}
