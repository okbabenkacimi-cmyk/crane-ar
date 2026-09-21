package com.cranear.crane_ar.ar

import android.content.Context
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.opengl.Matrix
import com.google.ar.core.Anchor
import com.google.ar.core.Config
import com.google.ar.core.Frame
import com.google.ar.core.Plane
import com.google.ar.core.TrackingFailureReason
import com.google.ar.core.TrackingState
import com.google.ar.core.exceptions.CameraNotAvailableException
import com.google.ar.core.exceptions.NotYetAvailableException
import java.util.concurrent.atomic.AtomicBoolean
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

/**
 * The AR render loop. Runs on the GL thread.
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

    private val surfaceReady = AtomicBoolean(false)

    private var lastReportedSignature: String = ""
    private var lastReportMillis: Long = 0L

    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES20.glClearColor(0f, 0f, 0f, 1f)

        backgroundRenderer.createOnGlThread()
        planeRenderer.createOnGlThread()
        sceneRenderer.createOnGlThread()

        sessionManager.displayRotationHelper.onSurfaceChanged(viewportWidth, viewportHeight)
        surfaceReady.set(true)
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

            if (camera.trackingState == TrackingState.PAUSED) {
                reportStatus(frame, horizontalPlaneCount(frame), hasReference = false)
                return
            }

            // ---- Camera background -------------------------------------------
            backgroundRenderer.draw(frame)

            // ---- Matrices ----------------------------------------------------
            camera.getProjectionMatrix(projectionMatrix, 0, 0.05f, 100f)
            camera.getViewMatrix(viewMatrix, 0)
            Matrix.multiplyMM(
                viewProjectionMatrix, 0, projectionMatrix, 0, viewMatrix, 0
            )

            // ---- Handle user input -------------------------------------------
            processPendingInput(frame)

            // ---- Detected planes ---------------------------------------------
            planeRenderer.draw(frame, viewProjectionMatrix)

            // ---- Anchor + world-space circles --------------------------------
            val anchor = sceneState.referenceAnchor
            var referenceTracking = false
            if (anchor != null) {
                referenceTracking = anchor.trackingState == TrackingState.TRACKING
                sceneRenderer.draw(anchor, sceneState, viewProjectionMatrix)
            }

            // ---- Status ------------------------------------------------------
            reportStatus(
                frame = frame,
                planeCount = horizontalPlaneCount(frame),
                hasReference = anchor != null,
                referenceTracking = referenceTracking
            )
        } catch (e: CameraNotAvailableException) {
            emitStatus(
                tracking = "TRACKING_LOST",
                ground = "NO_GROUND_DETECTED",
                planes = 0,
                hasReference = sceneState.referenceAnchor != null,
                referenceTracking = false,
                force = true
            )
        }
    }

    // -----------------------------------------------------------------------

    private fun processPendingInput(frame: Frame) {
        if (sceneState.pendingCentreHitTest) {
            sceneState.pendingCentreHitTest = false
            placeReference(
                frame,
                viewportWidth / 2f,
                viewportHeight / 2f,
                requireGroundPlane = true
            )
            return
        }
        val tap = sceneState.consumeTap() ?: return
        placeReference(frame, tap.first, tap.second, requireGroundPlane = true)
    }

    private fun placeReference(
        frame: Frame,
        xPx: Float,
        yPx: Float,
        requireGroundPlane: Boolean
    ) {
        try {
            val hitResults = frame.hitTest(xPx, yPx)
            for (hit in hitResults) {
                val trackable = hit.trackable
                if (trackable is Plane) {
                    val validPose =
                        trackable.isPoseInPolygon(hit.hitPose) ||
                        trackable.isPoseInExtents(hit.hitPose)
                    val isGround =
                        !requireGroundPlane ||
                        trackable.type == Plane.Type.HORIZONTAL_UPWARD_FACING
                    if (validPose && isGround &&
                        trackable.trackingState == TrackingState.TRACKING
                    ) {
                        sceneState.referenceAnchor?.detach()
                        sceneState.referenceAnchor = hit.createAnchor()
                        ArCoreHolder.currentView?.onReferenceEstablished()
                        return
                    }
                }
            }
        } catch (e: NotYetAvailableException) {
            // Frame data not ready — drop this tap silently.
        } catch (e: Exception) {
            // Ignore malformed hit results.
        }
    }

    private fun horizontalPlaneCount(frame: Frame): Int {
        var count = 0
        for (plane in frame.getUpdatedTrackables(Plane::class.java)) {
            if (plane.trackingState == TrackingState.TRACKING &&
                plane.type == Plane.Type.HORIZONTAL_UPWARD_FACING
            ) {
                count++
            }
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
                if (camera.trackingFailureReason == TrackingFailureReason.NONE) {
                    "GOOD"
                } else {
                    "LIMITED"
                }
            TrackingState.PAUSED -> "LIMITED"
            TrackingState.STOPPED -> "TRACKING_LOST"
            else -> "TRACKING_LOST"
        }

        val ground: String =
            if (tracking == "TRACKING_LOST") "NO_GROUND_DETECTED"
            else if (planeCount > 0) "DETECTED"
            else "NO_GROUND_DETECTED"

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

        if (!force && signature == lastReportedSignature && now - lastReportMillis < 800L) {
            return
        }
        lastReportedSignature = signature
        lastReportMillis = now

        ArCoreHolder.currentView?.postStatus(
            mapOf(
                "event" to "status",
                "tracking" to tracking,
                "ground" to ground,
                "horizontalPlanes" to planes,
                "hasReference" to hasReference,
                "referenceTracking" to referenceTracking
            )
        )
    }
}
