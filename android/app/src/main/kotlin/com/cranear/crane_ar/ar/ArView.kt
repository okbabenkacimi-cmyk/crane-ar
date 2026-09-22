package com.cranear.crane_ar.ar

import android.app.Activity
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.opengl.GLSurfaceView
import android.view.MotionEvent
import android.view.View
import io.flutter.plugin.platform.PlatformView

/**
 * Hybrid-composition PlatformView hosting the ARCore GLSurfaceView.
 *
 * FIX: previously this class set PixelFormat.TRANSLUCENT on the surface,
 * which made the camera feed invisible (rendered fully transparent on top
 * of Flutter's black background). It is now OPAQUE.
 */
class ArView(private val activity: Activity) : PlatformView {

    private val mainHandler = Handler(Looper.getMainLooper())

    private val sceneState = ArSceneState()
    private val sessionManager = ArSessionManager(activity)

    private val glSurfaceView = GLSurfaceView(activity)
    private val renderer: ArRenderer

    private var attached = false

    init {
        glSurfaceView.preserveEGLContextOnPause = true
        glSurfaceView.setEGLContextClientVersion(2)
        glSurfaceView.setEGLConfigChooser(8, 8, 8, 8, 16, 0)

        // THE FIX — was TRANSLUCENT before, which hid the camera feed.
        glSurfaceView.holder.setFormat(PixelFormat.OPAQUE)

        renderer = ArRenderer(activity, sessionManager, sceneState)
        glSurfaceView.setRenderer(renderer)
        glSurfaceView.renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY

        glSurfaceView.setOnTouchListener { _: View, event: MotionEvent ->
            if (event.actionMasked == MotionEvent.ACTION_UP) {
                sceneState.queueTap(event.x, event.y)
            }
            true
        }

        ArCoreHolder.currentView = this
    }

    override fun getView(): View = glSurfaceView

    override fun onFlutterViewAttached(flutterView: View) {
        attached = true
        glSurfaceView.onResume()
        sessionManager.resume()
        sessionManager.lastError?.let { error ->
            postStatus(mapOf("event" to "error", "message" to error))
        }
    }

    override fun onFlutterViewDetached() {
        attached = false
        sessionManager.pause()
        glSurfaceView.onPause()
    }

    override fun dispose() {
        if (ArCoreHolder.currentView === this) {
            ArCoreHolder.currentView = null
        }
        sceneState.referenceAnchor?.detach()
        sceneState.referenceAnchor = null
        sessionManager.pause()
        sessionManager.destroy()
        glSurfaceView.onPause()
    }

    fun updateRadii(work: Float, boundary: Float, showBoundary: Boolean) {
        sceneState.workRadius = work
        sceneState.boundaryRadius = boundary
        sceneState.showBoundary = showBoundary
    }

    fun resetReference() {
        sceneState.referenceAnchor?.detach()
        sceneState.referenceAnchor = null
        sceneState.boomTipOffsetY = 0f
        sceneState.boomAngleDegrees = 0f
        postStatus(
            mapOf(
                "event" to "status",
                "tracking" to "GOOD",
                "ground" to "DETECTED",
                "horizontalPlanes" to 0,
                "hasReference" to false,
                "referenceTracking" to false
            )
        )
    }

    fun confirmReferenceAtScreenCenter(): Boolean {
        if (!attached) return false
        sceneState.pendingCentreHitTest = true
        return true
    }

    /**
     * Tells the renderer to capture the current screen centre as a ray
     * toward the boom tip. The renderer will then compute the boom tip
     * position by intersecting the ray with a sphere of radius L (boom
     * length) centred on the slew anchor.
     */
    fun captureBoomTip(): Boolean {
        if (!attached) return false
        sceneState.pendingBoomTipCapture = true
        return true
    }

    fun onReferenceEstablished() {
        postStatus(mapOf("event" to "reference", "hasReference" to true))
    }

    fun postStatus(payload: Map<String, Any?>) {
        mainHandler.post {
            ArCoreHolder.eventSink?.success(payload)
        }
    }
}
