import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:imo/data/gem_blocks.dart';
import 'package:imo/data/gem_figures.dart';
import 'package:imo/data/gem_floors.dart';
import 'package:imo/data/gem_map_data.dart';
import 'package:imo/data/gem_nav.dart';
import 'package:imo/models/map_models.dart';

/// A figure's base on the floor as a normalised polygon (the canvas places the
/// mesh the same way: u to the figure's left, w forward, in units of height).
List<Offset> footprintOf(MapFigure f, Size px) {
  final u = math.min(px.width, px.height), h = f.height * u;
  final fx = math.cos(f.facing), fy = math.sin(f.facing), lx = fy, ly = -fx;
  final [u0, u1, w0, w1] = f.footprint;
  return [
    for (final (a, b) in [(u0, w0), (u1, w0), (u1, w1), (u0, w1)])
      Offset((f.x * px.width + (lx * a + fx * b) * h) / px.width, (f.y * px.height + (ly * a + fy * b) * h) / px.height),
  ];
}

List<Offset> polygonOf(List<double> v) => [for (var i = 0; i + 1 < v.length; i += 2) Offset(v[i], v[i + 1])];

bool _cross(Offset a, Offset b, Offset c, Offset d) {
  double o(Offset p, Offset q, Offset r) => (q.dx - p.dx) * (r.dy - p.dy) - (q.dy - p.dy) * (r.dx - p.dx);
  return o(a, b, c) * o(a, b, d) < 0 && o(c, d, a) * o(c, d, b) < 0;
}

bool overlaps(List<Offset> a, List<Offset> b) {
  if (a.any((p) => pointInPolygon(p, b)) || b.any((p) => pointInPolygon(p, a))) return true;
  for (var i = 0; i < a.length; i++) {
    for (var j = 0; j < b.length; j++) {
      if (_cross(a[i], a[(i + 1) % a.length], b[j], b[(j + 1) % b.length])) return true;
    }
  }
  return false;
}

void main() {
  final px = allMaps['main_building']!.imageSize;
  final mosque = kFigures['main_building']!.singleWhere((f) => f.mesh == 'mosque');
  final base = footprintOf(mosque, px);

  test('the mosque marks the Prayer Room and stands wholly on its unit', () {
    expect(mosque.placeId, 'mb_prayer');
    expect(kMeshes['mosque'], isNotNull);
    final unit = kBlocks['main_building']!.singleWhere((b) => b.placeId == 'mb_prayer');
    for (final p in base) {
      expect(pointInPolygon(p, polygonOf(unit.pts)), isTrue, reason: '$p');
    }
  });

  test('the mosque touches no wall, statue or other unit', () {
    for (final b in [...kBlocks['main_building']!, ...?kExtraBlocks['main_building']]) {
      if (b.placeId == 'mb_prayer') continue;
      expect(overlaps(base, polygonOf(b.pts)), isFalse, reason: '${b.kind} ${b.placeId ?? ''}');
    }
  });

  test('the way into the Prayer Room does not run through the mosque', () {
    expect(pointInPolygon(kNavNodes['mb_prayer']!.position, base), isFalse);
  });

  test('every figure has its mesh or outline', () {
    for (final f in kFigures.values.expand((l) => l)) {
      expect(kMeshes.containsKey(f.mesh) || kSilhouettes.containsKey(f.mesh), isTrue, reason: f.id);
    }
  });
}
