import 'package:flutter/material.dart';

import '../../domain/geometry/geometry_engine.dart';
import '../../domain/models/ar_status.dart';
import '../../features/ar/ar_controller.dart';
import '../../features/ar/ar_view_widget.dart';
import '../../features/geometry/geometry_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/control_panel.dart';
import '../widgets/readout_panel.dart';
import '../widgets/status_banner.dart';

enum _Step { placeSlewCentre, captureBoomTip, done }

class ArScreen extends StatefulWidget {
  const ArScreen({super.key});

  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  final ArController _ar = ArController();
  final GeometryController _geometry = GeometryController();

  _Step _step = _Step.placeSlewCentre;
  double? _measuredAngleDeg;
  double? _measuredTipHeight;
  bool _errorDialogShown = false;

  @override
  void initState() {
    super.initState();
    _ar.addListener(_onArChanged);
    _geometry.addListener(_onGeometryChanged);
    _ar.startListening();
    _ar.setBoomLength(_geometry.config.boomLength);
    _ar.setBoundaryExtra(_geometry.config.margin);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncRadii();
    });
  }

  @override
  void dispose() {
    _ar.removeListener(_onArChanged);
    _geometry.removeListener(_onGeometryChanged);
    _ar.dispose();
    _geometry.dispose();
    super.dispose();
  }

  void _onArChanged() {
    if (!mounted) return;

    final String? err = _ar.nativeError;
    if (err != null && !_errorDialogShown) {
      _errorDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceRaised,
            title: const Text('AR not available'),
            content: Text(err),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  _ar.clearNativeError();
                  Navigator.of(ctx).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }

    setState(() {});
    if (_ar.status.hasReferencePoint && _step == _Step.placeSlewCentre) {
      _step = _Step.captureBoomTip;
    }
    final double? measured = _ar.measuredAngleDeg;
    if (measured != null) {
      _measuredAngleDeg = measured;
      _measuredTipHeight = _ar.measuredTipHeight;
      _step = _Step.done;
      _geometry.setBoomAngleDegrees(measured);
    }
  }

  void _onGeometryChanged() {
    if (!mounted) return;
    setState(() {});
    _ar.setBoomLength(_geometry.config.boomLength);
    _ar.setBoundaryExtra(_geometry.config.margin);
    _syncRadii();
  }

  void _syncRadii() {
    final GeometryResult r = _geometry.result;
    _ar.pushRadii(
      workRadius: r.workRadius,
      boundaryRadius: r.boundaryRadius,
      showBoundary: _geometry.showBoundary,
    );
  }

  Future<void> _reset() async {
    await _ar.resetReference();
    if (!mounted) return;
    setState(() {
      _step = _Step.placeSlewCentre;
      _measuredAngleDeg = null;
      _measuredTipHeight = null;
    });
  }

  Future<void> _captureBoomTip() async {
    final bool ok = await _ar.captureBoomTip();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.surfaceRaised,
          content: Text('Could not capture boom tip — aim at the boom.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ArStatusSnapshot status = _ar.status;
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: ArViewWidget(
              onPlatformViewCreated: (int id) {
                _syncRadii();
              },
            ),
          ),

          Center(
            child: IgnorePointer(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _step == _Step.captureBoomTip
                        ? AppTheme.accent
                        : Colors.white54,
                    width: 1.6,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).maybePop();
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.5),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ADVISORY VISUALIZATION',
                            style: TextStyle(
                              fontSize: 9.5,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    StatusBanner(status: status),
                    const SizedBox(height: 10),
                    _stepBanner(),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: size.height * 0.62,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                        Colors.black,
                      ],
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ReadoutPanel(
                          result: _geometry.result,
                          status: status,
                          showBoundary: _geometry.showBoundary,
                        ),
                        const SizedBox(height: 10),
                        ControlPanel(
                          boomLength: _geometry.config.boomLength,
                          boomAngleDegrees: _measuredAngleDeg ??
                              _geometry.config.boomAngleDegrees,
                          margin: _geometry.config.margin,
                          showBoundary: _geometry.showBoundary,
                          onBoomLengthChanged: _geometry.setBoomLength,
                          onAngleChanged: _geometry.setBoomAngleDegrees,
                          onMarginChanged: _geometry.setMargin,
                          onShowBoundaryChanged: (bool v) {
                            _geometry.setShowBoundary(v);
                            _syncRadii();
                          },
                        ),
                        const SizedBox(height: 10),
                        _actionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBanner() {
    if (_step == _Step.placeSlewCentre) {
      return _banner(
        'Step 1 of 2',
        'Point at the crane slew centre on the ground and tap, or press USE SCREEN CENTRE.',
        AppTheme.accent,
      );
    }
    if (_step == _Step.captureBoomTip) {
      return _banner(
        'Step 2 of 2',
        'Aim the crosshair at the TOP of the boom (the tip) and press CAPTURE BOOM TIP.',
        AppTheme.secondary,
      );
    }
    return _banner(
      'Boom captured',
      'Angle: ${(_measuredAngleDeg ?? 0).toStringAsFixed(1)}° · '
          'Tip height: ${(_measuredTipHeight ?? 0).toStringAsFixed(2)} m',
      AppTheme.success,
    );
  }

  Widget _banner(String title, String body, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    if (_step == _Step.captureBoomTip) {
      return Row(
        children: <Widget>[
          Expanded(
            child: FilledButton.icon(
              onPressed: _captureBoomTip,
              icon: const Icon(Icons.center_focus_strong, size: 18),
              label: const Text('CAPTURE BOOM TIP'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt, size: 16),
              label: const Text('RESET'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt, size: 16),
            label: const Text('RESET'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
