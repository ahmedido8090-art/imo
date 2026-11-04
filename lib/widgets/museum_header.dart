import 'package:flutter/material.dart';

import '../theme.dart';

class MuseumHeader extends StatelessWidget {
  const MuseumHeader({super.key, required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GemColors.ivory,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GemColors.teal,
              border: Border.all(color: GemColors.gold, width: 2),
            ),
            child: const Icon(
              Icons.remove_red_eye_outlined,
              color: GemColors.gold,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GRAND EGYPTIAN MUSEUM',
                  style: TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 11,
                    letterSpacing: 1.8,
                    color: GemColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Grand Staircase · Level 1',
                  style: TextStyle(
                    fontSize: 19,
                    color: GemColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSearch,
            tooltip: 'Search museum',
            icon: const Icon(Icons.search, size: 27, color: GemColors.ink),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .7),
              side: const BorderSide(color: Color(0xffd6d1c7)),
              padding: const EdgeInsets.all(11),
            ),
          ),
        ],
      ),
    );
  }
}
