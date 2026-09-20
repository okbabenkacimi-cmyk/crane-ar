import 'package:flutter/material.dart';

import 'presentation/screens/home_screen.dart';
import 'presentation/theme/app_theme.dart';

class CraneArApp extends StatelessWidget {
  const CraneArApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crane AR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
