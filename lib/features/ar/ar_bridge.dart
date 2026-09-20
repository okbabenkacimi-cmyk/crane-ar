import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../domain/models/ar_status.dart';

/// Thin, typed wrapper around the Flutter <-> native ARCore bridge.
///
/// This is the ONLY place in the Dart layer that talks to platform channels.
class ArBridge {
  ArBridge({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methods = methodChannel ?? const MethodChannel(ArChannels.methods),
        _events = eventChannel ?? const EventChannel(ArChannels.events);

  final MethodChannel _methods;
  final EventChannel _events;

  /// Returns true when the device supports ARCore.
  Future<bool> isArCoreSupported() async {
    final bool? supported =
        await _methods.invokeMethod<bool>('checkArCoreSupport');
    return supported ?? false;
  }

  /// Requests the CAMERA runtime permission. Returns true when granted.
  Future<bool> requestCameraPermission() async {
    final bool? granted =
        await _methods.invokeMethod<bool>('requestCameraPermission');
    return granted ?? false;
  }

  /// Pushes the current radii into the world-space renderer.
  Future<void> setRadii({
    required double workRadius,
    required double boundaryRadius,
    required bool showBoundary,
  }) async {
    await _methods.invokeMethod<void>('setRadii', <String, dynamic>{
      'workRadius': workRadius,
      'boundaryRadius': boundaryRadius,
      'showBoundary': showBoundary,
    });
  }

  /// Clears the crane reference anchor.
  Future<void> resetReference() async {
    await _methods.invokeMethod<void>('resetReference');
  }

  /// Fallback: hit-test the screen centre and anchor there.
  Future<bool> confirmReferenceAtScreenCenter() async {
    final bool? placed =
        await _methods.invokeMethod<bool>('confirmReferenceAtCenter');
    return placed ?? false;
  }

  /// Streaming AR status updates from the native session.
  Stream<ArStatusSnapshot> statusStream() {
    return _events.receiveBroadcastStream().map((dynamic event) {
      final map = Map<dynamic, dynamic>.from(event as Map);
      return ArStatusSnapshot.fromMap(map);
    });
  }
}
