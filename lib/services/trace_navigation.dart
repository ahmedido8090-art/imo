import 'dart:ui';
import '../data/gem_map_data.dart';
import '../data/gem_extras.dart';
import '../data/gem_paths.dart';
import '../models/map_models.dart';

enum TraceRouteStatus { verified, provisional, needsReview, unknownPlace }

class TraceNode {
  const TraceNode(this.id, this.mapId, this.point);
  final String id, mapId;
  final Offset point;
}

class TraceEdge {
  TraceEdge(this.id, this.from, this.to, this.mapId, List<Offset> points,
      {required this.meters, required this.seconds, this.stairs = false,
      this.reviewed = false, this.stepFreeVerified = false, this.portal = false})
      : points = List.unmodifiable(points) {
    if (!portal && points.length < 2) {
      throw ArgumentError('A walking edge needs a complete polyline');
    }
    if (!meters.isFinite || meters < 0 || !seconds.isFinite || seconds < 0) {
      throw ArgumentError('Route costs must be finite and nonnegative');
    }
  }
  final String id, from, to, mapId;
  final List<Offset> points;
  final double meters, seconds;
  final bool stairs, reviewed, stepFreeVerified, portal;
  TraceEdge reversed() => TraceEdge(id, to, from, mapId,
      points.reversed.toList(), meters: meters, seconds: seconds,
      stairs: stairs, reviewed: reviewed, stepFreeVerified: stepFreeVerified,
      portal: portal);
}

/// Only explicitly confirmed obstacle footprints affect connectivity.
/// Unknown artwork must not be promoted to a wall automatically.
class TraceBarrier {
  TraceBarrier(this.mapId, List<Offset> points, {this.confirmed = false})
      : points = List.unmodifiable(points) {
    if (points.length < 3) throw ArgumentError('A barrier needs 3 vertices');
  }
  final String mapId;
  final List<Offset> points;
  final bool confirmed;
  static double _cross(Offset a, Offset b) => a.dx*b.dy-a.dy*b.dx;
  bool _inside(Offset p) {
    var result = false;
    for (var i=0,j=points.length-1;i<points.length;j=i++) {
      final a=points[i], b=points[j];
      if ((a.dy>p.dy)!=(b.dy>p.dy) &&
          p.dx<(b.dx-a.dx)*(p.dy-a.dy)/(b.dy-a.dy)+a.dx) {
        result=!result;
      }
    }
    return result;
  }
  bool blocks(Offset a, Offset b) {
    if (!confirmed) return false;
    // Strict interior overlap blocks walking; boundary contact alone does not.
    final delta=b-a;
    if (delta.distanceSquared < 1e-20) return _inside(a);
    final ts=<double>[0,1];
    for (var i=0;i<points.length;i++) {
      final c=points[i], d=points[(i+1)%points.length], side=d-c;
      final denominator=_cross(delta,side);
      if (denominator.abs()<1e-12) continue;
      final t=_cross(c-a,side)/denominator;
      final u=_cross(c-a,delta)/denominator;
      if (t>0 && t<1 && u>=0 && u<=1) ts.add(t);
    }
    ts.sort();
    for (var i=1;i<ts.length;i++) {
      final p=a+delta*((ts[i-1]+ts[i])/2);
      // Exclude a point lying exactly on a polygon boundary.
      var onBoundary=false;
      for (var j=0;j<points.length;j++) {
        final c=points[j], d=points[(j+1)%points.length];
        if (_cross(p-c,d-c).abs()<1e-12 &&
            (p.dx-c.dx)*(p.dx-d.dx)+(p.dy-c.dy)*(p.dy-d.dy)<=1e-12) {
          onBoundary=true; break;
        }
      }
      if (!onBoundary && _inside(p)) return true;
    }
    return false;
  }
}

class TraceRoute {
  TraceRoute(this.status, List<TraceEdge> edges)
      : edges=List.unmodifiable(edges);
  final TraceRouteStatus status;
  final List<TraceEdge> edges;
  double get meters => edges.fold(0.0,(sum,e)=>sum+e.meters);
  double get seconds => edges.fold(0.0,(sum,e)=>sum+e.seconds);
}

