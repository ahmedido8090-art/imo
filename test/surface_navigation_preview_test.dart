import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/data/main_building_surface_draft.dart';
import '../lib/screens/surface_navigation_screen.dart';

void main() {
  test('draft geometry loads the PDF obstacle candidates',() {
    final surface=buildMainBuildingDraftSurface();
    expect(surface.floors.length,1);
    expect(surface.obstacles.length,65);
    expect(surface.contains(const Offset(1280,175)),isTrue);
    expect(surface.contains(const Offset(1385,325)),isTrue);
    expect(surface.contains(const Offset(1204,293)),isFalse);
  });
  test('preview callback invokes the new engine and validates every segment',() {
    final points=runSurfacePreview({'start':[1280.0,175.0],'end':[1385.0,325.0]});
    expect(points,isNotNull);
    final path=[for(final p in points!)Offset(p[0],p[1])];
    expect(path.first,const Offset(1280,175));
    expect(path.last,const Offset(1385,325));
    final surface=buildMainBuildingDraftSurface();
    for(var i=1;i<path.length;i++) {expect(surface.visible(path[i-1],path[i]),isTrue);}
  });
  testWidgets('preview is explicitly labelled and does not calculate automatically',(tester) async {
    await tester.pumpWidget(const MaterialApp(home:SurfaceNavigationScreen()));
    await tester.pumpAndSettle();
    expect(find.text('New walking engine'),findsOneWidget);
    expect(find.byKey(const Key('surface-preview-warning')),findsOneWidget);
    expect(find.text('Example'),findsOneWidget);
    final button=tester.widget<FilledButton>(find.widgetWithText(FilledButton,'Route'));
    expect(button.onPressed,isNull);
  });
}
