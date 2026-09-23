import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../features/ar/ar_controller.dart';
import '../theme/app_theme.dart';
import 'ar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ArController _ar = ArController();
  bool _busy = false;

  @override
  void dispose() {
    _ar.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    final bool ready = await _ar.prepare();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!ready) {
      final String? error = _ar.nativeError;
      if (error != null) {
        _ar.clearNativeError();
        await showDialog<void>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceRaised,
            title: const Text('AR unavailable'),
            content: Text(error),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ArScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Spacer(flex: 2),
              Container(
                width: 56,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'World-anchored crane work-radius visualization',
                style: TextStyle(fontSize: 15, color: Colors.white60),
              ),
              const SizedBox(height: 32),
              const _Bullet(text: 'Establish the crane reference point on real ground'),
              const _Bullet(text: 'Work radius  R = L × cos(θ)'),
              const _Bullet(text: 'Planning boundary  R_boundary = R + M'),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRaised,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  AppConstants.advisoryNotice,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    height: 1.45,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _busy ? null : _start,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'START AR SESSION',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: AppTheme.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}        
