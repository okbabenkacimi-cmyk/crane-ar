package com.cranear.crane_ar.ar

import android.opengl.GLES20
import java.nio.FloatBuffer

/**
 * Minimal unlit colour program used for world-space markers, rings and planes.
 */
class ColorProgram {

    var program: Int = 0
        private set
    private var aPosition = 0
    private var uMvpMatrix = 0
    private var uColor = 0

    fun create() {
        program = ShaderUtil.createProgram(VERTEX_SHADER, FRAGMENT_SHADER)
        aPosition = GLES20.glGetAttribLocation(program, "a_Position")
        uMvpMatrix = GLES20.glGetUniformLocation(program, "u_MvpMatrix")
        uColor = GLES20.glGetUniformLocation(program, "u_Color")
    }

    fun use() {
        GLES20.glUseProgram(program)
    }

    fun setMvp(matrix: FloatArray) {
        GLES20.glUniformMatrix4fv(uMvpMatrix, 1, false, matrix, 0)
    }

    fun setColor(r: Float, g: Float, b: Float, a: Float) {
        GLES20.glUniform4f(uColor, r, g, b, a)
    }

    fun bindPosition(buffer: FloatBuffer) {
        GLES20.glEnableVertexAttribArray(aPosition)
        GLES20.glVertexAttribPointer(
            aPosition, 3, GLES20.GL_FLOAT, false, 0, buffer
        )
    }

    companion object {
        private const val VERTEX_SHADER = """
            uniform mat4 u_MvpMatrix;
            attribute vec4 a_Position;
            void main() {
                gl_Position = u_MvpMatrix * a_Position;
            }
        """

        private const val FRAGMENT_SHADER = """
            precision mediump float;
            uniform vec4 u_Color;
            void main() {
                gl_FragColor = u_Color;
            }
        """
    }
}
