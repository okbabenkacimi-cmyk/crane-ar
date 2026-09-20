/// Channel names shared between Dart and the native ARCore layer.
class ArChannels {
  ArChannels._();

  static const String methods = 'crane_ar/methods';
  static const String events = 'crane_ar/events';
  static const String arViewType = 'crane_ar/ar_view';
}

/// Product-level constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Crane AR';
  static const String referenceLabel = 'CRANE REFERENCE POINT';
  static const String confirmReferencePrompt = 'Confirm crane reference point';

  static const String advisoryNotice =
      'Advisory visualization prototype. Work radius and planning boundary are '
      'geometric projections only and are not a certified safe zone, exclusion '
      'zone, or lift approval.';

  static const String groundUnavailableMessage =
      'Ground reference unavailable — move camera or establish reference manually.';
}
