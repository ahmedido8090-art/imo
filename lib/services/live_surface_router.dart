import 'dart:math' as math;
import 'dart:ui';
import '../data/floor_masks.dart';
import 'floor_grid.dart';
import '../models/map_models.dart';
import 'walkable_surface.dart';

/// Plan-space routing on the four traced visitor-map floors.
/// POI approaches are schematic arrival positions beside blocked footprints.
class LiveSurfaceRouter {
  LiveSurfaceRouter({Map<String, WalkableSurface>? surfaces})
    : _surfaces = surfaces ?? {},
      _defaults = surfaces == null;
  final Map<String, WalkableSurface> _surfaces;
  final bool _defaults;
  final Map<(String, double, double), Offset?> _approaches = {};
  final Map<(String, double, double, double, double), List<Offset>?> _routes =
      {};
  final _grids = <String, FloorGrid>{};
  bool hasMap(String id) =>
      _surfaces.containsKey(id) || (_defaults && floorMasks.containsKey(id));
  FloorGrid? _grid(String id) {
    final mask = floorMasks[id];
    if (!_defaults || mask == null) return null;
    return _grids.putIfAbsent(id, () => FloorGrid(mask.$1, mask.$2, mask.$3));
  }

  Offset _pixels(GemMap m, Offset p) =>
      Offset(p.dx * m.imageSize.width, p.dy * m.imageSize.height);
  Offset _normal(GemMap m, Offset p) =>
      Offset(p.dx / m.imageSize.width, p.dy / m.imageSize.height);
  bool walkable(GemMap m, Offset p) =>
      _grid(m.id)?.contains(_pixels(m, p)) ??
      _surfaces[m.id]?.contains(_pixels(m, p)) ??
      false;

  /// Do not connect to arbitrary junctions across a wall. For a pin drawn
  /// inside a room, find a nearby exterior floor point, limited to 80 pixels.
  Offset? approach(GemMap m, Offset p) {
    if (!p.dx.isFinite || !p.dy.isFinite) return null;
    final key = (m.id, p.dx, p.dy);
    if (_approaches.containsKey(key)) return _approaches[key];
    final grid = _grid(m.id);
    if (grid != null) {
      final q = _pixels(m, p);
      if (grid.contains(q)) return p;
      final at = grid.approach(q);
      return at == null ? null : _normal(m, at);
    }
    final surface = _surfaces[m.id];
    if (surface == null) return null;
    final q = _pixels(m, p);
    if (surface.contains(q)) return _approaches[key] = p;
    final projections = <(double, Offset)>[];
    for (final polygon in [...surface.floors, ...surface.obstacles]) {
      for (var i = 0; i < polygon.length; i++) {
        final a = polygon[i], b = polygon[(i + 1) % polygon.length], v = b - a;
        final t = v.distanceSquared < 1e-16
            ? 0.0
            : (((q - a).dx * v.dx + (q - a).dy * v.dy) / v.distanceSquared)
                  .clamp(0.0, 1.0)
                  .toDouble();
        final at = a + v * t;
        final d = (at - q).distance;
        if (d <= 81) projections.add((d, at));
      }
    }
    projections.sort((a, b) => a.$1.compareTo(b.$1));
    Offset? best;
    var distance = 80.0;
    for (final projection in projections) {
      if (projection.$1 > distance + .75) break;
      for (var k = 0; k < 16; k++) {
        final at =
            projection.$2 +
            Offset(math.cos(k * math.pi / 8), math.sin(k * math.pi / 8)) * .75;
        final d = (at - q).distance;
        if (d < distance && surface.contains(at)) {
          best = at;
          distance = d;
        }
      }
    }
    if (_approaches.length > 512) _approaches.clear();
    return _approaches[key] = best == null ? null : _normal(m, best);
  }

  List<Offset>? plan(GemMap m, Offset from, Offset to) {
    final key = (m.id, from.dx, from.dy, to.dx, to.dy);
    if (_routes.containsKey(key)) return _routes[key];
    final a = approach(m, from), b = approach(m, to);
    if (a == null || b == null) return null;
    final start = _pixels(m, a), end = _pixels(m, b);
    final path =
        _grid(m.id)?.route(start, end) ?? _surfaces[m.id]?.route(start, end);
    if (_routes.length > 256) _routes.clear();
    return _routes[key] = path == null
        ? null
        : List<Offset>.unmodifiable([for (final p in path) _normal(m, p)]);
  }
}
