import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/gem_map_data.dart';
import '../data/main_building_surface_draft.dart';
import '../services/walkable_surface.dart';

/// Pure numeric isolate request: no widgets, assets or platform APIs.
List<List<double>>? runSurfacePreview(Map<String,List<double>> request) {
  final a=request['start']!,b=request['end']!;
  final result=buildMainBuildingDraftSurface().route(
    Offset(a[0],a[1]),Offset(b[0],b[1]));
  return result==null?null:[for(final p in result)[p.dx,p.dy]];
}

class SurfaceNavigationScreen extends StatefulWidget {
  const SurfaceNavigationScreen({super.key});
  @override
  State<SurfaceNavigationScreen> createState()=>_SurfaceNavigationScreenState();
}
class _SurfaceNavigationScreenState extends State<SurfaceNavigationScreen> {
  late final WalkableSurface surface=buildMainBuildingDraftSurface();
  Offset? start,end;
  List<Offset> route=[];
  bool pickingStart=true,busy=false,showGeometry=true;
  String message='Tap open floor to set your start, then your destination.';
  void pick(Offset p) {
    if(busy) return;
    if(!surface.contains(p)) {
      setState(()=>message='Not walkable in this draft. Tap the walkway outside the room, not a room pin.');
      return;
    }
    setState(() {
      route=[];
      if(pickingStart) { start=p;pickingStart=false;message='Start set. Now tap the destination walkway.'; }
      else { end=p;message='Destination set. Press Route.'; }
    });
  }
  Future<void> calculate() async {
    final a=start,b=end;
    if(busy||a==null||b==null) return;
    setState(() {busy=true;route=[];message='Calculating with the new walking engine...';});
    try {
      final points=await compute(runSurfacePreview,
        <String,List<double>>{'start':[a.dx,a.dy],'end':[b.dx,b.dy]});
      if(!mounted) return;
      setState(() {
        busy=false;
        route=points==null?[]:[for(final p in points)Offset(p[0],p[1])];
        message=points==null
          ?'No route in the draft geometry. This does not prove a real passage is blocked.'
          :'New engine: ${route.length>1?route.length-1:0} walking segments. No legacy-router fallback.';
      });
    } catch(error) {
      if(mounted) setState(() {busy=false;message='Preview calculation failed: $error';});
    }
  }
  void example() {
    if(busy) return;
    setState(() {start=const Offset(1280,175);end=const Offset(1385,325);route=[];});
    calculate();
  }
  @override
  Widget build(BuildContext context) {
    final m=mainBuildingMap;
    final dark=Theme.of(context).brightness==Brightness.dark;
    final asset='assets/maps/${dark?'dark':'light'}/${m.asset.split('/').last}';
    return Scaffold(
      appBar:AppBar(title:const Text('New walking engine')),
      body:SafeArea(child:Column(children:[
        const Padding(padding:EdgeInsets.fromLTRB(12,8,12,4),child:Text(
          'Main Building only - experimental. Floor and obstacle shapes are inferred from the visitor PDF. Doors, upper floors and accessibility are not verified. Normal directions are unchanged.',
          key:Key('surface-preview-warning'))),
        Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Wrap(
          spacing:8,runSpacing:4,alignment:WrapAlignment.center,children:[
            ChoiceChip(label:const Text('I am here'),selected:pickingStart,
              onSelected:busy?null:(_)=>setState(()=>pickingStart=true)),
            ChoiceChip(label:const Text('Go here'),selected:!pickingStart,
              onSelected:busy?null:(_)=>setState(()=>pickingStart=false)),
            FilledButton(onPressed:busy||start==null||end==null?null:calculate,
              child:const Text('Route')),
            OutlinedButton(onPressed:busy?null:example,child:const Text('Example')),
            TextButton(onPressed:busy?null:()=>setState(() {
              start=null;end=null;route=[];pickingStart=true;
              message='Tap open floor to set your start, then your destination.';
            }),child:const Text('Clear')),
            FilterChip(label:const Text('Show obstacles'),selected:showGeometry,
              onSelected:(v)=>setState(()=>showGeometry=v)),
          ])),
        if(busy) const LinearProgressIndicator(),
        Padding(padding:const EdgeInsets.all(8),child:Text(message,
          key:const Key('surface-preview-status'),textAlign:TextAlign.center)),
        Expanded(child:InteractiveViewer(minScale:.5,maxScale:10,
          child:Center(child:AspectRatio(aspectRatio:m.aspectRatio,
            child:LayoutBuilder(builder:(context,box)=>ClipRect(child:GestureDetector(
              behavior:HitTestBehavior.opaque,
              onTapUp:(details)=>pick(Offset(
                details.localPosition.dx/box.maxWidth*m.imageSize.width,
                details.localPosition.dy/box.maxHeight*m.imageSize.height)),
              child:Stack(fit:StackFit.expand,children:[
                SvgPicture.asset(asset,fit:BoxFit.fill),
                IgnorePointer(child:CustomPaint(painter:_SurfacePainter(
                  surface,route,start,end,showGeometry,m.imageSize))),
              ]),
            ))),
          )))),
        const Padding(padding:EdgeInsets.all(8),child:Text(
          'Blue = start, green = destination, orange = draft obstacles. Pinch to zoom. Route planning stays in map coordinates.')),
      ])),
    );
  }
}
class _SurfacePainter extends CustomPainter {
  _SurfacePainter(this.surface,this.route,this.start,this.end,this.overlay,this.mapSize);
  final WalkableSurface surface;
  final List<Offset> route;
  final Offset? start,end;
  final bool overlay;
  final Size mapSize;
  @override
  void paint(Canvas canvas,Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero&size);
    canvas.scale(size.width/mapSize.width,size.height/mapSize.height);
    final width=mapSize.width/size.width;
    Path polygon(List<Offset> points) {
      final p=Path();
      for(var i=0;i<points.length;i++) {
        if(i==0) {p.moveTo(points[i].dx,points[i].dy);}
        else {p.lineTo(points[i].dx,points[i].dy);}
      }
      return p..close();
    }
    if(overlay) {
      for(final f in surface.floors) {canvas.drawPath(polygon(f),Paint()..color=const Color(0x1832a852));}
      for(final o in surface.obstacles) {
        final p=polygon(o);
        canvas.drawPath(p,Paint()..color=const Color(0x55f57c00));
        canvas.drawPath(p,Paint()..color=Colors.deepOrange..style=PaintingStyle.stroke..strokeWidth=width);
      }
    }
    if(route.isNotEmpty) {
      final p=Path()..moveTo(route.first.dx,route.first.dy);
      for(final q in route.skip(1)) {p.lineTo(q.dx,q.dy);}
      canvas.drawPath(p,Paint()..color=Colors.white..style=PaintingStyle.stroke
        ..strokeWidth=7*width..strokeJoin=StrokeJoin.round..strokeCap=StrokeCap.round);
      canvas.drawPath(p,Paint()..color=Colors.teal..style=PaintingStyle.stroke
        ..strokeWidth=4*width..strokeJoin=StrokeJoin.round..strokeCap=StrokeCap.round);
    }
    for(final entry in [(start,Colors.blue),(end,Colors.green)]) {
      final p=entry.$1;
      if(p!=null) {
        canvas.drawCircle(p,8*width,Paint()..color=Colors.white);
        canvas.drawCircle(p,6*width,Paint()..color=entry.$2);
      }
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _SurfacePainter old)=>old.route!=route||
    old.start!=start||old.end!=end||old.overlay!=overlay||old.mapSize!=mapSize;
}
