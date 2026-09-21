package com.cranear.crane_ar.ar

import android.opengl.GLES20
import android.opengl.Matrix
import com.google.ar.core.Anchor
import com.google.ar.core.TrackingState
import java.nio.FloatBuffer

/**
 * Renders the world-space crane reference marker, the work-radius circle and
 * the planning-boundary circle. Everything is drawn in the anchor's local
 * coordinate frame, so it stays locked to the physical ground.
 */
class SceneRenderer {

    private val colorProgram = ColorProgram()

    private val anchorMatrix = FloatArray(16)
    private val modelViewProjection = FloatArray(16)

    // Cached geometry — rebuilt only when the radius actually changes.
    private var workRingRadius = -1f
    private var workRingBuffer: FloatBuffer? = null

    private var boundaryRingRadius = -1f
    private var boundaryRingBuffer: FloatBuffer? = null

    private val poleBuffer: FloatBuffer =
        GeometryBuilder.directBuffer(GeometryBuilder.buildPole(1.30f, 0.035f))

    private val baseDiscBuffer: FloatBuffer =
        GeometryBuilder.directBuffer(GeometryBuilder.buildDisc(0.20f, 48, 0.012f))

    private val crossBuffer: FloatBuffer =
        GeometryBuilder.directBuffer(
            GeometryBuilder.buildGroundCross(0.55f, 0.035f, 0.012f)
        )

    private val baseRingBuffer: FloatBuffer =
        GeometryBuilder.directBuffer(
            GeometryBuilder.buildRing(0.26f, 0.035f, 64, 0.014f)
        )

    fun createOnGlThread() {
        colorProgram.create()
    }

    fun draw(
        anchor: Anchor,
        state: ArSceneState,
        viewProjectionMatrix: FloatArray
    ) {
        if (anchor.trackingState != TrackingState.TRACKING) return

        anchor.pose.toMatrix(anchorMatrix, 0)
        Matrix.multiplyMM(
            modelViewProjection, 0, viewProjectionMatrix, 0, anchorMatrix, 0
        )

        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
        GLES20.glDisable(GLES20.GL_DEPTH_TEST)
        GLES20.glDepthMask(false)

        colorProgram.use()
        colorProgram.setMvp(modelViewProjection)

        // ---- Reference marker -------------------------------------------------
        colorProgram.setColor(1.0f, 0.70f, 0.0f, 1.0f)
        colorProgram.bindPosition(baseDiscBuffer)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_FAN, 0, baseDiscBuffer.capacity() / 3)

        colorProgram.setColor(1.0f, 1.0f, 1.0f, 0.95f)
        colorProgram.bindPosition(crossBuffer)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLES, 0, crossBuffer.capacity() / 3)

        colorProgram.setColor(1.0f, 0.70f, 0.0f, 0.95f)
        colorProgram.bindPosition(poleBuffer)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLES, 0, poleBuffer.capacity() / 3)

        colorProgram.setColor(1.0f, 0.85f, 0.25f, 0.9f)
        colorProgram.bindPosition(baseRingBuffer)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, baseRingBuffer.capacity() / 3)

        // ---- Planning boundary (outer) ---------------------------------------
        if (state.showBoundary && state.boundaryRadius > 0.01f) {
            val buffer = boundaryBufferFor(state.boundaryRadius)
            colorProgram.setColor(0.21f, 0.76f, 1.0f, 0.85f)
            colorProgram.bindPosition(buffer)
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, buffer.capacity() / 3)
        }

        // ---- Work radius (inner) ---------------------------------------------
        if (state.workRadius > 0.01f) {
            val buffer = workBufferFor(state.workRadius)
            colorProgram.setColor(1.0f, 0.70f, 0.0f, 0.95f)
            colorProgram.bindPosition(buffer)
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, buffer.capacity() / 3)
        }

        GLES20.glDepthMask(true)
        GLES20.glEnable(GLES20.GL_DEPTH_TEST)
        GLES20.glDisable(GLES20.GL_BLEND)
    }

    private fun workBufferFor(radius: Float): FloatBuffer {
        if (workRingBuffer == null || kotlin.math.abs(workRingRadius - radius) > 0.001f) {
            val halfWidth = (radius * 0.006f).coerceAtLeast(0.045f)
            val segments = segmentsFor(radius)
            workRingBuffer = GeometryBuilder.directBuffer(
                GeometryBuilder.buildRing(radius, halfWidth, segments, 0.020f)
            )
            workRingRadius = radius
        }
        return workRingBuffer!!
    }

    private fun boundaryBufferFor(radius: Float): FloatBuffer {
        if (boundaryRingBuffer == null ||
            kotlin.math.abs(boundaryRingRadius - radius) > 0.001f
        ) {
            val halfWidth = (radius * 0.007f).coerceAtLeast(0.055f)
            val segments = segmentsFor(radius)
            boundaryRingBuffer = GeometryBuilder.directBuffer(
                GeometryBuilder.buildRing(radius, halfWidth, segments, 0.022f)
            )
            boundaryRingRadius = radius
        }
        return boundaryRingBuffer!!
    }

    private fun segmentsFor(radius: Float): Int =
        (radius * 12f).toInt().coerceIn(64, 256)
}
