import 'package:flutter/material.dart';

abstract final class GemColors {
  static const ivory = Color(0xfff7f1e7);
  static const map = Color(0xffeee9dc);
  static const teal = Color(0xff164758);
  static const ink = Color(0xff182025);
  static const gold = Color(0xffb28538);
  static const muted = Color(0xff667074);
  static const mapLine = Color(0xff96a3a1);
  static const mapGrid = Color(0xffc9c8bb);
}

abstract final class GemTheme {
  static ThemeData get data => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: GemColors.ivory,
    colorScheme: ColorScheme.fromSeed(seedColor: GemColors.teal),
    fontFamily: 'Georgia',
    useMaterial3: true,
  );
}
