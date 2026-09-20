/// Camera tracking quality, mirrored from ARCore's TrackingState.
enum ArTrackingQuality {
  good,
  limited,
  trackingLost,
  initializing;

  static ArTrackingQuality fromWire(String? value) {
    switch (value) {
      case 'GOOD':
        return ArTrackingQuality.good;
      case 'LIMITED':
        return ArTrackingQuality.limited;
      case 'TRACKING_LOST':
        return ArTrackingQuality.trackingLost;
      default:
        return ArTrackingQuality.initializing;
    }
  }

  String get label {
    switch (this) {
      case ArTrackingQuality.good:
        return 'TRACKING: GOOD';
      case ArTrackingQuality.limited:
        return 'TRACKING: LIMITED';
      case ArTrackingQuality.trackingLost:
        return 'TRACKING: LOST';
      case ArTrackingQuality.initializing:
        return 'TRACKING: INITIALIZING';
    }
  }
}

/// Horizontal ground-plane availability.
enum ArGroundStatus {
  detected,
  noGroundDetected;

  static ArGroundStatus fromWire(String? value) {
    return value == 'DETECTED'
        ? ArGroundStatus.detected
        : ArGroundStatus.noGroundDetected;
  }

  String get label {
    switch (this) {
      case ArGroundStatus.detected:
        return 'GROUND: DETECTED';
      case ArGroundStatus.noGroundDetected:
        return 'GROUND: NOT DETECTED';
    }
  }
}

/// Immutable snapshot of native AR state.
class ArStatusSnapshot {
  const ArStatusSnapshot({
    this.tracking = ArTrackingQuality.initializing,
    this.ground = ArGroundStatus.noGroundDetected,
    this.horizontalPlaneCount = 0,
    this.hasReferencePoint = false,
    this.referenceTracking = false,
  });

  final ArTrackingQuality tracking;
  final ArGroundStatus ground;
  final int horizontalPlaneCount;
  final bool hasReferencePoint;
  final bool referenceTracking;

  static const ArStatusSnapshot initial = ArStatusSnapshot();

  /// True when the ground reference is reliable enough to place a marker.
  bool get canPlaceReference =>
      tracking == ArTrackingQuality.good &&
      ground == ArGroundStatus.detected;

  /// True when no reliable ground reference currently exists.
  bool get groundUnavailable =>
      tracking == ArTrackingQuality.trackingLost ||
      ground == ArGroundStatus.noGroundDetected;

  ArStatusSnapshot copyWith({
    ArTrackingQuality? tracking,
    ArGroundStatus? ground,
    int? horizontalPlaneCount,
    bool? hasReferencePoint,
    bool? referenceTracking,
  }) {
    return ArStatusSnapshot(
      tracking: tracking ?? this.tracking,
      ground: ground ?? this.ground,
      horizontalPlaneCount: horizontalPlaneCount ?? this.horizontalPlaneCount,
      hasReferencePoint: hasReferencePoint ?? this.hasReferencePoint,
      referenceTracking: referenceTracking ?? this.referenceTracking,
    );
  }

  factory ArStatusSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return ArStatusSnapshot(
      tracking: ArTrackingQuality.fromWire(map['tracking'] as String?),
      ground: ArGroundStatus.fromWire(map['ground'] as String?),
      horizontalPlaneCount: (map['horizontalPlanes'] as num?)?.toInt() ?? 0,
      hasReferencePoint: map['hasReference'] as bool? ?? false,
      referenceTracking: map['referenceTracking'] as bool? ?? false,
    );
  }
}
