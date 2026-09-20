import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../domain/geometry/geometry_engine.dart';
import '../../domain/models/ar_status.dart';
import '../theme/app_theme.dart';

class ReadoutPanel extends StatelessWidget {
  const ReadoutPanel({
    super.key,
    required this.result,
    required this.status,
    required this.showBoundary,
  });

  final GeometryResult result;
  final ArStatusSnapshot status;
  final bool showBoundary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.62),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _row('Boom length (L)',
              '${result.boomLength.toStringAsFixed(2)} m'),
          _row('Boom angle (θ)',
              '${result.boomAngleDegrees.toStringAsFixed(1)}°'),
          _divider(),
          _row('Work radius (R = L·cosθ)',
              '${result.workRadius.toStringAsFixed(2)} m',
              highlight: true),
          if (showBoundary)
            _row('Planning boundary (R + M)',
                '${result.boundaryRadius.toStringAsFixed(2)} m',
                highlight: true),
          _row('Planning margin (M)',
              '${result.margin.toStringAsFixed(2)} m'),
          _divider(),
          _row('Reference point',
              status.hasReferencePoint ? 'ESTABLISHED' : 'NOT SET'),
          _row('AR tracking', status.tracking.label.replaceFirst('TRACKING: ', '')),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(height: 1, color: Colors.white12),
      );

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: Colors.white60),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: highlight ? AppTheme.accent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small helper widget used by the AR screen for the reference prompt.
class ReferencePrompt extends StatelessWidget {
  const ReferencePrompt({super.key, required this.onConfirm, required this.enabled});

  final VoidCallback onConfirm;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accent.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            AppConstants.confirmReferencePrompt,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap the physical ground where the crane slew centre sits. '
            'The camera position is NOT assumed to be the crane centre.',
            style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: enabled ? onConfirm : null,
              icon: const Icon(Icons.center_focus_strong, size: 16),
              label: const Text('USE SCREEN CENTRE'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accent,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
