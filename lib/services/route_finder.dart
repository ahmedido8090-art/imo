import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/gem_extras.dart';
import '../data/gem_paths.dart';
import '../models/map_models.dart';

enum StepKind { start, left, right, enterBuilding, exitBuilding, stairs, lift, arrive, stop }
enum RouteObjective { shortestDistance, fastestTime }

@immutable
class RouteStep {
  const RouteStep(this.kind, {required this.mapId, this.position, this.targetId,
    this.refMapId, this.floor = 0, this.down = false, this.index = 0, this.meters = 0});
  final StepKind kind;
  final String mapId;
  final Offset? position;
  final String? targetId, refMapId;
  final int floor, index;
  final bool down;
  final double meters;
  RouteStep withMeters(double m) => RouteStep(kind, mapId: mapId,
    position: position, targetId: targetId, refMapId: refMapId, floor: floor,
    down: down, index: index, meters: m);
  IconData get icon => switch (kind) {
    StepKind.start => Icons.trip_origin, StepKind.left => Icons.turn_left,
    StepKind.right => Icons.turn_right, StepKind.enterBuilding => Icons.login,
    StepKind.exitBuilding => Icons.logout, StepKind.stairs => Icons.stairs,
    StepKind.lift => Icons.elevator, StepKind.arrive => Icons.flag,
    StepKind.stop => Icons.place,
  };
}

@immutable
class RouteLeg {
  const RouteLeg(this.mapId, this.points, this.nodeIds, {this.nextMapId, this.portal});
  final String mapId;
  final List<Offset> points;
  final List<String> nodeIds;
  final String? nextMapId;
  final Portal? portal;
}

@immutable
class RouteResult {
  const RouteResult({required this.legs, required this.steps, required this.meters,
    required this.seconds, required this.usesStairs});
  final List<RouteLeg> legs;
  final List<RouteStep> steps;
  final double meters, seconds;
  final bool usesStairs;
  Duration get walkTime => Duration(seconds: seconds.round());
  List<RouteLeg> legsOn(String mapId) => [for (final l in legs) if (l.mapId == mapId) l];
}

@immutable
class TourResult {
  const TourResult({required this.order, required this.route, required this.skipped});
  final List<String> order, skipped;
  final RouteResult route;
}

class _Node {
  const _Node(this.id, this.mapId, this.pos);
  final String id, mapId;
  final Offset pos;
}

class _Edge {
  const _Edge(this.to, this.meters, this.seconds, {required this.id,
    this.stairs = false, this.portal});
  final String id, to;
  final double meters, seconds;
  final bool stairs;
  final Portal? portal;
}

/// Pedestrian routing over existing traced walkways. Shared trace vertices
/// become junctions; no unverified straight-line shortcuts are manufactured.
class MuseumGraph {
  MuseumGraph(this.maps, {this.portals = const [], this.stairEdges = const {},
    this.redirects = const {}, this.placeFloors = const {},
    Map<String, List<Offset>>? edgePaths, Map<String, String>? pinLinks})
    : _paths = edgePaths ?? kEdgePaths, _pins = pinLinks ?? kPinLinks { _build(); }
  final Map<String, GemMap> maps;
  final List<Portal> portals;
  final Set<String> stairEdges;
  final Map<String, String> redirects;
  final Map<String, int> placeFloors;
  final Map<String, List<Offset>> _paths;
  final Map<String, String> _pins;
  static const double walkSpeed = 1.25;
  final Map<String, _Node> _nodes = {};
  final Map<String, List<_Edge>> _adj = {};
  final Map<String, MapPlace> _places = {};
  final Map<(String, double, double), String> _vertices = {};
  int _sequence = 0;

  double _distance(GemMap m, Offset a, Offset b) => Offset(
    (a.dx-b.dx)*m.imageSize.width, (a.dy-b.dy)*m.imageSize.height).distance;
  int _floor(String id) => placeFloors[id] ?? maps[_nodes[id]!.mapId]!.level;
  bool _offFloor(MapPlace p, GemMap m) => placeFloors[p.id] != null &&
    placeFloors[p.id] != m.level && !redirects.containsKey(p.id);

