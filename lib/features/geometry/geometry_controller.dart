import 'package:flutter/foundation.dart';

import '../../domain/geometry/geometry_engine.dart';
import '../../domain/models/crane_config.dart';

/// Holds the crane configuration and exposes the derived geometry.
///
/// Fully independent of AR: it never touches platform channels.
class GeometryController extends ChangeNotifier {
  GeometryController({CraneConfig initial = const CraneConfig()})
      : _config = initial;

  CraneConfig _config;
  CraneConfig get config => _config;

  GeometryResult get result => _config.result;

  bool _showBoundary = true;
  bool get showBoundary => _showBoundary;

  String? _lastError;
  String? get lastError => _lastError;

  void setBoomLength(double value) {
    try {
      GeometryEngine.validateBoomLength(value);
      _config = _config.copyWith(boomLength: value);
      _lastError = null;
      notifyListeners();
    } on GeometryValidationException catch (e) {
      _lastError = e.message;
      notifyListeners();
    }
  }

  void setBoomAngleDegrees(double value) {
    try {
      GeometryEngine.validateAngleDegrees(value);
      _config = _config.copyWith(boomAngleDegrees: value);
      _lastError = null;
      notifyListeners();
    } on GeometryValidationException catch (e) {
      _lastError = e.message;
      notifyListeners();
    }
  }

  void setMargin(double value) {
    try {
      GeometryEngine.validateMargin(value);
      _config = _config.copyWith(margin: value);
      _lastError = null;
      notifyListeners();
    } on GeometryValidationException catch (e) {
      _lastError = e.message;
      notifyListeners();
    }
  }

  void setShowBoundary(bool value) {
    if (_showBoundary == value) return;
    _showBoundary = value;
    notifyListeners();
  }
}
