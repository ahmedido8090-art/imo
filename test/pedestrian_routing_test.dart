import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/map_models.dart';
import '../lib/services/route_finder.dart';

GemMap plan(String id, Map<String, Offset> nodes, List<(String, String)> edges) => GemMap(
  id: id, title: id, shortTitle: id, asset: '', imageSize: const Size(1000, 1000),
  places: const [], entranceId: nodes.keys.first, junctions: nodes, edges: edges);

void main() {
  test('shared trace vertex permits an earlier pedestrian connection', () {
    final m = plan('test', {'a': const Offset(.1,.5), 'b': const Offset(.9,.5),
      'c': const Offset(.5,.1), 'd': const Offset(.9,.9)}, [('a','b'),('c','d')]);
    final g = MuseumGraph({'test': m}, pinLinks: const {}, edgePaths: const {
      'a|b': [Offset(.5,.5)], 'c|d': [Offset(.5,.5)],
    });
    final route = g.find('a','c');
    expect(route, isNotNull);
    expect(route!.legs.single.points, contains(const Offset(.5,.5)));
    expect(route.legs.single.points, isNot(contains(const Offset(.9,.5))));
  });
  test('two taps on the same edge route between projections', () {
    final m = plan('test', {'a': const Offset(.1,.5), 'b': const Offset(.9,.5)}, [('a','b')]);
    final g = MuseumGraph({'test': m}, edgePaths: const {}, pinLinks: const {});
    final a = g.nearestNodeId('test', const Offset(.3,.52))!;
    final b = g.nearestNodeId('test', const Offset(.6,.48))!;
    final route = g.find(a,b)!;
    expect(g.positionOf(a)!.dx, closeTo(.3,1e-9));
    expect(g.positionOf(b)!.dx, closeTo(.6,1e-9));
    expect(route.legs.single.points.first.dy, closeTo(.5,1e-9));
    expect(route.legs.single.points, isNot(contains(const Offset(.9,.5))));
    expect(g.find(b,a)!.meters, closeTo(route.meters,1e-9));
  });
  test('portal advances current node and arrives on destination map', () {
    final a = plan('test_a', {'a': const Offset(.1,.1), 'door_a': const Offset(.2,.1)}, [('a','door_a')]);
    final b = plan('test_b', {'door_b': const Offset(.7,.7), 'b': const Offset(.8,.7)}, [('door_b','b')]);
    final g = MuseumGraph({'test_a': a, 'test_b': b}, edgePaths: const {}, pinLinks: const {},
      portals: const [Portal('door_a','door_b',PortalKind.door)]);
    final route = g.find('a','b')!;
    expect(route.legs.map((l)=>l.mapId), ['test_a','test_b']);
    expect(route.legs.last.points.first, const Offset(.7,.7));
    expect(route.steps.last.kind, StepKind.arrive);
    expect(route.steps.last.mapId, 'test_b');
  });
  test('stairs stay unavailable in step-free mode', () {
    final m = plan('test', {'a': const Offset(.1,.1), 'b': const Offset(.2,.2)}, [('a','b')]);
    final g = MuseumGraph({'test': m}, edgePaths: const {}, pinLinks: const {}, stairEdges: const {'a|b'});
    expect(g.find('a','b'), isNotNull);
    expect(g.find('a','b',avoidStairs: true), isNull);
  });
  test('nearby disconnected traces are not merged', () {
    final m = plan('test', {'a': const Offset(.1,.1), 'b': const Offset(.2,.1),
      'c': const Offset(.1,.10001), 'd': const Offset(.2,.10001)}, [('a','b'),('c','d')]);
    final g = MuseumGraph({'test': m}, edgePaths: const {}, pinLinks: const {});
    expect(g.find('a','d'), isNull);
  });
}
