import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../domain/models/ar_status.dart';
import '../theme/app_theme.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.status});

  final ArStatusSnapshot status;

  Color get _trackingColor {
    switch (status.tracking) {
      case ArTrackingQuality.good:
        return AppTheme.success;
      case ArTrackingQuality.limited:
        return AppTheme.accent;
      case ArTrackingQuality.trackingLost:
        return AppTheme.danger;
      case ArTrackingQuality.initializing:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.62),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _trackingColor.withOpacity(0.55)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _trackingColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      status.tracking.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: _trackingColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${status.ground.label}  ·  planes: ${status.horizontalPlaneCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (status.hasReferencePoint)
                Row(
                  children: <Widget>[
                    Icon(
                      status.referenceTracking
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      size: 16,
                      color: status.referenceTracking
                          ? AppTheme.secondary
                          : Colors.white38,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'REF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (status.groundUnavailable)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.danger.withOpacity(0.5)),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.danger, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppConstants.groundUnavailableMessage,
                      style: TextStyle(fontSize: 11.5, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
