import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/category_pill.dart';
import '../widgets/map_control.dart';
import '../widgets/museum_header.dart';
import '../widgets/museum_map_canvas.dart';
import 'pinned_location_sheet.dart';

class MuseumMapScreen extends StatefulWidget {
  const MuseumMapScreen({super.key});

  @override
  State<MuseumMapScreen> createState() => _MuseumMapScreenState();
}

class _MuseumMapScreenState extends State<MuseumMapScreen> {
  bool _foodSelected = false;
  bool _giftSelected = false;

  void _openPinnedLocation() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const PinnedLocationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MuseumHeader(onSearch: () {}),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: MuseumMapCanvas(onTap: _openPinnedLocation),
                  ),
                  Positioned(
                    top: 20,
                    left: 18,
                    child: CategoryPill(
                      icon: Icons.restaurant,
                      label: 'Food',
                      selected: _foodSelected,
                      onTap: () =>
                          setState(() => _foodSelected = !_foodSelected),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 127,
                    child: CategoryPill(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Gift shop',
                      selected: _giftSelected,
                      onTap: () =>
                          setState(() => _giftSelected = !_giftSelected),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    top: 20,
                    child: Column(
                      children: [
                        MapControl(
                          icon: Icons.layers_outlined,
                          tooltip: 'Layers',
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        MapControl(
                          icon: Icons.my_location_outlined,
                          tooltip: 'Recenter',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: Center(
                      child: FilledButton.icon(
                        key: const Key('open-pin'),
                        onPressed: _openPinnedLocation,
                        icon: const Icon(Icons.location_on_outlined),
                        label: const Text('Explore pinned artifact'),
                        style: FilledButton.styleFrom(
                          backgroundColor: GemColors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
