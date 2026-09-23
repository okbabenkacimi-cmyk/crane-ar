import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';

/// Hosts the native ARCore GLSurfaceView inside the Flutter tree.
///
/// The camera is shown by the native Kotlin side (PixelFormat.OPAQUE).
class ArViewWidget extends StatelessWidget {
  const ArViewWidget({super.key, this.onPlatformViewCreated});

  final ValueChanged<int>? onPlatformViewCreated;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isAndroid) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'The AR prototype currently targets Android devices with ARCore.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    return AndroidView(
      viewType: ArChannels.arViewType,
      creationParams: const <String, dynamic>{},
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: onPlatformViewCreated,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
    );
  }
}
