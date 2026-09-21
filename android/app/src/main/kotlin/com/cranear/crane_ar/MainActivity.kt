package com.cranear.crane_ar

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.cranear.crane_ar.ar.ArCoreHolder
import com.cranear.crane_ar.ar.ArViewFactory
import com.google.ar.core.ArCoreApk
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ---- Platform view registration (hybrid composition) -----------------
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "crane_ar/ar_view",
            ArViewFactory(this)
        )

        // ---- Event channel: native -> Dart status stream ---------------------
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "crane_ar/events"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                ArCoreHolder.eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                ArCoreHolder.eventSink = null
            }
        })

        // ---- Method channel: Dart -> native commands -------------------------
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "crane_ar/methods"
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "checkArCoreSupport" -> {
                    val availability = ArCoreApk.getInstance()
                        .checkAvailability(this)
                    val supported =
                        availability == ArCoreApk.Availability.SUPPORTED_INSTALLED ||
                        availability == ArCoreApk.Availability.SUPPORTED_APK_TOO_OLD ||
                        availability == ArCoreApk.Availability.SUPPORTED_NOT_INSTALLED
                    result.success(supported)
                }

                "requestCameraPermission" -> requestCameraPermission(result)

                "setRadii" -> {
                    val work = (call.argument<Double>("workRadius") ?: 0.0).toFloat()
                    val boundary =
                        (call.argument<Double>("boundaryRadius") ?: 0.0).toFloat()
                    val show = call.argument<Boolean>("showBoundary") ?: true
                    ArCoreHolder.currentView?.updateRadii(work, boundary, show)
                    result.success(null)
                }

                "resetReference" -> {
                    ArCoreHolder.currentView?.resetReference()
                    result.success(null)
                }

                "confirmReferenceAtCenter" -> {
                    val placed =
                        ArCoreHolder.currentView?.confirmReferenceAtScreenCenter()
                            ?: false
                    result.success(placed)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun requestCameraPermission(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(
                this, Manifest.permission.CAMERA
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CAMERA),
            CAMERA_PERMISSION_REQUEST
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CAMERA_PERMISSION_REQUEST) {
            val granted =
                grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    companion object {
        private const val CAMERA_PERMISSION_REQUEST = 0x4152 // "AR"
    }
}
