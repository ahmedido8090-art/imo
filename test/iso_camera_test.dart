import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/widgets/iso_camera.dart';

void main() {
  test('default tilt is more overhead without flattening the map', () {
    expect(kMaxTilt, closeTo(0.50, 1e-12));
    expect(kMaxTilt, greaterThan(0));
    expect(kMaxTilt, lessThan(0.92));
  });

  test('screen-to-floor round trips preserve tap coordinates', () {
    final camera = IsoCamera(center: const Offset(400, 300),
      tilt: kMaxTilt, viewport: const Size(800, 600));
    final flat = Matrix4.identity()
      ..translate(120.0, 80.0)
      ..rotateZ(0.3)
      ..scale(1.7, 1.7, 1.7);
    final full = camera.compose(flat);
    for (final p in [const Offset(0, 0), const Offset(100, 250),
      const Offset(800, 500)]) {
      final restored = unproject(full, project(full, p.dx, p.dy));
      expect(restored, isNotNull);
      expect(restored!.dx, closeTo(p.dx, 1e-7));
      expect(restored.dy, closeTo(p.dy, 1e-7));
    }
  });

  test('nonzero wall heights still project differently from the floor', () {
    final camera = IsoCamera(center: const Offset(400, 300),
      tilt: kMaxTilt, viewport: const Size(800, 600));
    final ground = project(camera.matrix, 400, 300, 0);
    final roof = project(camera.matrix, 400, 300, 30);
    expect((roof - ground).distance, greaterThan(0));
    expect(camera.distance, 2400);
  });
}
