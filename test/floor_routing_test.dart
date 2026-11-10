import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imo/data/gem_extras.dart';
import 'package:imo/data/gem_map_data.dart';
import 'package:imo/services/floor_grid.dart';
import 'package:imo/services/live_surface_router.dart';
import 'package:imo/services/route_finder.dart';

MuseumGraph museum() => MuseumGraph(
  allMaps,
  portals: kPortals,
  redirects: kRouteRedirects,
  placeFloors: kPlaceFloor,
  stairEdges: kStairEdges,
);

void main() {
  test('a thin wall and diagonal touching cells cannot be shortcut', () {
    final bits = Uint8List(2);
    // Two squares touching at one corner.
    for (final i in [0, 1, 4, 5, 10, 11, 14, 15]) {
      bits[i >> 3] |= 1 << (i & 7);
    }
    final floor = FloorGrid(4, 4, base64Encode(bits));
    expect(floor.route(const Offset(2, 2), const Offset(14, 14)), isNull);
    expect(floor.visible(const Offset(2, 2), const Offset(14, 14)), isFalse);
    expect(floor.route(const Offset(2, 2), const Offset(6, 6)), [
      const Offset(2, 2),
      const Offset(6, 6),
    ]);
  });
  test('every public POI has a route from its map entrance', () {
    final graph = museum();
    for (final map in allMaps.values) {
      for (final place in map.places) {
        expect(
          graph.find(map.entranceId, place.id),
          isNotNull,
          reason: place.id,
        );
      }
    }
  });
  test('all four maps, stairs and lift preserve walking geometry', () {
    final graph = museum(), live = LiveSurfaceRouter();
    for (final avoidStairs in [false, true]) {
      for (final pair in [
        ('cx_ticket', 'tg_mask'),
        ('tg_mask', 'cx_ticket'),
        ('mb_entrance', 'mg_12'),
        ('mb_6', 'tg_throne'),
      ]) {
        final route = graph.find(pair.$1, pair.$2, avoidStairs: avoidStairs)!;
        if (avoidStairs) expect(route.usesStairs, isFalse);
        for (final leg in route.legs) {
          final map = allMaps[leg.mapId]!;
          if (leg.points.length < 2) continue; // off-floor lift landing
          for (var i = 1; i < leg.points.length; i++) {
            final a = leg.points[i - 1], b = leg.points[i];
            final length = Offset(
              (a.dx - b.dx) * map.imageSize.width,
              (a.dy - b.dy) * map.imageSize.height,
            ).distance;
            for (var j = 0; j <= length.ceil(); j++) {
              expect(
                live.walkable(
                  map,
                  Offset.lerp(a, b, length == 0 ? 0 : j / length.ceil())!,
                ),
                isTrue,
                reason: '${pair} on ${map.id}',
              );
            }
          }
        }
      }
    }
  });
  test('invalid floor taps cannot snap through a wall', () {
    final g = museum();
    expect(g.nearestNodeId('main_building', const Offset(-.1, .5)), isNull);
    expect(
      g.nearestNodeId('main_building', const Offset(double.nan, .5)),
      isNull,
    );
  });
}
