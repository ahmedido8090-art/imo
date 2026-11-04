import 'package:flutter/material.dart';

import '../painters/museum_map_painter.dart';

class MuseumMapCanvas extends StatelessWidget {
  const MuseumMapCanvas({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const MuseumMapPainter(),
      child: InkWell(onTap: onTap, child: const SizedBox.expand()),
    );
  }
}
