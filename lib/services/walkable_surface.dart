import 'dart:math' as math;
import 'dart:ui';

/// One floor in plan-space pixels. Camera projection never affects routing.
/// Used by the experimental preview, not yet by production MuseumGraph.
class WalkableSurface {
  WalkableSurface({required this.floors, this.obstacles = const []});
  final List<List<Offset>> floors;
  final List<List<Offset>> obstacles;
  static const double epsilon = 1e-8;
  double _cross(Offset a, Offset b) => a.dx*b.dy-a.dy*b.dx;
  bool _inside(Offset p, List<Offset> polygon) {
    var result=false;
    for(var i=0,j=polygon.length-1;i<polygon.length;j=i++) {
      final a=polygon[j],b=polygon[i],v=b-a;
      if(_cross(p-a,v).abs() <= epsilon*math.max(1.0,v.distance) &&
        (p-a).dx*(p-b).dx+(p-a).dy*(p-b).dy <= epsilon) return true;
      if((a.dy>p.dy)!=(b.dy>p.dy) &&
        p.dx<(b.dx-a.dx)*(p.dy-a.dy)/(b.dy-a.dy)+a.dx) result=!result;
    }
    return result;
  }
  bool contains(Offset p) => floors.any((f)=>_inside(p,f)) &&
    !obstacles.any((o)=>_inside(p,o));
  Iterable<(Offset,Offset)> _sides(List<Offset> p) sync* {
    for(var i=0;i<p.length;i++) { yield (p[i],p[(i+1)%p.length]); }
  }
  bool visible(Offset a, Offset b) {
    if(!contains(a)||!contains(b)) return false;
    final d=b-a;
    if(d.distanceSquared < epsilon*epsilon) return true;
    final cuts=<double>[0,1];
    for(final side in [...floors.expand(_sides),...obstacles.expand(_sides)]) {
      final c=side.$1,e=side.$2-c,den=_cross(d,e);
      if(den.abs()<epsilon) {
        if(_cross(c-a,d).abs()<epsilon) {
          for(final p in [c,side.$2]) {
            final t=((p-a).dx*d.dx+(p-a).dy*d.dy)/d.distanceSquared;
            if(t>0&&t<1) cuts.add(t);
          }
        }
      } else {
        final t=_cross(c-a,e)/den,u=_cross(c-a,d)/den;
        if(t>=0&&t<=1&&u>=0&&u<=1) cuts.add(t);
      }
    }
    cuts.sort();
    for(final t in cuts) { if(!contains(a+d*t)) return false; }
    for(var i=1;i<cuts.length;i++) {
      if(!contains(a+d*((cuts[i]+cuts[i-1])/2))) return false;
    }
    return true;
  }
  /// Keep one corner candidate per connected free angular sector instead of
  /// all 16 samples. This avoids thousands of redundant visibility vertices.
  /// The 0.001-pixel offset is numerical, NOT physical/accessibility clearance.
  Iterable<Offset> _cornerCandidates() sync* {
    for(final p in obstacles.expand((p)=>p)) {
      final samples=[for(var k=0;k<16;k++)
        p+Offset(math.cos(k*math.pi/8),math.sin(k*math.pi/8))*0.001];
      final free=samples.map(contains).toList();
      for(var k=0;k<16;k++) {
        if(!free[k]||free[(k+15)%16]) continue;
        var length=1;
        while(length<16&&free[(k+length)%16]) { length++; }
        yield samples[(k+(length-1)~/2)%16];
      }
    }
  }
  /// A* over the candidate visibility graph, not a car-lane network.
  /// This is a near-corner approximation, not a surveyed shortest-path proof.
  List<Offset>? route(Offset start, Offset goal) {
    if(!contains(start)||!contains(goal)) return null;
    if(start==goal) return [start];
    if(visible(start,goal)) return [start,goal];
    final vertices=<Offset>{start,goal,...floors.expand((p)=>p),
      ..._cornerCandidates()}.where(contains).toList();
    final s=vertices.indexOf(start),g=vertices.indexOf(goal);
    final distances=<int,double>{s:0},previous=<int,int>{};
    final open=<int>{s},closed=<int>{};
    while(open.isNotEmpty) {
      final at=open.reduce((a,b)=>
        distances[a]!+(vertices[a]-goal).distance <=
        distances[b]!+(vertices[b]-goal).distance ? a:b);
      open.remove(at);
      if(at==g) {
        final path=<Offset>[goal];var k=g;
        while(k!=s) { k=previous[k]!;path.add(vertices[k]); }
        return path.reversed.toList();
      }
      closed.add(at);
      for(var next=0;next<vertices.length;next++) {
        if(closed.contains(next)||next==at) continue;
        final cost=distances[at]!+(vertices[next]-vertices[at]).distance;
        if(cost >= (distances[next]??double.infinity)) continue;
        if(!visible(vertices[at],vertices[next])) continue;
        distances[next]=cost;previous[next]=at;open.add(next);
      }
    }
    return null;
  }
}
