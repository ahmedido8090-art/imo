import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imo/data/gem_extras.dart';
import 'package:imo/data/gem_map_data.dart';
import 'package:imo/services/route_finder.dart';
import 'package:imo/models/map_models.dart';

GemMap _map({
  required String id,
  required Map<String, Offset> junctions,
  List<(String, String)> edges = const [],
}) {
  return GemMap(
    id: id,
    title: id,
    shortTitle: id,
    asset: 'assets/maps/light/main_building.svg',
    imageSize: const Size(1000, 1000),
    places: const [],
    entranceId: junctions.keys.first,
    junctions: junctions,
    edges: edges,
  );
}

void main() {
  test('selects by shortest distance vs fastest time', () {
    final g = MuseumGraph(
      {
        'a': _map(
          id: 'a',
          junctions: {
            'start': const Offset(0, 0),
            'lift_link': const Offset(0.01, 0),
            'mid': const Offset(0, 0.02),
            'end': const Offset(0.02, 0.02),
          },
          edges: const [
            ('start', 'lift_link'),
            ('start', 'mid'),
            ('mid', 'end'),
          ],
        ),
      },
      portals: const [Portal('lift_link', 'end', PortalKind.lift, meters: 10)],
    );

    final shortest = g.find('start', 'end', objective: RouteObjective.shortestDistance)!;
    final fastest = g.find('start', 'end', objective: RouteObjective.fastestTime)!;

    expect(shortest.steps.any((s) => s.kind == StepKind.lift), isTrue);
    expect(fastest.steps.any((s) => s.kind == StepKind.lift), isFalse);
    expect(shortest.meters, lessThan(fastest.meters));
    expect(shortest.seconds, greaterThan(fastest.seconds));
  });

  test('avoidStairs excludes stair links', () {
    final g = MuseumGraph(
      {
        'a': _map(
          id: 'a',
          junctions: {
            'start': const Offset(0, 0),
            'mid': const Offset(0.01, 0),
            'detour': const Offset(0, 0.8),
            'end': const Offset(0.01, 0.8),
          },
          edges: const [
            ('start', 'mid'),
            ('mid', 'end'),
            ('start', 'detour'),
            ('detour', 'end'),
          ],
        ),
      },
      stairEdges: const {'mid|end'},
    );

    final normal = g.find('start', 'end', avoidStairs: false)!;
    final stepFree = g.find('start', 'end', avoidStairs: true)!;

    expect(normal.usesStairs, isTrue);
    expect(stepFree.usesStairs, isFalse);
  });

  test('parallel stairs/lift edges keep chosen edge identity', () {
    final g = MuseumGraph(
      {
        'a': _map(
          id: 'a',
          junctions: {
            'start': const Offset(0, 0),
            'hub': const Offset(0.02, 0),
            'dest': const Offset(0.04, 0),
          },
          edges: const [('start', 'hub')],
        ),
      },
      portals: const [
        Portal('hub', 'dest', PortalKind.stairs, meters: 1),
        Portal('hub', 'dest', PortalKind.lift, meters: 100),
      ],
    );

    final r = g.find('start', 'dest', avoidStairs: true)!;
    expect(r.usesStairs, isFalse);
    expect(r.steps.any((s) => s.kind == StepKind.lift), isTrue);
    expect(r.steps.any((s) => s.kind == StepKind.stairs), isFalse);
  });

  test('normalizes redirects for source and destination', () {
    final g = MuseumGraph(
      {
        'a': _map(
          id: 'a',
          junctions: {
            'start': const Offset(0, 0),
            'end': const Offset(0.1, 0),
          },
          edges: const [('start', 'end')],
        ),
      },
      redirects: const {'alias': 'end'},
    );

    final toAlias = g.find('start', 'alias');
    final sameByRedirect = g.find('alias', 'end');
    expect(toAlias, isNotNull);
    expect(sameByRedirect, isNotNull);
    expect(sameByRedirect!.meters, 0);
  });

  test('returns null for unreachable destinations', () {
    final g = MuseumGraph(
      {
        'a': _map(
          id: 'a',
          junctions: {
            'start': const Offset(0, 0),
            'end': const Offset(0.1, 0),
            'isolated': const Offset(0.9, 0.9),
          },
          edges: const [('start', 'end')],
        ),
      },
    );

    expect(g.find('start', 'isolated'), isNull);
  });

  test('assembles multi-map routes across GEM plans', () {
    final g = MuseumGraph(
      allMaps,
      portals: kPortals,
      stairEdges: kStairEdges,
      redirects: kRouteRedirects,
      placeFloors: kPlaceFloor,
    );

    final r = g.find('cx_ticket', 'tg_mask');
    expect(r, isNotNull);
    final maps = r!.legs.map((l) => l.mapId).toSet();
    expect(maps.contains('gem_complex'), isTrue);
    expect(maps.contains('main_building'), isTrue);
    expect(maps.contains('main_galleries'), isTrue);
    expect(maps.contains('tutankhamun'), isTrue);
  });
}
