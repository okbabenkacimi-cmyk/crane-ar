package com.cranear.crane_ar.ar

import com.google.ar.core.Anchor

/**
 * Shared, thread-safe state between the Flutter-controlled bridge and the
 * GL renderer. Written from the main thread, read from the GL thread.
 */
class ArSceneState {
    @Volatile
    var referenceAnchor: Anchor? = null

    @Volatile
    var workRadius: Float = 0f

    @Volatile
    var boundaryRadius: Float = 0f

    @Volatile
    var showBoundary: Boolean = true

    /** Pending tap coordinates in pixels; -1 means "no tap". */
    @Volatile
    var pendingTapX: Float = -1f

    @Volatile
    var pendingTapY: Float = -1f

    /** When true, the next frame hit-tests the screen centre instead of a tap. */
    @Volatile
    var pendingCentreHitTest: Boolean = false

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
