import 'package:flutter/services.dart';

import '../../core/constants.dart';

/// Thin wrapper around the Flutter <-> native ARCore bridge.
class ArBridge {
  ArBridge({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methods = methodChannel ?? const MethodChannel(ArChannels.methods),
        _events = eventChannel ?? const EventChannel(ArChannels.events);

  final MethodChannel _methods;
  final EventChannel _events;

  Future<bool> isArCoreSupported() async {
    final bool? supported =
        await _methods.invokeMethod<bool>('checkArCoreSupport');
    return supported ?? false;
  }

  Future<bool> requestCameraPermission() async {
    final bool? granted =
        await _methods.invokeMethod<bool>('requestCameraPermission');
    return granted ?? false;
  }

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

  Future<void> setBoomLength(double metres) async {
    await _methods.invokeMethod<void>(
      'setBoomLength',
      <String, dynamic>{'value': metres},
    );
  }

  Future<void> setBoundaryExtra(double metres) async {
    await _methods.invokeMethod<void>(
      'setBoundaryExtra',
      <String, dynamic>{'value': metres},
    );
  }

  Future<bool> captureBoomTip() async {
    final bool? ok = await _methods.invokeMethod<bool>('captureBoomTip');
    return ok ?? false;
  }

  Future<void> resetReference() async {
    await _methods.invokeMethod<void>('resetReference');
  }

  Future<bool> confirmReferenceAtScreenCenter() async {
    final bool? placed =
        await _methods.invokeMethod<bool>('confirmReferenceAtCenter');
    return placed ?? false;
  }

  Stream<Map<dynamic, dynamic>> statusStream() {
    return _events.receiveBroadcastStream().map((dynamic event) {
      return Map<dynamic, dynamic>.from(event as Map);
    });
  }
}