  void _build() {
    for (final m in maps.values) {
      for (final p in m.places) {
        _nodes[p.id] = _Node(p.id, m.id, p.position); _places[p.id] = p;
      }
      m.junctions.forEach((id, pos) { _nodes[id] = _Node(id, m.id, pos); });
    }
    for (final m in maps.values) {
      for (final e in m.edges) {
        _link(e.$1, e.$2, stairs: stairEdges.contains('${e.$1}|${e.$2}') ||
          stairEdges.contains('${e.$2}|${e.$1}'));
      }
      for (final p in m.places.where((p) => p.autoConnect)) {
        final linked = _pins[p.id];
        if (linked != null && m.junctions.containsKey(linked)) {
          _link(p.id, linked, stairs: _offFloor(p, m));
        }
        // Unknown entrances remain disconnected rather than crossing walls
        // through an unchecked nearest-junction fallback.
      }
    }
    for (final p in portals) {
      _link(p.a, p.b, meters: p.meters, portal: p,
        stairs: p.kind == PortalKind.stairs);
    }
  }

  void _connect(String a, String b, double meters, {bool stairs = false, Portal? portal}) {
    if (a == b) return;
    final id = 'edge_${_sequence++}';
    final seconds = meters / walkSpeed + (portal?.kind == PortalKind.lift ? 40 : 0);
    _adj.putIfAbsent(a, () => []).add(_Edge(b, meters, seconds,
      id: id, stairs: stairs, portal: portal));
    _adj.putIfAbsent(b, () => []).add(_Edge(a, meters, seconds,
      id: id, stairs: stairs, portal: portal));
  }

  String _vertex(String mapId, Offset p) {
    // Exact coordinates only: do not merge nearby but separated walkways.
    return _vertices.putIfAbsent((mapId, p.dx, p.dy), () {
      final id = 'walk_${_sequence++}';
      _nodes[id] = _Node(id, mapId, p); return id;
    });
  }

  void _link(String a, String b, {double? meters, bool stairs = false, Portal? portal}) {
    final na = _nodes[a], nb = _nodes[b];
    if (na == null || nb == null) return;
    if (portal != null) {
      _connect(a, b, meters ?? portal.meters, stairs: stairs, portal: portal); return;
    }
    if (na.mapId != nb.mapId) return;
    final m = maps[na.mapId]!;
    final forward = a.compareTo(b) < 0;
    final stored = _paths[forward ? '$a|$b' : '$b|$a'] ?? const <Offset>[];
    final pts = <Offset>[na.pos, ...(forward ? stored : stored.reversed), nb.pos];
    var at = a;
    for (var i = 0; i < pts.length; i++) {
      // Stair/off-floor traces must not join ordinary floor-level paths.
      final id = stairs ? (i == 0 ? a : i == pts.length-1 ? b : 'stair_${_sequence++}')
        : _vertex(na.mapId, pts[i]);
      _nodes.putIfAbsent(id, () => _Node(id, na.mapId, pts[i]));
      _connect(at, id, i == 0 ? 0 : _distance(m, pts[i-1], pts[i])*m.metersPerPixel,
        stairs: stairs);
      at = id;
    }
    _connect(at, b, 0, stairs: stairs);
  }

  bool has(String id) => _nodes.containsKey(id);
  String normalizeNodeId(String id) {
    final seen = <String>{};
    while (redirects.containsKey(id) && seen.add(id)) { id = redirects[id]!; }
    return id;
  }
  Offset? positionOf(String id) => _nodes[id]?.pos;
  String? mapOf(String id) => _nodes[id]?.mapId;

  /// Compatibility API: returns a routable projected node, not an endpoint.
  /// Splitting preserves both directions and also supports two taps on one edge.
  String? nearestNodeId(String mapId, Offset pos) {
    final m = maps[mapId]; if (m == null) return null;
    String? from;
    _Edge? selected;
    Offset? projection;
    var best = double.infinity;
    var fraction = 0.0;
    for (final entry in _adj.entries) {
      final a = _nodes[entry.key]!;
      if (a.mapId != mapId) continue;
      for (final e in entry.value) {
        final b = _nodes[e.to]!;
        if (e.portal != null || e.stairs || b.mapId != mapId ||
            _floor(a.id) != m.level || _floor(b.id) != m.level) continue;
        final v = Offset((b.pos.dx-a.pos.dx)*m.imageSize.width,
          (b.pos.dy-a.pos.dy)*m.imageSize.height);
        if (v.distanceSquared < 1e-16) continue;
        final w = Offset((pos.dx-a.pos.dx)*m.imageSize.width,
          (pos.dy-a.pos.dy)*m.imageSize.height);
        final t = ((w.dx*v.dx+w.dy*v.dy)/v.distanceSquared).clamp(0.0, 1.0).toDouble();
        final p = a.pos+(b.pos-a.pos)*t;
        final d = _distance(m, pos, p);
        if (d < best) {
          best = d; from = a.id; selected = e; projection = p; fraction = t;
        }
      }
    }
    if (from == null || selected == null || projection == null) return null;
    if (fraction <= 1e-9) return from;
    if (fraction >= 1-1e-9) return selected.to;
    final id = 'snap_${_sequence++}';
    _nodes[id] = _Node(id, mapId, projection);
    _adj[from]!.removeWhere((e) => e.id == selected!.id);
    _adj[selected.to]!.removeWhere((e) => e.id == selected!.id);
    _connect(from, id, selected.meters*fraction);
    _connect(id, selected.to, selected.meters*(1-fraction));
    return id;
  }

