import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/gem_map_data.dart';
import '../models/map_models.dart';
import '../services/trace_navigation.dart';
import '../state/app_state.dart';

class TraceNavigationScreen extends StatefulWidget {
  const TraceNavigationScreen({super.key});
  @override
  State<TraceNavigationScreen> createState()=>_TraceNavigationScreenState();
}
class _TraceNavigationScreenState extends State<TraceNavigationScreen> {
  late final TraceRouter router=buildMuseumTraceRouter();
  late final List<MapPlace> places=[for(final m in allMaps.values)...m.places];
  String mapId='main_building',from='mb_entrance',to='mb_1';
  bool drafts=false,stepFree=false;
  String tr(String en,String ar)=>AppState.instance.isArabic?ar:en;
  @override
  Widget build(BuildContext context) {
    final m=allMaps[mapId]!;
    final route=router.route(from,to,stepFree:stepFree,allowUnreviewed:drafts);
    final dark=Theme.of(context).brightness==Brightness.dark;
    final file=m.asset.split('/').last;
    final asset='assets/maps/${dark?'dark':'light'}/$file';
    final message=switch(route.status) {
      TraceRouteStatus.verified=>tr('Route uses reviewed connections.',
          'المسار يستخدم وصلات تمت مراجعتها.'),
      TraceRouteStatus.provisional=>tr(
          'DRAFT: fastest estimated route on unreviewed existing connections. Not verified against the full trace or for accessibility.',
          'مسودة: أسرع مسار تقديري عبر الوصلات الحالية غير المراجعة. لم يتم التحقق منه مقابل الرسم الكامل أو لإمكانية الوصول.'),
      TraceRouteStatus.needsReview=>tr(
          'No reviewed connection is mapped for this selection. This does NOT mean the real passage is blocked.',
          'لا توجد وصلة مراجعة مرسومة لهذا الاختيار. هذا لا يعني أن الممر الحقيقي مغلق.'),
      TraceRouteStatus.unknownPlace=>tr('Unknown place identifier.','معرف المكان غير معروف.'),
    };
    Widget picker(String label,String value,ValueChanged<String> change)=>
      DropdownButtonFormField<String>(
        key:ValueKey('$label:$value'),initialValue:value,isExpanded:true,
        decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),
        items:[for(final p in places)DropdownMenuItem(value:p.id,
          child:Text('${p.name} (${p.id})',overflow:TextOverflow.ellipsis))],
        onChanged:(v){if(v!=null)setState(()=>change(v));},
      );
    return Scaffold(
      appBar:AppBar(title:Text(tr('Trace navigation — review','مراجعة الملاحة على الخريطة'))),
      body:SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.all(10),child:Column(children:[
          picker(tr("I'm here",'أنا هنا'),from,(v){from=v;mapId=router.nodes[router.normalize(v)]!.mapId;}),
          const SizedBox(height:8),
          picker(tr('Go to','الوجهة'),to,(v){to=v;}),
          Wrap(spacing:12,children:[
            FilterChip(label:Text(tr('Show unreviewed draft routes','إظهار مسارات المسودة')),
              selected:drafts,onSelected:(v)=>setState(()=>drafts=v)),
            FilterChip(label:Text(tr('Exclude stairs','استبعاد السلالم')),
              selected:stepFree,onSelected:(v)=>setState(()=>stepFree=v)),
          ]),
          Text(message,style:TextStyle(color:route.status==TraceRouteStatus.provisional?
              Colors.deepOrange:null)),
          if(route.edges.isNotEmpty)Text(tr(
              '${route.meters.round()} m · ${(route.seconds/60).toStringAsFixed(1)} min — estimated',
              '${route.meters.round()} م · ${(route.seconds/60).toStringAsFixed(1)} دقيقة — تقديري')),
          SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
            for(final map in allMaps.values)Padding(padding:const EdgeInsetsDirectional.only(end:8),
              child:ChoiceChip(label:Text(map.shortTitle),selected:map.id==mapId,
                onSelected:(_)=>setState(()=>mapId=map.id))),
          ])),
        ])),
        Expanded(child:InteractiveViewer(minScale:.5,maxScale:10,
          child:Center(child:AspectRatio(aspectRatio:m.aspectRatio,
            child:LayoutBuilder(builder:(context,box)=>Stack(fit:StackFit.expand,children:[
              SvgPicture.asset(asset,fit:BoxFit.fill),
              IgnorePointer(child:CustomPaint(painter:_TraceRoutePainter(route,mapId))),
              for(final p in m.places)Positioned(
                left:p.position.dx*box.maxWidth-12,top:p.position.dy*box.maxHeight-12,
                child:Tooltip(message:'${p.name} · ${p.id}',
                  child:GestureDetector(onTap:()=>showModalBottomSheet<void>(context:context,
                    builder:(sheet)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),
                      child:Column(mainAxisSize:MainAxisSize.min,children:[
                        Text(p.name,style:Theme.of(context).textTheme.titleLarge),
                        Text('${p.category.label} · ${p.id}'),
                        Text(tr('Marker position, not a verified entrance.',
                            'موضع علامة وليس مدخلاً تم التحقق منه.')),
                        Wrap(spacing:12,children:[
                          TextButton(onPressed:(){setState(()=>from=p.id);Navigator.pop(sheet);},
                            child:Text(tr("I'm here",'أنا هنا'))),
                          TextButton(onPressed:(){setState(()=>to=p.id);Navigator.pop(sheet);},
                            child:Text(tr('Go here','اذهب هنا'))),
                        ]),
                      ])))),child:Container(width:24,height:24,
                    decoration:BoxDecoration(color:p.id==from?Colors.blue:
                        p.id==to?Colors.red:Colors.teal,shape:BoxShape.circle,
                        border:Border.all(color:Colors.white)),
                    child:Icon(_icon(p),size:15,color:Colors.white)))),
              ),
            ])),
          )))),
        Padding(padding:const EdgeInsets.all(8),child:Text(tr(
          'Source SVG details are preserved. No candidate outline is added as a physical wall. Excluding stairs alone does not certify wheelchair access.',
          'تفاصيل SVG الأصلية محفوظة. لا تتم إضافة خطوط غير مؤكدة كجدران حقيقية. استبعاد السلالم وحده لا يضمن ملاءمة الكراسي المتحركة.'),
          style:Theme.of(context).textTheme.bodySmall)),
      ])),
    );
  }
  IconData _icon(MapPlace p)=>switch(p.glyph) {
    PlaceGlyph.restroom=>Icons.wc,
    PlaceGlyph.lift=>Icons.elevator,
    PlaceGlyph.info=>Icons.info_outline,
    PlaceGlyph.wheelchair=>Icons.accessible,
    _=>switch(p.category) {
      PlaceCategory.restaurant=>Icons.restaurant,
      PlaceCategory.shop=>Icons.store,
      PlaceCategory.entrance=>Icons.login,
      _=>Icons.place,
    },
  };
}
class _TraceRoutePainter extends CustomPainter {
  _TraceRoutePainter(this.route,this.mapId);
  final TraceRoute route;
  final String mapId;
  @override
  void paint(Canvas canvas,Size size) {
    final paint=Paint()..color=(route.status==TraceRouteStatus.provisional?
        Colors.deepOrange:Colors.blue)..strokeWidth=3..style=PaintingStyle.stroke;
    for(final e in route.edges.where((e)=>!e.portal&&e.mapId==mapId)) {
      final path=Path();
      for(var i=0;i<e.points.length;i++) {
        final p=e.points[i];
        if(i==0){path.moveTo(p.dx*size.width,p.dy*size.height);}
        else{path.lineTo(p.dx*size.width,p.dy*size.height);}
      }
      canvas.drawPath(path,paint);
    }
  }
  @override
  bool shouldRepaint(covariant _TraceRoutePainter old)=>old.route!=route||old.mapId!=mapId;
}
