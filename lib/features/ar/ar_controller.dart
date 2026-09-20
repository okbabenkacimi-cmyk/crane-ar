import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/ar_status.dart';
import 'ar_bridge.dart';

/// Owns AR lifecycle state for the presentation layer.
class ArController extends ChangeNotifier {
  ArController({ArBridge? bridge}) : _bridge = bridge ?? ArBridge();

  final ArBridge _bridge;
  StreamSubscription<ArStatusSnapshot>? _subscription;

  ArStatusSnapshot _status = ArStatusSnapshot.initial;
  ArStatusSnapshot get status => _status;

  bool _arCoreSupported = false;
  bool get arCoreSupported => _arCoreSupported;

  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  bool _initialized = false;
  bool get initialized => _initialized;

  String? _error;

  /// Reads a stored error message (if any) and clears it.
  String? consumeError() {
    final String? e = _error;
    _error = null;
    return e;
  }

  /// Verifies ARCore availability and camera permission.
  Future<bool> prepare() async {
    _error = null;
    try {
      _arCoreSupported = await _bridge.isArCoreSupported();
      if (!_arCoreSupported) {
        _error = 'This device does not support ARCore. '
            'Install/update "Google Play Services for AR" and retry.';
        _initialized = true;
        notifyListeners();
        return false;
      }
      _permissionGranted = await _bridge.requestCameraPermission();
      if (!_permissionGranted) {
        _error = 'Camera permission is required for AR ground tracking.';
        _initialized = true;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'ARCore initialisation failed: $e';
      _initialized = true;
      notifyListeners();
      return false;
    }
    _initialized = true;
    notifyListeners();
    return true;
  }

  /// Begins consuming native status events.
  void startListening() {
    _subscription ??= _bridge.statusStream().listen(
      (ArStatusSnapshot snapshot) {
        _status = snapshot;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'AR status stream error: $e';
        notifyListeners();
      },
    );
  }

  Future<void> pushRadii({
    required double workRadius,
    required double boundaryRadius,
    required bool showBoundary,
  }) async {
    try {
      await _bridge.setRadii(
        workRadius: workRadius,
        boundaryRadius: boundaryRadius,
        showBoundary: showBoundary,
      );
    } catch (_) {
      // The native AR view may not be attached yet; it re-syncs on creation.
    }
  }

  Future<void> resetReference() => _bridge.resetReference();

  Future<bool> confirmReferenceAtCenter() =>
      _bridge.confirmReferenceAtScreenCenter();

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
