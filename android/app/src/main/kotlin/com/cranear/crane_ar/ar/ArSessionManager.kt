package com.cranear.crane_ar.ar

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import com.google.ar.core.ArCoreApk
import com.google.ar.core.Config
import com.google.ar.core.Session
import com.google.ar.core.exceptions.UnavailableApkTooOldException
import com.google.ar.core.exceptions.UnavailableArcoreNotInstalledException
import com.google.ar.core.exceptions.UnavailableDeviceNotCompatibleException
import com.google.ar.core.exceptions.UnavailableSdkTooOldException

/**
 * Owns the ARCore [Session] and its configuration.
 *
 * This version enables:
 *  - Raw Depth API (Config.DepthMode.AUTOMATIC) so the renderer can read
 *    per-pixel confidence and reject unreliable depth readings.
 *  - Geospatial mode (VPS) where supported, giving longer-range depth on
 *    sites with Google Street View coverage.
 *  - Instant Placement disabled, which removes a common source of
 *    unreliable anchors on featureless ground.
 */
class ArSessionManager(private val activity: Activity) {

    val displayRotationHelper = DisplayRotationHelper(activity)

    var session: Session? = null
        private set

    private var installRequested = false

    /** Thrown out to the caller so the UI can surface a readable message. */
    var lastError: String? = null
        private set

    fun resume() {
        if (session != null) {
            displayRotationHelper.onResume()
            return
        }

        try {
            when (ArCoreApk.getInstance().requestInstall(activity, !installRequested)) {
                ArCoreApk.InstallStatus.INSTALL_REQUESTED -> {
                    installRequested = true
                    return
                }
                ArCoreApk.InstallStatus.INSTALLED -> Unit
                null -> return
            }

            if (ContextCompat.checkSelfPermission(
                    activity, Manifest.permission.CAMERA
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                lastError = "Camera permission not granted."
                return
            }

            val newSession = Session(activity)

            val config = Config(newSession).apply {
                planeFindingMode = Config.PlaneFindingMode.HORIZONTAL
                lightEstimationMode = Config.LightEstimationMode.DISABLED
                updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
                focusMode = Config.FocusMode.AUTO

                // NEW — enable the Raw Depth API so ArRenderer can filter
                // depth readings by confidence on featureless ground.
                depthMode = Config.DepthMode.AUTOMATIC
            }
            newSession.configure(config)

            // NEW — try to enable Geospatial (VPS) mode for longer-range depth.
            // Not all devices / ARCore versions support it; safe to ignore.
            try {
                val geoConfig = newSession.config
                geoConfig.geospatialMode = Config.GeospatialMode.ENABLED
                newSession.configure(geoConfig)
            } catch (e: Exception) {
                // Geospatial mode unsupported here — continue without it.
            }

            session = newSession
            lastError = null
        } catch (e: UnavailableArcoreNotInstalledException) {
            lastError = "ARCore is not installed on this device."
        } catch (e: UnavailableApkTooOldException) {
            lastError = "Google Play Services for AR is out of date."
        } catch (e: UnavailableSdkTooOldException) {
            lastError = "This app's ARCore SDK is too old."
        } catch (e: UnavailableDeviceNotCompatibleException) {
            lastError = "This device is not compatible with ARCore."
        } catch (e: Exception) {
            lastError = "ARCore session creation failed: ${e.message}"
        }

        displayRotationHelper.onResume()
    }

    fun pause() {
        displayRotationHelper.onPause()
    }

    fun destroy() {
        session?.close()
        session = null
    }
}
