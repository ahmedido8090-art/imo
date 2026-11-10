import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:collection/collection.dart';

/// A cell covers four SVG pixels on each axis. All geometry is in plan space.
class FloorGrid {
  FloorGrid(this.columns, this.rows, String bits) : _open = base64Decode(bits);
  final int columns, rows;
  final Uint8List _open;
  static const cell = 4;

  bool _free(int x, int y) {
    if (x < 0 || y < 0 || x >= columns || y >= rows) return false;
    final i = y * columns + x;
    return (_open[i >> 3] & (1 << (i & 7))) != 0;
  }

  bool contains(Offset p) =>
      p.dx.isFinite &&
      p.dy.isFinite &&
      _free((p.dx / cell).floor(), (p.dy / cell).floor());

  Offset _center(int i) =>
      Offset((i % columns + .5) * cell, (i ~/ columns + .5) * cell);

  int _index(Offset p) =>
      (p.dy / cell).floor() * columns + (p.dx / cell).floor();

  Offset? approach(Offset p, {double radius = 80}) {
    if (contains(p)) return p;
    Offset? best;
    var limit = radius * radius;
    for (
      int y = math.max(0, ((p.dy - radius) / cell).floor());
      y < rows && y * cell <= p.dy + radius;
      y++
    ) {
      for (
        int x = math.max(0, ((p.dx - radius) / cell).floor());
        x < columns && x * cell <= p.dx + radius;
        x++
      ) {
        if (!_free(x, y)) continue;
        final q = _center(y * columns + x);
        final distance = (p - q).distanceSquared;
        if (distance < limit) {
          best = q;
          limit = distance;
        }
      }
    }
    return best;
  }

  /// Visit every grid cell crossed by the segment, including both neighbors
  /// at a diagonal corner. Never smooth through a display case or thin wall.
  bool visible(Offset a, Offset b) {
    if (!contains(a) || !contains(b)) return false;
    var x = (a.dx / cell).floor(), y = (a.dy / cell).floor();
    final endX = (b.dx / cell).floor(), endY = (b.dy / cell).floor();
    final d = b - a, sx = d.dx.sign.toInt(), sy = d.dy.sign.toInt();
    final dx = sx == 0 ? double.infinity : cell / d.dx.abs();
    final dy = sy == 0 ? double.infinity : cell / d.dy.abs();
    var tx = sx == 0
        ? double.infinity
        : ((x + (sx > 0 ? 1 : 0)) * cell - a.dx) / d.dx;
    var ty = sy == 0
        ? double.infinity
        : ((y + (sy > 0 ? 1 : 0)) * cell - a.dy) / d.dy;
    while (x != endX || y != endY) {
      if (x != endX && y != endY && (tx - ty).abs() < 1e-10) {
        if (!_free(x + sx, y) || !_free(x, y + sy)) return false;
        x += sx;
        y += sy;
        tx += dx;
        ty += dy;
      } else if (y == endY || (x != endX && tx < ty)) {
        x += sx;
        tx += dx;
      } else {
        y += sy;
        ty += dy;
      }
      if (!_free(x, y)) return false;
    }
    return true;
  }

  List<Offset>? route(Offset start, Offset goal) {
    if (!contains(start) || !contains(goal)) return null;
    if (start == goal) return [start];
    if (visible(start, goal)) return [start, goal];
    final source = _index(start), target = _index(goal);
    final costs = Float64List(columns * rows)
      ..fillRange(0, columns * rows, double.infinity);
    final previous = Int32List(columns * rows);
    final open = HeapPriorityQueue<({int id, double cost, double estimate})>(
      (a, b) => a.estimate.compareTo(b.estimate),
    );
    final end = _center(target);
    costs[source] = 0;
    open.add((id: source, cost: 0, estimate: 0));
    while (open.isNotEmpty) {
      final at = open.removeFirst();
      if (at.cost != costs[at.id]) continue;
      if (at.id == target) {
        final reverse = [goal];
        for (var id = target; ; id = previous[id]) {
          reverse.add(_center(id));
          if (id == source) break;
        }
        final path = [start, ...reverse.reversed];
        final result = [start];
        var anchor = 0;
        while (anchor < path.length - 1) {
          var next = path.length - 1;
          while (next > anchor + 1 && !visible(path[anchor], path[next])) {
            next--;
          }
          if (result.last != path[next]) result.add(path[next]);
          anchor = next;
        }
        return result;
      }
      final x = at.id % columns, y = at.id ~/ columns;
      for (var j = -1; j <= 1; j++) {
        for (var i = -1; i <= 1; i++) {
          if (i == 0 && j == 0 || !_free(x + i, y + j)) continue;
          final diagonal = i != 0 && j != 0;
          if (diagonal && (!_free(x + i, y) || !_free(x, y + j))) continue;
          final id = (y + j) * columns + x + i;
          final cost = at.cost + (diagonal ? math.sqrt2 : 1) * cell;
          if (cost >= costs[id]) continue;
          costs[id] = cost;
          previous[id] = at.id;
          open.add((
            id: id,
            cost: cost,
            estimate: cost + (_center(id) - end).distance,
          ));
        }
      }
    }
    return null;
  }
}
