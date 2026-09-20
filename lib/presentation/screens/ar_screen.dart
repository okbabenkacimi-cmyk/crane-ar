import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../domain/geometry/geometry_engine.dart';
import '../../domain/models/ar_status.dart';
import '../../features/ar/ar_controller.dart';
import '../../features/ar/ar_view_widget.dart';
import '../../features/geometry/geometry_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/control_panel.dart';
import '../widgets/readout_panel.dart';
import '../widgets/status_banner.dart';

class ArScreen extends StatefulWidget {
  const ArScreen({super.key});

  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  final ArController _ar = ArController();
  final GeometryController _geometry = GeometryController();

  @override
  void initState() {
    super.initState();
    _ar.addListener(_onArChanged);
    _geometry.addListener(_onGeometryChanged);
    _ar.startListening();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRadii());
  }

  @override
  void dispose() {
    _ar.removeListener(_onArChanged);
    _geometry.removeListener(_onGeometryChanged);
    _ar.dispose();
    _geometry.dispose();
    super.dispose();
  }

  void _onArChanged() => setState(() {});
  void _onGeometryChanged() {
    setState(() {});
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

  Future<void> _resetReference() async {
    await _ar.resetReference();
  }

  Future<void> _confirmAtCentre() async {
    final bool ok = await _ar.confirmReferenceAtCenter();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.surfaceRaised,
          content: Text(
            'No horizontal plane at screen centre. Aim at the ground and tap.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ArStatusSnapshot status = _ar.status;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ArViewWidget(
            onPlatformViewCreated: (int id) {
              _syncRadii();
            },
          ),

          // Top HUD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
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
                  if (!status.hasReferencePoint)
                    ReferencePrompt(
                      enabled: status.canPlaceReference,
                      onConfirm: _confirmAtCentre,
                    ),
                  const Spacer(),
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: status.canPlaceReference
                                ? AppTheme.accent
                                : Colors.white38,
                            width: 1.6,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ReadoutPanel(
                    result: _geometry.result,
                    status: status,
                    showBoundary: _geometry.showBoundary,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ControlPanel(
                          boomLength: _geometry.config.boomLength,
                          boomAngleDegrees: _geometry.config.boomAngleDegrees,
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetReference,
                          icon: const Icon(Icons.restart_alt, size: 16),
                          label: const Text(
                            'RESET REFERENCE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
