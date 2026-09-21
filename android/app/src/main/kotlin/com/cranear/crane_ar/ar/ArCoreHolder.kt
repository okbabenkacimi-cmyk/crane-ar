package com.cranear.crane_ar.ar

import io.flutter.plugin.common.EventChannel

/**
 * Process-wide handle to the currently attached AR view and the active
 * Flutter event sink. Keeps the MethodChannel handler decoupled from the
 * PlatformView lifecycle.
 */
object ArCoreHolder {
    @Volatile
    var currentView: ArView? = null

    @Volatile
    var eventSink: EventChannel.EventSink? = null
}
