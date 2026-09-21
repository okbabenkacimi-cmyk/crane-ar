package com.cranear.crane_ar.ar

import android.opengl.GLES20
import android.opengl.Matrix
import com.google.ar.core.Frame
import com.google.ar.core.Plane
import com.google.ar.core.TrackingState

/**
 * Visualises detected horizontal planes as translucent filled polygons.
 */
class PlaneRenderer {

    private val colorProgram = ColorProgram()

    private val planeMatrix = FloatArray(16)
    private val modelViewProjection = FloatArray(16)

    fun createOnGlThread() {
        colorProgram.create()
    }

    fun draw(frame: Frame, viewProjectionMatrix: FloatArray) {
        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
        GLES20.glDepthMask(false)

        colorProgram.use()

        for (plane in frame.getUpdatedTrackables(Plane::class.java)) {
            if (plane.trackingState != TrackingState.TRACKING) continue
            if (plane.type != Plane.Type.HORIZONTAL_UPWARD_FACING) continue

            val polygon = try {
                plane.polygon
            } catch (e: Exception) {
                continue
            }
            val vertices = GeometryBuilder.buildPlanePolygon(polygon, 0.001f)
            if (vertices.isEmpty()) continue

            plane.centerPose.toMatrix(planeMatrix, 0)
            Matrix.multiplyMM(
                modelViewProjection, 0, viewProjectionMatrix, 0, planeMatrix, 0
            )

            colorProgram.setMvp(modelViewProjection)
            colorProgram.setColor(0.21f, 0.76f, 1.0f, 0.10f)
            colorProgram.bindPosition(GeometryBuilder.directBuffer(vertices))
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_FAN, 0, vertices.size / 3)
        }

        GLES20.glDepthMask(true)
        GLES20.glDisable(GLES20.GL_BLEND)
    }
}
