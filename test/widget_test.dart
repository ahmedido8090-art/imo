import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imo/app.dart';
import 'package:imo/data/gem_extras.dart';
import 'package:imo/widgets/museum_map_canvas.dart';

void main() {
  testWidgets('I am here and Start route update the normal tilted map', (
    tester,
  ) async {
    await tester.pumpWidget(const GemNavigatorApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    var canvas = tester.widget<MuseumMapCanvas>(find.byType(MuseumMapCanvas));
    canvas.onPlaceTap(placeById('mb_entrance')!);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.text("I'm here"));
    await tester.tap(find.text("I'm here"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    canvas = tester.widget<MuseumMapCanvas>(find.byType(MuseumMapCanvas));
    expect(canvas.originMapId, 'main_building');
    expect(canvas.originPos, isNotNull);
    expect(canvas.tilted, isTrue);

    canvas.onPlaceTap(placeById('mb_1')!);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.text('Start route'));
    await tester.tap(find.text('Start route'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    canvas = tester.widget<MuseumMapCanvas>(find.byType(MuseumMapCanvas));
    expect(canvas.legs, isNotEmpty);
    expect(canvas.legs.first.points.first, canvas.originPos);
    expect(canvas.routeTargetId, 'mb_1');

    // A new origin on the destination clears the previous route.
    canvas.onPlaceTap(placeById('mb_1')!);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.text("I'm here"));
    await tester.tap(find.text("I'm here"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    canvas = tester.widget<MuseumMapCanvas>(find.byType(MuseumMapCanvas));
    expect(canvas.legs, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
