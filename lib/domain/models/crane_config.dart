import '../geometry/geometry_engine.dart';

/// User-editable crane parameters.
class CraneConfig {
  const CraneConfig({
    this.boomLength = 20.0,
    this.boomAngleDegrees = 45.0,
    this.margin = 2.0,
  });

  final double boomLength;
  final double boomAngleDegrees;
  final double margin;

  CraneConfig copyWith({
    double? boomLength,
    double? boomAngleDegrees,
    double? margin,
  }) {
    return CraneConfig(
      boomLength: boomLength ?? this.boomLength,
      boomAngleDegrees: boomAngleDegrees ?? this.boomAngleDegrees,
      margin: margin ?? this.margin,
    );
  }

  GeometryResult get result => GeometryEngine.compute(
        boomLength: boomLength,
        boomAngleDegrees: boomAngleDegrees,
        margin: margin,
      );
}