  ({Map<String, double> dist, Map<String, (String, _Edge)> prev}) _search(
    String start, bool avoidStairs, RouteObjective objective, {String? stopAt}) {
    final dist = <String, double>{start: 0};
    final prev = <String, (String, _Edge)>{};
    final open = <String>{start}, closed = <String>{};
    while (open.isNotEmpty) {
      final at = open.reduce((a, b) => dist[a]! <= dist[b]! ? a : b);
      open.remove(at);
      if (at == stopAt) break;
      closed.add(at);
      for (final e in _adj[at] ?? const <_Edge>[]) {
        if (closed.contains(e.to) || (avoidStairs && e.stairs)) continue;
        final cost = dist[at]! + (objective == RouteObjective.shortestDistance ? e.meters : e.seconds);
        if (cost < (dist[e.to] ?? double.infinity)) {
          dist[e.to] = cost; prev[e.to] = (at, e); open.add(e.to);
        }
      }
    }
    return (dist: dist, prev: prev);
  }

  RouteResult? find(String from, String to, {bool avoidStairs = false,
    RouteObjective objective = RouteObjective.shortestDistance}) {
    from = normalizeNodeId(from); to = normalizeNodeId(to);
    if (!has(from) || !has(to)) return null;
    final r = _search(from, avoidStairs, objective, stopAt: to);
    if (!r.dist.containsKey(to)) return null;
    final reversed = <_Edge>[];
    var at = to;
    while (at != from) {
      final p = r.prev[at]; if (p == null) return null;
      reversed.add(p.$2); at = p.$1;
    }
    return _assemble(from, reversed.reversed.toList());
  }

  RouteResult _assemble(String start, List<_Edge> edges) {
    final legs = <RouteLeg>[];
    final raw = <(RouteStep, double)>[];
    var at = start, mapId = _nodes[start]!.mapId;
    var ids = <String>[start], points = <Offset>[_nodes[start]!.pos];
    var meters = 0.0, seconds = 0.0;
    var stairs = false;
    raw.add((RouteStep(StepKind.start, mapId: mapId, position: points.first,
      targetId: _places.containsKey(start) ? start : null), 0));
    void close({String? next, Portal? portal}) {
      legs.add(RouteLeg(mapId, List.of(points), List.of(ids), nextMapId: next, portal: portal));
    }
    for (final e in edges) {
      final a = _nodes[at]!, b = _nodes[e.to]!;
      if (e.portal != null) {
        final p = e.portal!;
        final leaving = (kOutdoorMaps.contains(b.mapId) && !kOutdoorMaps.contains(a.mapId)) ||
          kSubMapParent[a.mapId] == b.mapId;
        final kind = switch (p.kind) {
          PortalKind.door => leaving ? StepKind.exitBuilding : StepKind.enterBuilding,
          PortalKind.stairs => StepKind.stairs, PortalKind.lift => StepKind.lift,
        };
        raw.add((RouteStep(kind, mapId: a.mapId, position: a.pos,
          refMapId: leaving ? a.mapId : b.mapId, floor: _floor(b.id),
          down: _floor(b.id) < _floor(a.id)), meters));
        if (a.mapId != b.mapId) {
          close(next: b.mapId, portal: p);
          mapId = b.mapId; ids = <String>[]; points = <Offset>[];
        }
      }
      ids.add(b.id);
      if (points.isEmpty || points.last != b.pos) points.add(b.pos);
      meters += e.meters; seconds += e.seconds; stairs = stairs || e.stairs;
      at = b.id; // Also advance after portals.
    }
    close();
    // Instructions follow the actual polyline, including bends within old edges.
    // Small raster steps do not generate a turn at every pixel.
    var base = 0.0;
    for (final leg in legs) {
      final m = maps[leg.mapId]!;
      var anchor = 0, previousTurn = 0;
      for (var i = 1; i+1 < leg.points.length; i++) {
        if (_distance(m, leg.points[anchor], leg.points[i]) < 10) continue;
        var j = i+1;
        while (j+1 < leg.points.length && _distance(m, leg.points[i], leg.points[j]) < 10) { j++; }
        final a = leg.points[i]-leg.points[anchor], b = leg.points[j]-leg.points[i];
        final va = Offset(a.dx*m.imageSize.width, a.dy*m.imageSize.height);
        final vb = Offset(b.dx*m.imageSize.width, b.dy*m.imageSize.height);
        final angle = math.atan2(va.dx*vb.dy-va.dy*vb.dx, va.dx*vb.dx+va.dy*vb.dy);
        if (angle.abs() > 0.6 && vb.distance >= 10) {
          var distance = base;
          for (var k = 1; k <= i; k++) {
            distance += _distance(m, leg.points[k-1], leg.points[k])*m.metersPerPixel;
          }
          raw.add((RouteStep(angle > 0 ? StepKind.right : StepKind.left,
            mapId: leg.mapId, position: leg.points[i]), distance));
          previousTurn = i; anchor = i;
        } else if (i-previousTurn > 1) { anchor = i-1; }
      }
      for (var i = 1; i < leg.points.length; i++) {
        base += _distance(m, leg.points[i-1], leg.points[i])*m.metersPerPixel;
      }
      if (leg.portal != null) base += leg.portal!.meters;
    }
    raw.add((RouteStep(StepKind.arrive, mapId: _nodes[at]!.mapId,
      position: _nodes[at]!.pos, targetId: _places.containsKey(at) ? at : null), meters));
    raw.sort((a, b) => a.$2.compareTo(b.$2));
    final steps = <RouteStep>[for (var i = 0; i < raw.length; i++)
      raw[i].$1.withMeters(i+1 < raw.length ? math.max(0.0, raw[i+1].$2-raw[i].$2) : 0)];
    return RouteResult(legs: legs, steps: steps, meters: meters,
      seconds: seconds, usesStairs: stairs);
  }

