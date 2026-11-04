// File: lib/core/themes.dart
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

abstract final class AppColors {
  // Mapped to GemColors
  static const Color primary = GemColors.teal;
  static const Color secondary = GemColors.gold;
  static const Color background = GemColors.ivory;
  static const Color surfaceSubtle = GemColors.map;
  static const Color borderSubtle = GemColors.mapGrid;
  static const Color textPrimary = GemColors.ink;
  static const Color textSecondary = GemColors.muted;
  static const Color routeLineActive = GemColors.gold;

  // Existing tokens unique to AppColors (left untouched)
  static const Color surface = Color(0xFFFAF8F5);
  static const Color textOnImage = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF2E6F40);
  static const Color scrimOverlay = Color(0x59182025);
  static const Color sheetHandle = Color(0xFFCFC9BC);
  static const Color timelineConnector = Color(0xFFDFD6C5);
}

abstract final class AppDimensions {
  // 4pt / 8pt Spacing Grid
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Border Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 28.0;
  static const double radiusFull = 999.0;

  // Screen & Component Tokens
  static const double borderThin = 1.0;
  static const double headerIconSize = 42.0;
  static const double closeButtonSize = 36.0;
  static const double cardHeight = 140.0;
  static const double cardImageWidth = 108.0;
  static const double navPillWidth = 56.0;
  static const double navPillHeight = 32.0;
  static const double iconSizeSm = 15.0;
  static const double iconSizeMd = 20.0;

  // Bottom Sheet & Timeline Tokens
  static const double sheetHandleWidth = 40.0;
  static const double sheetHandleHeight = 4.0;
  static const double stepBadgeSize = 24.0;
  static const double stepConnectorHeight = 14.0;
  static const double stepConnectorWidth = 1.5;
  static const double primaryButtonHeight = 54.0;
  static const double blurSigma = 5.0;
}

abstract final class AppTextStyles {
  static const String _serifFontFamily = 'Georgia';

  static const TextStyle headingLarge = TextStyle(
    fontFamily: _serifFontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle sheetTitle = TextStyle(
    fontFamily: _serifFontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: _serifFontFamily,
    fontSize: 21.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _serifFontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle overlineGold = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w700,
    color: AppColors.secondary,
    letterSpacing: 1.3,
    height: 1.2,
  );

  static const TextStyle overlineMuted = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 1.0,
    height: 1.2,
  );

  static const TextStyle cardIndexNumber = TextStyle(
    fontFamily: _serifFontFamily,
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnImage,
    height: 1.0,
  );

  static const TextStyle metricValue = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static const TextStyle metricSublabel = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static const TextStyle stepTitle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle stepBadgeNumber = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnImage,
    height: 1.0,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnImage,
    height: 1.2,
  );
}

abstract final class AppTheme {
  static ThemeData get lightTheme => GemTheme.data.copyWith(
        dividerTheme: const DividerThemeData(
          color: AppColors.borderSubtle,
          thickness: AppDimensions.borderThin,
          space: AppDimensions.borderThin,
        ),
      );
}