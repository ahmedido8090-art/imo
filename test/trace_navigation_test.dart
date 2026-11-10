import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/trace_navigation.dart';

TraceEdge edge(String id,String from,String to,double seconds,
    {bool reviewed=true,bool stairs=false,bool stepFree=true,double meters=10,
    List<Offset> points=const [Offset(0,0),Offset(1,0)]})=>
  TraceEdge(id,from,to,'test',points,meters:meters,seconds:seconds,
    reviewed:reviewed,stairs:stairs,stepFreeVerified:stepFree);
List<TraceNode> nodes()=>const [
  TraceNode('a','test',Offset.zero),
  TraceNode('b','test',Offset(1,0)),
  TraceNode('c','test',Offset(1,1)),
];
void main() {
  test('chooses lowest time, even if it has greater distance',(){
    final r=TraceRouter(nodes(),[
      edge('slow','a','c',60,meters:2),
      edge('ab','a','b',10,meters:20),edge('bc','b','c',10,meters:20),
    ]).route('a','c');
    expect(r.status,TraceRouteStatus.verified);
    expect(r.edges.map((e)=>e.id),['ab','bc']);
    expect(r.seconds,20);expect(r.meters,40);
  });
  test('preserves parallel edge identity',(){
    final r=TraceRouter(nodes(),[
      edge('stairs','a','b',1,stairs:true),edge('lift','a','b',20),
    ]).route('a','b',stepFree:true);
    expect(r.edges.single.id,'lift');
  });
  test('unreviewed edges require explicit draft opt-in',(){
    final g=TraceRouter(nodes(),[edge('draft','a','b',5,reviewed:false)]);
    expect(g.route('a','b').status,TraceRouteStatus.needsReview);
    expect(g.route('a','b',allowUnreviewed:true).status,TraceRouteStatus.provisional);
  });
  test('strict step-free requires affirmative accessibility review',(){
    final g=TraceRouter(nodes(),[edge('unknown','a','b',5,stepFree:false)]);
    expect(g.route('a','b',stepFree:true).status,TraceRouteStatus.needsReview);
    expect(g.route('a','b',stepFree:true,allowUnreviewed:true).status,
      TraceRouteStatus.provisional);
  });
  test('unknown outline does not become an obstacle',(){
    final barrier=TraceBarrier('test',const [
      Offset(.4,-.1),Offset(.6,-.1),Offset(.6,.1),Offset(.4,.1),
    ]);
    expect(TraceRouter(nodes(),[edge('ab','a','b',1)],barriers:[barrier])
      .route('a','b').status,TraceRouteStatus.verified);
  });
  test('confirmed obstacle checks interior segments, not only endpoints',(){
    final barrier=TraceBarrier('test',const [
      Offset(.4,-.1),Offset(.6,-.1),Offset(.6,.1),Offset(.4,.1),
    ],confirmed:true);
    expect(TraceRouter(nodes(),[edge('ab','a','b',1)],barriers:[barrier])
      .route('a','b').status,TraceRouteStatus.needsReview);
    expect(barrier.blocks(const Offset(0,.1),const Offset(1,.1)),isFalse);
  });
  test('a bent polyline can avoid a confirmed obstacle',(){
    final barrier=TraceBarrier('test',const [
      Offset(.4,-.1),Offset(.6,-.1),Offset(.6,.1),Offset(.4,.1),
    ],confirmed:true);
    final r=TraceRouter(nodes(),[
      edge('detour','a','b',10,points:const [
        Offset.zero,Offset(0,1),Offset(1,1),Offset(1,0),
      ]),
    ],barriers:[barrier]).route('a','b');
    expect(r.edges.single.id,'detour');
  });
  test('normalizes redirects, rejects unknown IDs and allows zero trip',(){
    final g=TraceRouter(nodes(),[],redirects:{'alias':'a'});
    expect(g.route('alias','a').seconds,0);
    expect(g.route('missing','a').status,TraceRouteStatus.unknownPlace);
  });
  test('portal followed by walking retains exact edge sequence',(){
    final g=TraceRouter(const [TraceNode('a','one',Offset.zero),
      TraceNode('b','two',Offset.zero),TraceNode('c','two',Offset(1,0))],[
      TraceEdge('portal','a','b','one',[],meters:2,seconds:2,
        reviewed:true,portal:true),
      TraceEdge('walk','b','c','two',const [Offset.zero,Offset(1,0)],
        meters:10,seconds:8,reviewed:true),
    ]);
    final r=g.route('a','c');
    expect(r.edges.map((e)=>e.id),['portal','walk']);
    expect(r.edges.last.to,'c');expect(r.seconds,10);
  });
  test('museum adapter never labels imported connections as reviewed',(){
    final g=buildMuseumTraceRouter();
    expect(g.route('mb_entrance','mb_1').status,TraceRouteStatus.needsReview);
    final r=g.route('mb_entrance','mb_1',allowUnreviewed:true);
    expect(r.status,TraceRouteStatus.provisional);
    expect(r.edges.every((e)=>!e.reviewed),isTrue);
  });
}