  TourResult? tour(String start, List<String> stops, {bool avoidStairs = false, bool optimize = true}) =>
    tourWithObjective(start, stops, avoidStairs: avoidStairs, optimize: optimize);

  TourResult? tourWithObjective(String start, List<String> stops, {bool avoidStairs = false,
    bool optimize = true, RouteObjective objective = RouteObjective.shortestDistance}) {
    start = normalizeNodeId(start); if (!has(start)) return null;
    final ids = stops.map(normalizeNodeId).where((id) => id != start).toSet().toList();
    final skipped = <String>[];
    final distances = <String, Map<String, double>>{};
    for (final id in <String>[start, ...ids.where(has)]) {
      distances[id] = _search(id, avoidStairs, objective).dist;
    }
    final remaining = <String>[];
    for (final id in ids) {
      if (!has(id) || !(distances[start]?[id] ?? double.infinity).isFinite) {
        skipped.add(id);
      } else { remaining.add(id); }
    }
    if (remaining.isEmpty) return null;
    var order = <String>[];
    var at = start;
    while (remaining.isNotEmpty) {
      if (optimize) remaining.sort((a, b) =>
        (distances[at]?[a] ?? double.infinity).compareTo(distances[at]?[b] ?? double.infinity));
      at = remaining.removeAt(0); order.add(at);
    }
    double cost(List<String> list) {
      var sum = 0.0, prev = start;
      for (final id in list) { sum += distances[prev]?[id] ?? double.infinity; prev = id; }
      return sum;
    }
    if (optimize) {
      var improved = true;
      while (improved) {
        improved = false;
        for (var i = 0; i+1 < order.length; i++) {
          for (var j = i+1; j < order.length; j++) {
            final candidate = [...order.take(i), ...order.sublist(i,j+1).reversed, ...order.skip(j+1)];
            if (cost(candidate)+1e-6 < cost(order)) { order = candidate; improved = true; }
          }
        }
      }
    }
    final legs = <RouteLeg>[], steps = <RouteStep>[];
    var meters = 0.0, seconds = 0.0;
    var stairs = false;
    at = start;
    for (var i = 0; i < order.length; i++) {
      final r = find(at, order[i], avoidStairs: avoidStairs, objective: objective);
      if (r == null) { skipped.add(order[i]); continue; }
      legs.addAll(r.legs);
      for (final s in r.steps) {
        if (s.kind == StepKind.start && i > 0) continue;
        steps.add(s.kind == StepKind.arrive ? RouteStep(StepKind.stop,
          mapId: s.mapId, position: s.position, targetId: s.targetId, index: i+1) : s);
      }
      meters += r.meters; seconds += r.seconds; stairs = stairs || r.usesStairs;
      at = order[i];
    }
    return TourResult(order: order, skipped: skipped, route: RouteResult(
      legs: legs, steps: steps, meters: meters, seconds: seconds, usesStairs: stairs));
  }
}
