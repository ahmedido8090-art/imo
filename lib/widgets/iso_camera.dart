import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lean from straight down: about 39 degrees for visible wall faces.
/// Keep a nonzero tilt so wall heights retain their 2.5D appearance.
const double kMaxTilt = 0.68;

class IsoCamera {
  IsoCamera({required this.center, required this.tilt, required Size viewport})
    : distance = math.max(viewport.width, viewport.height) * 3.0;

  final Offset center;
  final double tilt;
  final double distance;
  late final Matrix4 matrix = _build();

  Matrix4 _build() {
    final perspective = Matrix4.identity()..setEntry(3, 2, -1 / distance);
    return Matrix4.translationValues(center.dx, center.dy, 0) *
        perspective *
        Matrix4.rotationX(tilt) *
        Matrix4.translationValues(-center.dx, -center.dy, 0);
  }

  Matrix4 compose(Matrix4 flat) => matrix * flat;
  Offset toScreen(Offset flat) => project(matrix, flat.dx, flat.dy);
  Offset toFlat(Offset screen) => unproject(matrix, screen) ?? screen;
}

Offset project(Matrix4 m, double x, double y, [double z = 0]) {
  final s = m.storage;
  final w = s[3] * x + s[7] * y + s[11] * z + s[15];
  final inv = w.abs() < 1e-9 ? 1.0 : 1 / w;
  return Offset(
    (s[0] * x + s[4] * y + s[8] * z + s[12]) * inv,
    (s[1] * x + s[5] * y + s[9] * z + s[13]) * inv,
  );
}

/// Exact inverse on the z=0 plane. Rendering and hit-testing use the
/// same camera, including after pan, zoom and rotation.
Offset? unproject(Matrix4 m, Offset screen) {
  final s = m.storage;
  final a = s[0], b = s[4], c = s[12];
  final d = s[1], e = s[5], f = s[13];
  final g = s[3], h = s[7], i = s[15];
  final det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
  if (det.abs() < 1e-12) return null;
  final ia = (e * i - f * h) / det;
  final ib = (c * h - b * i) / det;
  final ic = (b * f - c * e) / det;
  final id = (f * g - d * i) / det;
  final ie = (a * i - c * g) / det;
  final iff = (c * d - a * f) / det;
  final ig = (d * h - e * g) / det;
  final ih = (b * g - a * h) / det;
  final ii = (a * e - b * d) / det;
  final x = ia * screen.dx + ib * screen.dy + ic;
  final y = id * screen.dx + ie * screen.dy + iff;
  final w = ig * screen.dx + ih * screen.dy + ii;
  if (w.abs() < 1e-12) return null;
  return Offset(x / w, y / w);
}
