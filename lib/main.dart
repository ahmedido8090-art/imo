// File: lib/main.dart
import 'package:flutter/material.dart';
import 'core/constants/app_strings.dart';
import 'core/themes.dart';
import 'features/rostau/presentation/screens/rostau_paths_screen.dart';

void main() {
  runApp(const NavigatorApp());
}

class NavigatorApp extends StatelessWidget {
  const NavigatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.rostauPathsTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RostauPathsScreen(),
    );
  }
}