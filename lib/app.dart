import 'package:flutter/material.dart';

import 'screens/museum_map_screen.dart';
import 'theme.dart';

class GemNavigatorApp extends StatelessWidget {
  const GemNavigatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GEM Navigator',
      debugShowCheckedModeBanner: false,
      theme: GemTheme.data,
      home: const MuseumMapScreen(),
    );
  }
}
