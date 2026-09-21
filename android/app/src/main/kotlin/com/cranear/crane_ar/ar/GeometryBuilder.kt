package com.cranear.crane_ar.ar

import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import kotlin.math.cos
import kotlin.math.sin

object GeometryBuilder {

    fun directBuffer(data: FloatArray): FloatBuffer =
        ByteBuffer.allocateDirect(data.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply {
                put(data)
                position(0)
            }

    /**
     * Builds a horizontal annulus (thick ring) centred on the origin in the XZ
     * plane. Suitable for GL_TRIANGLE_STRIP with (segments + 1) * 2 vertices.
     */
    fun buildRing(
        radius: Float,
        halfWidth: Float,
        segments: Int,
        y: Float
    ): FloatArray {
        val safeSegments = segments.coerceAtLeast(8)
        val inner = (radius - halfWidth).coerceAtLeast(0f)
        val outer = radius + halfWidth
        val vertexCount = (safeSegments + 1) * 2
        val out = FloatArray(vertexCount * 3)
        var i = 0
        for (s in 0..safeSegments) {
            val a = (2.0 * Math.PI * s / safeSegments).toFloat()
            val c = cos(a)
            val sn = sin(a)
            out[i++] = inner * c
            out[i++] = y
            out[i++] = inner * sn
            out[i++] = outer * c
            out[i++] = y
            out[i++] = outer * sn
        }
        return out
    }

    /**
     * Builds a filled disc (GL_TRIANGLE_FAN) of the given radius.
     */
    fun buildDisc(radius: Float, segments: Int, y: Float): FloatArray {
        val safeSegments = segments.coerceAtLeast(8)
        val out = FloatArray((safeSegments + 2) * 3)
        var i = 0
        out[i++] = 0f
        out[i++] = y
        out[i++] = 0f
        for (s in 0..safeSegments) {
            val a = (2.0 * Math.PI * s / safeSegments).toFloat()
            out[i++] = radius * cos(a)
            out[i++] = y
            out[i++] = radius * sin(a)
        }
        return out
    }

    /**
     * Two perpendicular vertical quads forming a visible pole marker.
     * Suitable for GL_TRIANGLES (12 vertices).
     */
    fun buildPole(height: Float, halfWidth: Float): FloatArray {
        val w = halfWidth
        val h = height
        return floatArrayOf(
            // XY plane quad
            -w, 0f, 0f, w, 0f, 0f, -w, h, 0f,
            w, 0f, 0f, w, h, 0f, -w, h, 0f,
            // ZY plane quad
            0f, 0f, -w, 0f, 0f, w, 0f, h, -w,
            0f, 0f, w, 0f, h, w, 0f, h, -w
        )
    }

    /**
     * Crosshair bars lying flat on the ground: 2 quads, GL_TRIANGLES (12 verts).
     */
    fun buildGroundCross(armLength: Float, halfWidth: Float, y: Float): FloatArray {
        val a = armLength
        val w = halfWidth
        return floatArrayOf(
            // X bar
            -a, y, -w, a, y, -w, -a, y, w,
            a, y, -w, a, y, w, -a, y, w,
            // Z bar
            -w, y, -a, w, y, -a, -w, y, a,
            w, y, -a, w, y, a, -w, y, a
        )
    }

    /** Builds a filled polygon (triangle fan) from plane-local (x, z) pairs. */
    fun buildPlanePolygon(polygon: FloatBuffer, y: Float): FloatArray {
        val count = polygon.remaining() / 2
        if (count < 3) return FloatArray(0)
        val out = FloatArray((count + 2) * 3)
        var i = 0
        out[i++] = 0f
        out[i++] = y
        out[i++] = 0f
        val dup = polygon.duplicate()
        dup.rewind()
        for (p in 0 until count) {
            val x = dup.get()
            val z = dup.get()
            out[i++] = x
            out[i++] = y
            out[i++] = z
        }
        // Close the fan.
        dup.rewind()
        out[i++] = dup.get()
        out[i++] = y
        out[i++] = dup.get()
        return out
    }
}