class TraceRouter {
  TraceRouter(Iterable<TraceNode> nodes, Iterable<TraceEdge> edges,
      {this.redirects=const {}, List<TraceBarrier> barriers=const []})
      : nodes={for(final n in nodes)n.id:n} {
    for (final edge in edges) {
      if (!this.nodes.containsKey(edge.from) || !this.nodes.containsKey(edge.to)) {
        throw ArgumentError('Unknown route endpoint on ${edge.id}');
      }
      if (!edge.portal && barriers.any((b)=>b.mapId==edge.mapId &&
          List.generate(edge.points.length-1,(i)=>
              b.blocks(edge.points[i],edge.points[i+1])).any((x)=>x))) continue;
      _adj.putIfAbsent(edge.from,()=>[]).add(edge);
    }
  }
  final Map<String,TraceNode> nodes;
  final Map<String,String> redirects;
  final Map<String,List<TraceEdge>> _adj={};
  String normalize(String id) {
    final visited=<String>{};
    while (redirects.containsKey(id) && visited.add(id)) { id=redirects[id]!; }
    return id;
  }
  TraceRoute route(String from,String to,
      {bool stepFree=false,bool allowUnreviewed=false}) {
    from=normalize(from);to=normalize(to);
    if (!nodes.containsKey(from)||!nodes.containsKey(to)) {
      return TraceRoute(TraceRouteStatus.unknownPlace,[]);
    }
    if (from==to) return TraceRoute(TraceRouteStatus.verified,[]);
    final dist=<String,double>{from:0};
    final previous=<String,TraceEdge>{};
    final open=nodes.keys.toSet();
    while(open.isNotEmpty) {
      String? at;var cost=double.infinity;
      for(final id in open) { if((dist[id]??double.infinity)<cost) {
        at=id;cost=dist[id]!;
      }}
      if(at==null||at==to) break;
      open.remove(at);
      for(final e in _adj[at]??const <TraceEdge>[]) {
        if (!open.contains(e.to) || (!allowUnreviewed&&!e.reviewed)) continue;
        if (stepFree&&(e.stairs||(!allowUnreviewed&&!e.stepFreeVerified))) continue;
        final next=cost+e.seconds;
        if(next<(dist[e.to]??double.infinity)) {
          dist[e.to]=next;previous[e.to]=e;
        }
      }
    }
    if(!previous.containsKey(to)) {
      return TraceRoute(TraceRouteStatus.needsReview,[]);
    }
    final reversed=<TraceEdge>[];var at=to;
    while(at!=from) { final e=previous[at]!;reversed.add(e);at=e.from; }
    final path=reversed.reversed.toList();
    final provisional=path.any((e)=>!e.reviewed||(stepFree&&!e.stepFreeVerified));
    return TraceRoute(provisional?TraceRouteStatus.provisional:
        TraceRouteStatus.verified,path);
  }
}

/// Adapter for the repository's EXISTING geometry. These connections have
/// not been physically verified against the semantic review and stay drafts.
TraceRouter buildMuseumTraceRouter() {
  final nodes=<String,TraceNode>{};final edges=<TraceEdge>[];
  for(final m in allMaps.values) {
    for(final p in m.places) { nodes[p.id]=TraceNode(p.id,m.id,p.position); }
    m.junctions.forEach((id,p)=>nodes[id]=TraceNode(id,m.id,p));
  }
  var sequence=0;
  void link(String a,String b,{bool stairs=false,double? meters,bool portal=false,
      bool lift=false}) {
    final na=nodes[a],nb=nodes[b];if(na==null||nb==null)return;
    final m=allMaps[na.mapId]!;
    final key=a.compareTo(b)<0?'$a|$b':'$b|$a';
    final stored=portal?const <Offset>[]:(kEdgePaths[key]??const <Offset>[]);
    final via=a.compareTo(b)<0?stored:stored.reversed.toList();
    final points=<Offset>[na.point,...via,nb.point];
    var length=0.0;
    for(var i=1;i<points.length;i++) {
      final d=points[i]-points[i-1];
      length+=Offset(d.dx*m.imageSize.width,d.dy*m.imageSize.height).distance;
    }
    final distance=meters??length*m.metersPerPixel;
    final e=TraceEdge('trace_${sequence++}',a,b,na.mapId,
        portal?const <Offset>[]:points,meters:distance,
        seconds:distance/(stairs?0.65:1.25)+(lift?40:0),
        stairs:stairs,portal:portal);
    edges.add(e);edges.add(e.reversed());
  }
  for(final m in allMaps.values) {
    for(final e in m.edges) {
      link(e.$1,e.$2,stairs:kStairEdges.contains('${e.$1}|${e.$2}')||
          kStairEdges.contains('${e.$2}|${e.$1}'));
    }
    for(final p in m.places.where((p)=>p.autoConnect)) {
      final floor=kPlaceFloor[p.id];
      // Do not manufacture stairways from upper-floor overview markers.
      if(floor!=null&&floor!=m.level)continue;
      final junction=kPinLinks[p.id];
      if(junction!=null&&m.junctions.containsKey(junction))link(p.id,junction);
      // No unchecked nearest-junction fallback.
    }
  }
  for(final p in kPortals) {
    link(p.a,p.b,stairs:p.kind==PortalKind.stairs,meters:p.meters,
        portal:true,lift:p.kind==PortalKind.lift);
  }
  return TraceRouter(nodes.values,edges,redirects:kRouteRedirects);
}
