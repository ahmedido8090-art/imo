import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/walkable_surface.dart';
List<Offset> rect(double l,double t,double r,double b) =>
  [Offset(l,t),Offset(r,t),Offset(r,b),Offset(l,b)];
void main() {
  test('open floor routes directly without artificial turns',(){
    final s=WalkableSurface(floors:[rect(0,0,100,100)]);
    expect(s.route(const Offset(10,10),const Offset(90,90)),
      [const Offset(10,10),const Offset(90,90)]);
  });
  test('blocked straight path uses only obstacle-free segments',(){
    final s=WalkableSurface(floors:[rect(0,0,100,100)],
      obstacles:[rect(40,20,60,80)]);
    final r=s.route(const Offset(10,50),const Offset(90,50))!;
    expect(r.length,greaterThan(2));
    for(var i=1;i<r.length;i++) { expect(s.visible(r[i-1],r[i]),true); }
  });
  test('disconnected floor regions do not gain a fabricated passage',(){
    final s=WalkableSurface(floors:[rect(0,0,10,10),rect(20,0,30,10)]);
    expect(s.route(const Offset(5,5),const Offset(25,5)),isNull);
  });
  test('concave floor cannot be shortcut through outside space',(){
    final s=WalkableSurface(floors:[[const Offset(0,0),const Offset(100,0),
      const Offset(100,20),const Offset(20,20),const Offset(20,100),const Offset(0,100)]]);
    expect(s.visible(const Offset(10,90),const Offset(90,10)),false);
    expect(s.route(const Offset(10,90),const Offset(90,10)),isNotNull);
  });
  test('full-height obstacle cannot be bypassed on its boundary',(){
    final s=WalkableSurface(floors:[rect(0,0,100,100)],
      obstacles:[rect(40,0,60,100)]);
    expect(s.route(const Offset(10,50),const Offset(90,50)),isNull);
  });
  test('same point is a zero-length trip',(){
    final s=WalkableSurface(floors:[rect(0,0,10,10)]);
    expect(s.route(const Offset(5,5),const Offset(5,5)),[const Offset(5,5)]);
  });
  test('pins inside obstacles require explicit approach points',(){
    final s=WalkableSurface(floors:[rect(0,0,100,100)],
      obstacles:[rect(40,20,60,80)]);
    expect(s.route(const Offset(10,50),const Offset(50,50)),isNull);
  });
}
