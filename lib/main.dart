import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/screens/main_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Education Platform',
      theme: AppTheme.lightTheme,
      home: const MainShell(),
    );
  }
}