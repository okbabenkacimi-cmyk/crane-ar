package com.cranear.crane_ar.ar

import android.content.Context
import android.hardware.display.DisplayManager
import android.view.Display
import android.view.WindowManager
import com.google.ar.core.Session

/**
 * Tracks the device display rotation and viewport size so ARCore can be told
 * about geometry changes only when they actually happen.
 */
class DisplayRotationHelper(context: Context) : DisplayManager.DisplayListener {

    private val displayManager =
        context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

    @Suppress("DEPRECATION")
    private val defaultDisplay: Display =
        (context.getSystemService(Context.WINDOW_SERVICE) as WindowManager).defaultDisplay

    private var viewportChanged = false
    private var viewportWidth = 0
    private var viewportHeight = 0

    fun onResume() {
        displayManager.registerDisplayListener(this, null)
        viewportChanged = true
    }

    fun onPause() {
        displayManager.unregisterDisplayListener(this)
    }

    fun onSurfaceChanged(width: Int, height: Int) {
        viewportWidth = width
        viewportHeight = height
        viewportChanged = true
    }

    fun updateSessionIfNeeded(session: Session) {
        if (viewportChanged && viewportWidth > 0 && viewportHeight > 0) {
            session.setDisplayGeometry(
                getDisplayRotation(), viewportWidth, viewportHeight
            )
            viewportChanged = false
        }
    }

    @Suppress("DEPRECATION")
    fun getDisplayRotation(): Int = defaultDisplay.rotation

    override fun onDisplayAdded(displayId: Int) = Unit
    override fun onDisplayRemoved(displayId: Int) = Unit
    override fun onDisplayChanged(displayId: Int) {
        viewportChanged = true
    }
}
