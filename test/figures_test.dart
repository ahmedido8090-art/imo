import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:imo/data/gem_blocks.dart';
import 'package:imo/data/gem_figures.dart';
import 'package:imo/data/gem_floors.dart';
import 'package:imo/data/gem_map_data.dart';
import 'package:imo/data/gem_nav.dart';
import 'package:imo/models/map_models.dart';

/// The Prayer Room's unit as the plan draws it (normalised): the mosque takes
/// its place, so it is no longer in gem_blocks.dart.
const _prayerRoom = [
  0.5505, 0.1438, 0.5509, 0.1498, 0.5539, 0.1524, 0.5905, 0.1483, 0.5921, 0.1450, 0.5999, 0.1079, //
  0.5999, 0.1033, 0.5982, 0.1000, 0.5965, 0.0994, 0.5600, 0.1035, 0.5584, 0.1068,
];

/// A mesh figure's vertices on the floor, normalised, placed as the canvas
/// places them (u to the figure's left, w forward, in units of its height).
List<Offset> footOf(MapFigure f, Size px) {
  final mesh = kMeshes[f.mesh]!;
  final h = f.height * math.min(px.width, px.height);
  final fx = math.cos(f.facing), fy = math.sin(f.facing), lx = fy, ly = -fx;
  return [
    for (var i = 0; i < mesh.verts.length; i += 3)
      if (mesh.verts[i + 2] <= 0.001)
        Offset(
          (f.x * px.width + (lx * mesh.verts[i] + fx * mesh.verts[i + 1]) * h) / px.width,
          (f.y * px.height + (ly * mesh.verts[i] + fy * mesh.verts[i + 1]) * h) / px.height,
        ),
  ];
}

List<Offset> polygonOf(List<double> v) => [for (var i = 0; i + 1 < v.length; i += 2) Offset(v[i], v[i + 1])];

List<Offset> hullOf(List<Offset> pts) {
  final p = [...pts]..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
  double cross(Offset o, Offset a, Offset b) => (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
  final lo = <Offset>[], up = <Offset>[];
  for (final q in p) {
    while (lo.length > 1 && cross(lo[lo.length - 2], lo.last, q) <= 0) {
      lo.removeLast();
    }
    lo.add(q);
  }
  for (final q in p.reversed) {
    while (up.length > 1 && cross(up[up.length - 2], up.last, q) <= 0) {
      up.removeLast();
    }
    up.add(q);
  }
  return [...lo.sublist(0, lo.length - 1), ...up.sublist(0, up.length - 1)];
}

/// Area in map px.
double areaOf(List<Offset> poly, Size px) {
  var s = 0.0;
  for (var i = 0; i < poly.length; i++) {
    final a = poly[i], b = poly[(i + 1) % poly.length];
    s += a.dx * px.width * b.dy * px.height - b.dx * px.width * a.dy * px.height;
  }
  return s.abs() / 2;
}

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
  final base = hullOf(footOf(mosque, px));
  final room = polygonOf(_prayerRoom);

  test('the mosque takes the Prayer Room over: it fills the room and stays inside it', () {
    expect(mosque.placeId, 'mb_prayer');
    // the room's unit is not drawn any more: the mosque stands in its place
    expect(kBlocks['main_building']!.where((b) => b.placeId == 'mb_prayer'), isEmpty);
    // its base reaches the room's outline (the unit has its corners cut: up to 5 px)...
    final grown = hullOf([for (final p in room) ...[for (final d in const [Offset(-5, -5), Offset(5, -5), Offset(5, 5), Offset(-5, 5)]) p + Offset(d.dx / px.width, d.dy / px.height)]]);
    for (final p in base) {
      expect(pointInPolygon(p, grown), isTrue, reason: '$p');
    }
    // ...and covers nearly all of it
    expect(areaOf(base, px) / areaOf(room, px), greaterThan(0.95));
  });

  test('the mosque touches no wall, statue or other unit', () {
    for (final b in [...kBlocks['main_building']!, ...?kExtraBlocks['main_building']]) {
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
