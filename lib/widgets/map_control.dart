import 'package:flutter/material.dart';

import '../theme.dart';

class MapControl extends StatelessWidget {
  const MapControl({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, color: GemColors.teal),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: .9),
        padding: const EdgeInsets.all(13),
        elevation: 4,
      ),
    );
  }
}
