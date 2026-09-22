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
 * Owns the ARCore [Session]. Every failure path is now recorded in [lastError]
 * and reported to the Flutter UI via ArView.postStatus.
 */
class ArSessionManager(private val activity: Activity) {

    val displayRotationHelper = DisplayRotationHelper(activity)

    var session: Session? = null
        private set

    private var installRequested = false

    var lastError: String? = null
        private set

    fun resume() {
        if (session != null) {
            displayRotationHelper.onResume()
            return
        }

        try {
            val availability = ArCoreApk.getInstance().checkAvailability(activity)
            if (availability.isTransient) {
                lastError = "Checking ARCore availability… please retry in a moment."
                return
            }

            val installStatus = ArCoreApk.getInstance()
                .requestInstall(activity, !installRequested)
            when (installStatus) {
                ArCoreApk.InstallStatus.INSTALL_REQUESTED -> {
                    installRequested = true
                    lastError = "ARCore installation required. " +
                        "Install 'Google Play Services for AR' from the " +
                        "Play Store, then reopen this screen."
                    return
                }
                ArCoreApk.InstallStatus.INSTALLED -> Unit
                null -> {
                    lastError = "ARCore availability unknown. Try again."
                    return
                }
            }

            if (ContextCompat.checkSelfPermission(
                    activity, Manifest.permission.CAMERA
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                lastError = "Camera permission denied. " +
                    "Grant camera access in Settings and reopen."
                return
            }

            val newSession = Session(activity)

            val config = Config(newSession).apply {
                planeFindingMode = Config.PlaneFindingMode.HORIZONTAL
                lightEstimationMode = Config.LightEstimationMode.DISABLED
                updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
                focusMode = Config.FocusMode.AUTO
                depthMode = Config.DepthMode.AUTOMATIC
            }
            newSession.configure(config)

            try {
                val geoConfig = newSession.config
                geoConfig.geospatialMode = Config.GeospatialMode.ENABLED
                newSession.configure(geoConfig)
            } catch (e: Exception) {
                // Geospatial optional — ignore on unsupported devices.
            }

            session = newSession
            lastError = null
        } catch (e: UnavailableArcoreNotInstalledException) {
            lastError = "ARCore is not installed. Open the Play Store and " +
                "install 'Google Play Services for AR'."
        } catch (e: UnavailableApkTooOldException) {
            lastError = "Google Play Services for AR is out of date. " +
                "Update it in the Play Store."
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
