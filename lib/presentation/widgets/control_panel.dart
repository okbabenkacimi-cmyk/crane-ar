import 'package:flutter/material.dart';

import '../../domain/geometry/geometry_engine.dart';
import '../theme/app_theme.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({
    super.key,
    required this.boomLength,
    required this.boomAngleDegrees,
    required this.margin,
    required this.showBoundary,
    required this.onBoomLengthChanged,
    required this.onAngleChanged,
    required this.onMarginChanged,
    required this.onShowBoundaryChanged,
  });

  final double boomLength;
  final double boomAngleDegrees;
  final double margin;
  final bool showBoundary;
  final ValueChanged<double> onBoomLengthChanged;
  final ValueChanged<double> onAngleChanged;
  final ValueChanged<double> onMarginChanged;
  final ValueChanged<bool> onShowBoundaryChanged;

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  late final TextEditingController _lengthCtrl;
  late final TextEditingController _angleCtrl;
  late final TextEditingController _marginCtrl;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _lengthCtrl = TextEditingController(text: widget.boomLength.toStringAsFixed(1));
    _angleCtrl = TextEditingController(text: widget.boomAngleDegrees.toStringAsFixed(0));
    _marginCtrl = TextEditingController(text: widget.margin.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant ControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boomLength != widget.boomLength &&
        double.tryParse(_lengthCtrl.text) != widget.boomLength) {
      _lengthCtrl.text = widget.boomLength.toStringAsFixed(1);
    }
    if (oldWidget.boomAngleDegrees != widget.boomAngleDegrees &&
        double.tryParse(_angleCtrl.text) != widget.boomAngleDegrees) {
      _angleCtrl.text = widget.boomAngleDegrees.toStringAsFixed(0);
    }
    if (oldWidget.margin != widget.margin &&
        double.tryParse(_marginCtrl.text) != widget.margin) {
      _marginCtrl.text = widget.margin.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _angleCtrl.dispose();
    _marginCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.tune, size: 16, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  const Text(
                    'CRANE PARAMETERS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_more : Icons.expand_less,
                    size: 20,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: <Widget>[
                  _sliderRow(
                    label: 'Boom length L (m)',
                    value: widget.boomLength,
                    min: GeometryEngine.minBoomLength,
                    max: 80,
                    controller: _lengthCtrl,
                    onChanged: widget.onBoomLengthChanged,
                    decimals: 1,
                  ),
                  _sliderRow(
                    label: 'Boom angle θ (°)',
                    value: widget.boomAngleDegrees,
                    min: GeometryEngine.minAngleDegrees,
                    max: GeometryEngine.maxAngleDegrees,
                    controller: _angleCtrl,
                    onChanged: widget.onAngleChanged,
                    decimals: 0,
                  ),
                  _sliderRow(
                    label: 'Planning margin M (m)',
                    value: widget.margin,
                    min: GeometryEngine.minMargin,
                    max: 20,
                    controller: _marginCtrl,
                    onChanged: widget.onMarginChanged,
                    decimals: 1,
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: AppTheme.accent,
                    value: widget.showBoundary,
                    onChanged: widget.onShowBoundaryChanged,
                    title: const Text(
                      'Show planning boundary circle',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required TextEditingController controller,
    required ValueChanged<double> onChanged,
    required int decimals,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: Colors.white60),
              ),
            ),
            SizedBox(
              width: 72,
              height: 32,
              child: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12.5, color: Colors.white),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
                onSubmitted: (String raw) {
                  final double? parsed = double.tryParse(raw.trim());
                  if (parsed == null) {
                    controller.text = value.toStringAsFixed(decimals);
                    return;
                  }
                  onChanged(parsed.clamp(min, max));
                },
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: AppTheme.accent,
            thumbColor: AppTheme.accent,
            inactiveTrackColor: Colors.white24,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: (double v) {
              controller.text = v.toStringAsFixed(decimals);
              onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}
