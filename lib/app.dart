import 'package:flutter/material.dart';
import 'screens/museum_map_screen.dart';
import 'screens/trace_navigation_screen.dart';
import 'screens/surface_navigation_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

class GemNavigatorApp extends StatelessWidget {
  const GemNavigatorApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.instance,
    builder: (context, _) => MaterialApp(
      title: 'GEM Navigator',
      debugShowCheckedModeBanner: false,
      theme: GemTheme.light,
      darkTheme: GemTheme.dark,
      themeMode: AppState.instance.themeMode,
      builder: (context, child) => Directionality(
        textDirection: AppState.instance.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      // Keep named debug routes available without floating test launchers.
      routes: {
        '/trace-navigation': (_) => const TraceNavigationScreen(),
        '/surface-navigation': (_) => const SurfaceNavigationScreen(),
      },
      home: const MuseumMapScreen(),
    ),
  );
}
