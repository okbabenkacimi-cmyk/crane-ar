import 'dart:math' as math;

/// Raised when a geometric input falls outside its physically meaningful domain.
class GeometryValidationException implements Exception {
  const GeometryValidationException(this.field, this.message);

  final String field;
  final String message;

  @override
  String toString() => 'GeometryValidationException($field): $message';
}

/// Immutable, fully-derived geometry for one crane configuration.
class GeometryResult {
  const GeometryResult({
    required this.boomLength,
    required this.boomAngleDegrees,
    required this.margin,
    required this.workRadius,
    required this.boundaryRadius,
    required this.boomTipHeight,
  });

  /// L — boom length in metres.
  final double boomLength;

  /// θ — boom elevation above horizontal, in degrees (0–90).
  final double boomAngleDegrees;

  /// M — planning margin in metres.
  final double margin;

  /// R = L × cos(θ) — horizontal geometric projection of the boom.
  final double workRadius;

  /// R_boundary = R + M.
  final double boundaryRadius;

  /// L × sin(θ) — informational boom-tip height above the reference plane.
  final double boomTipHeight;

  @override
  String toString() => 'GeometryResult(L=$boomLength, θ=$boomAngleDegrees, '
      'R=$workRadius, M=$margin, R_boundary=$boundaryRadius)';
}

/// Pure geometry engine. Contains **no** AR, Flutter, or platform dependency.
class GeometryEngine {
  GeometryEngine._();

  static const double minBoomLength = 0.1;
  static const double maxBoomLength = 250.0;
  static const double minAngleDegrees = 0.0;
  static const double maxAngleDegrees = 90.0;
  static const double minMargin = 0.0;
  static const double maxMargin = 100.0;

  static double validateBoomLength(double value) {
    if (value.isNaN || value.isInfinite) {
      throw const GeometryValidationException(
          'boomLength', 'Boom length must be a finite number.');
    }
    if (value < minBoomLength) {
      throw GeometryValidationException(
          'boomLength', 'Boom length must be at least $minBoomLength m.');
    }
    if (value > maxBoomLength) {
      throw GeometryValidationException(
          'boomLength', 'Boom length must not exceed $maxBoomLength m.');
    }
    return value;
  }

  static double validateAngleDegrees(double value) {
    if (value.isNaN || value.isInfinite) {
      throw const GeometryValidationException(
          'boomAngleDegrees', 'Boom angle must be a finite number.');
    }
    if (value < minAngleDegrees || value > maxAngleDegrees) {
      throw GeometryValidationException('boomAngleDegrees',
          'Boom angle must be between $minAngleDegrees° and $maxAngleDegrees°.');
    }
    return value;
  }

  static double validateMargin(double value) {
    if (value.isNaN || value.isInfinite) {
      throw const GeometryValidationException(
          'margin', 'Planning margin must be a finite number.');
    }
    if (value < minMargin) {
      throw GeometryValidationException(
          'margin', 'Planning margin must not be negative.');
    }
    if (value > maxMargin) {
      throw GeometryValidationException(
          'margin', 'Planning margin must not exceed $maxMargin m.');
    }
    return value;
  }

  /// WORK RADIUS: horizontal geometric projection of the boom, R = L × cos(θ).
  static double workRadius(double boomLength, double boomAngleDegrees) {
    validateBoomLength(boomLength);
    validateAngleDegrees(boomAngleDegrees);
    final double radians = boomAngleDegrees * math.pi / 180.0;
    final double r = boomLength * math.cos(radians);
    // Guard against floating point noise at exactly 90°.
    return r < 0 ? 0.0 : r;
  }

  /// PLANNING BOUNDARY: R_boundary = R + M.
  static double boundaryRadius(
    double boomLength,
    double boomAngleDegrees,
    double margin,
  ) {
    validateMargin(margin);
    return workRadius(boomLength, boomAngleDegrees) + margin;
  }

  /// Informational boom-tip height: L × sin(θ).
  static double boomTipHeight(double boomLength, double boomAngleDegrees) {
    validateBoomLength(boomLength);
    validateAngleDegrees(boomAngleDegrees);
    final double radians = boomAngleDegrees * math.pi / 180.0;
    return boomLength * math.sin(radians);
  }

  /// Full derivation in one call.
  static GeometryResult compute({
    required double boomLength,
    required double boomAngleDegrees,
    required double margin,
  }) {
    final double l = validateBoomLength(boomLength);
    final double a = validateAngleDegrees(boomAngleDegrees);
    final double m = validateMargin(margin);
    final double r = workRadius(l, a);
    return GeometryResult(
      boomLength: l,
      boomAngleDegrees: a,
      margin: m,
      workRadius: r,
      boundaryRadius: r + m,
      boomTipHeight: boomTipHeight(l, a),
    );
  }
}
