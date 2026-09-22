package com.cranear.crane_ar.ar

import com.google.ar.core.Anchor

/**
 * Shared state between the Flutter-controlled bridge and the GL renderer.
 * Written from the main thread, read from the GL thread.
 */
class ArSceneState {

    // ---- Crane reference (slew centre) -----------------------------------
    @Volatile
    var referenceAnchor: Anchor? = null

    // ---- World-space radii -----------------------------------------------
    @Volatile
    var workRadius: Float = 0f

    @Volatile
    var boundaryRadius: Float = 0f

    @Volatile
    var showBoundary: Boolean = true

    /** Planning margin M in metres (mirrored from Flutter). */
    @Volatile
    var boundaryRadiusExtra: Float = 2f

    // ---- Boom geometry (computed by the renderer) ------------------------
    /** Boom length L in metres (mirrored from Flutter). */
    @Volatile
    var boomLength: Float = 20f

    /** Boom elevation above horizontal, degrees. 0 = horizontal, 90 = vertical. */
    @Volatile
    var boomAngleDegrees: Float = 0f

    /** Height of the boom tip above the slew anchor, metres. */
    @Volatile
    var boomTipOffsetY: Float = 0f

    // ---- Pending user input ----------------------------------------------
    @Volatile
    var pendingTapX: Float = -1f

    @Volatile
    var pendingTapY: Float = -1f

    @Volatile
    var pendingCentreHitTest: Boolean = false

    @Volatile
    var pendingBoomTipCapture: Boolean = false

    fun queueTap(x: Float, y: Float) {
        pendingTapX = x
        pendingTapY = y
    }

    fun consumeTap(): Pair<Float, Float>? {
        val x = pendingTapX
        val y = pendingTapY
        if (x < 0f || y < 0f) return null
        pendingTapX = -1f
        pendingTapY = -1f
        return Pair(x, y)
    }
}
