package com.cranear.crane_ar.ar

import android.opengl.GLES11Ext
import android.opengl.GLES20
import com.google.ar.core.Frame
import java.nio.FloatBuffer

/**
 * Draws the live camera feed as a full-screen textured quad.
 */
class BackgroundRenderer {

    var textureId: Int = -1
        private set

    private var program = 0
    private var aPosition = 0
    private var aTexCoord = 0
    private var uTexture = 0

    private val quadCoords = floatArrayOf(
        -1f, -1f, 0f,
         1f, -1f, 0f,
        -1f,  1f, 0f,
         1f,  1f, 0f
    )

    private val quadTexCoords = floatArrayOf(
        0f, 0f,
        1f, 0f,
        0f, 1f,
        1f, 1f
    )

    private val quadCoordsBuffer: FloatBuffer = GeometryBuilder.directBuffer(quadCoords)
    private val quadTexCoordsBuffer: FloatBuffer = GeometryBuilder.directBuffer(quadTexCoords)
    private val transformedTexCoords = FloatArray(8)
    private val transformedTexCoordsBuffer: FloatBuffer =
        GeometryBuilder.directBuffer(transformedTexCoords)

    fun createOnGlThread() {
        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        textureId = textures[0]
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE
        )
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE
        )
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST
        )
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_NEAREST
        )

        program = ShaderUtil.createProgram(VERTEX_SHADER, FRAGMENT_SHADER)
        aPosition = GLES20.glGetAttribLocation(program, "a_Position")
        aTexCoord = GLES20.glGetAttribLocation(program, "a_TexCoord")
        uTexture = GLES20.glGetUniformLocation(program, "u_Texture")
    }

    fun draw(frame: Frame) {
        if (frame.hasDisplayGeometryChanged()) {
            frame.transformDisplayUvCoords(
                quadTexCoordsBuffer, transformedTexCoordsBuffer
            )
        }

        GLES20.glDisable(GLES20.GL_DEPTH_TEST)
        GLES20.glDepthMask(false)
        GLES20.glDisable(GLES20.GL_BLEND)

        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glUseProgram(program)
        GLES20.glUniform1i(uTexture, 0)

        quadCoordsBuffer.position(0)
        GLES20.glEnableVertexAttribArray(aPosition)
        GLES20.glVertexAttribPointer(
            aPosition, 3, GLES20.GL_FLOAT, false, 0, quadCoordsBuffer
        )

        transformedTexCoordsBuffer.position(0)
        GLES20.glEnableVertexAttribArray(aTexCoord)
        GLES20.glVertexAttribPointer(
            aTexCoord, 2, GLES20.GL_FLOAT, false, 0, transformedTexCoordsBuffer
        )

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glDisableVertexAttribArray(aPosition)
        GLES20.glDisableVertexAttribArray(aTexCoord)
        GLES20.glDepthMask(true)
    }

    companion object {
        private const val VERTEX_SHADER = """
            attribute vec4 a_Position;
            attribute vec2 a_TexCoord;
            varying vec2 v_TexCoord;
            void main() {
                v_TexCoord = a_TexCoord;
                gl_Position = a_Position;
            }
        """

        private const val FRAGMENT_SHADER = """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;
            varying vec2 v_TexCoord;
            uniform samplerExternalOES u_Texture;
            void main() {
                gl_FragColor = texture2D(u_Texture, v_TexCoord);
            }
        """
    }
}
