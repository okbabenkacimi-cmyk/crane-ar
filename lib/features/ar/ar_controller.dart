import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/ar_status.dart';
import 'ar_bridge.dart';

/// Owns AR lifecycle state for the presentation layer.
class ArController extends ChangeNotifier {
  ArController({ArBridge? bridge}) : _bridge = bridge ?? ArBridge();

  final ArBridge _bridge;
  StreamSubscription<Map<dynamic, dynamic>>? _subscription;

  ArStatusSnapshot _status = ArStatusSnapshot.initial;
  ArStatusSnapshot get status => _status;

  bool _arCoreSupported = false;
  bool get arCoreSupported => _arCoreSupported;

  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  bool _initialized = false;
  bool get initialized => _initialized;

  // ---- Native error surfaced to the UI ---------------------------------
  String? _nativeError;
  String? get nativeError => _nativeError;

  String? consumeNativeError() {
    final String? e = _nativeError;
    _nativeError = null;
    return e;
  }

  // ---- Measured boom geometry (from boom-tip capture) ------------------
  double? _measuredAngleDeg;
  double? get measuredAngleDeg => _measuredAngleDeg;

  double? _measuredTipHeight;
  double? get measuredTipHeight => _measuredTipHeight;

  double? _measuredWorkRadius;
  double? get measuredWorkRadius => _measuredWorkRadius;

  double? _measuredBoundaryRadius;
  double? get measuredBoundaryRadius => _measuredBoundaryRadius;

  bool _sessionReady = false;
  bool get sessionReady => _sessionReady;

  Future<bool> prepare() async {
    _nativeError = null;
    try {
      _arCoreSupported = await _bridge.isArCoreSupported();
      if (!_arCoreSupported) {
        _nativeError = 'This device does not support ARCore. '
            'Install/update "Google Play Services for AR" and retry.';
        _initialized = true;
        notifyListeners();
        return false;
      }
      _permissionGranted = await _bridge.requestCameraPermission();
      if (!_permissionGranted) {
        _nativeError = 'Camera permission is required for AR ground tracking.';
        _initialized = true;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _nativeError = 'ARCore initialisation failed: $e';
      _initialized = true;
      notifyListeners();
      return false;
    }
    _initialized = true;
    notifyListeners();
    return true;
  }

  void startListening() {
    _subscription ??= _bridge.statusStream().listen(
      (Map<dynamic, dynamic> event) {
        final String evt = (event['event'] as String?) ?? 'status';
        switch (evt) {
          case 'boomTip':
            _handleBoomTipEvent(event);
            break;
          case 'reference':
            _status = _status.copyWith(hasReferencePoint: true);
            notifyListeners();
            break;
          case 'sessionReady':
            _sessionReady = true;
            notifyListeners();
            break;
          case 'error':
            _nativeError = (event['message'] as String?) ??
                'Unknown native AR error.';
            notifyListeners();
            break;
          case 'depthWarning':
          case 'depthOk':
            break;
          case 'status':
          default:
            _status = ArStatusSnapshot.fromMap(event);
            notifyListeners();
        }
      },
      onError: (Object e) {
        _nativeError = 'AR status stream error: $e';
        notifyListeners();
      },
    );
  }

  void _handleBoomTipEvent(Map<dynamic, dynamic> event) {
    _measuredAngleDeg = (event['boomAngleDegrees'] as num?)?.toDouble();
    _measuredTipHeight = (event['boomTipHeight'] as num?)?.toDouble();
    _measuredWorkRadius = (event['workRadius'] as num?)?.toDouble();
    _measuredBoundaryRadius = (event['boundaryRadius'] as num?)?.toDouble();
    notifyListeners();
  }

  Future<void> setBoomLength(double metres) async {
    try {
      await _bridge.setBoomLength(metres);
    } catch (_) {}
  }

  Future<void> setBoundaryExtra(double metres) async {
    try {
      await _bridge.setBoundaryExtra(metres);
    } catch (_) {}
  }

  Future<bool> captureBoomTip() => _bridge.captureBoomTip();

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
    } catch (_) {}
  }

  Future<void> resetReference() async {
    try {
      await _bridge.resetReference();
    } catch (_) {}
    _measuredAngleDeg = null;
    _measuredTipHeight = null;
    _measuredWorkRadius = null;
    _measuredBoundaryRadius = null;
    _status = _status.copyWith(hasReferencePoint: false);
    notifyListeners();
  }

  Future<bool> confirmReferenceAtCenter() =>
      _bridge.confirmReferenceAtScreenCenter();

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
