import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/map_models.dart';
import '../lib/services/live_surface_router.dart';
import '../lib/services/route_finder.dart';
import '../lib/services/walkable_surface.dart';

List<Offset> rectangle(double l,double t,double r,double b)=>
  [Offset(l,t),Offset(r,t),Offset(r,b),Offset(l,b)];
GemMap plan()=>const GemMap(id:'main_building',title:'Test',shortTitle:'Test',
  asset:'',imageSize:Size(1000,1000),places:[],entranceId:'a',
  junctions:{'a':Offset(.1,.1),'b':Offset(.9,.1),'detour':Offset(.5,.9)},
  edges:[('a','detour'),('detour','b')]);
MuseumGraph graph(WalkableSurface surface)=>MuseumGraph({'main_building':plan()},
  edgePaths:const {},pinLinks:const {},
  surfaceRouter:LiveSurfaceRouter(surfaces:{'main_building':surface}));
void main() {
  test('normal find uses the surface instead of the legacy dogleg',() {
    final g=graph(WalkableSurface(floors:[rectangle(0,0,1000,1000)]));
    final route=g.find('a','b')!;
    expect(route.legs.single.points,[const Offset(.1,.1),const Offset(.9,.1)]);
    expect(route.meters,closeTo(224,1e-6));
    expect(route.steps.map((s)=>s.kind),[StepKind.start,StepKind.arrive]);
  });
  test('no silent legacy fallback across disconnected floor regions',() {
    final g=graph(WalkableSurface(floors:[rectangle(0,0,200,200),rectangle(800,0,1000,200)]));
    expect(g.find('a','b'),isNull);
  });
  test('tap origins retain their actual open-floor coordinates',() {
    final g=graph(WalkableSurface(floors:[rectangle(0,0,1000,1000)]));
    final id=g.nearestNodeId('main_building',const Offset(.25,.25))!;
    expect(g.positionOf(id),const Offset(.25,.25));
    expect(g.find(id,'b')!.legs.single.points.first,const Offset(.25,.25));
    final restored=graph(WalkableSurface(floors:[rectangle(0,0,1000,1000)]));
    expect(restored.positionOf(id),const Offset(.25,.25));
    expect(restored.find(id,'b'),isNotNull);
  });
  test('tour distances and legs use the live surface',() {
    final g=graph(WalkableSurface(floors:[rectangle(0,0,1000,1000)]));
    final tour=g.tour('a',['b'],optimize:false)!;
    expect(tour.route.meters,closeTo(224,1e-6));
    expect(tour.route.legs.single.points.length,2);
  });
  test('room-pin approach stays on modeled floor',() {
    final surface=WalkableSurface(floors:[rectangle(0,0,1000,1000)],
      obstacles:[rectangle(450,450,550,550)]);
    final live=LiveSurfaceRouter(surfaces:{'main_building':surface});
    final approach=live.approach(plan(),const Offset(.5,.5));
    expect(approach,isNotNull);
    expect(live.walkable(plan(),approach!),isTrue);
    expect(approach,isNot(const Offset(.5,.5)));
  });
}
