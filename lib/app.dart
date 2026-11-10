import 'package:flutter/material.dart';
import 'screens/museum_map_screen.dart';
import 'screens/trace_navigation_screen.dart';
import 'screens/surface_navigation_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

class GemNavigatorApp extends StatelessWidget {
  const GemNavigatorApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.instance,
    builder: (context, _) => MaterialApp(
      title: 'GEM Navigator', debugShowCheckedModeBanner: false,
      theme: GemTheme.light, darkTheme: GemTheme.dark,
      themeMode: AppState.instance.themeMode,
      builder: (context, child) => Directionality(
        textDirection: AppState.instance.isArabic?TextDirection.rtl:TextDirection.ltr,
        child: child!,
      ),
      routes: {
        '/trace-navigation':(_)=>const TraceNavigationScreen(),
        '/surface-navigation':(_)=>const SurfaceNavigationScreen(),
      },
      home: const _MapWithTraceEntry(),
    ),
  );
}
class _MapWithTraceEntry extends StatelessWidget {
  const _MapWithTraceEntry();
  @override
  Widget build(BuildContext context)=>Stack(fit:StackFit.expand,children:[
    const MuseumMapScreen(),
    Positioned(right:12,bottom:246,child:SafeArea(
      child:FloatingActionButton.extended(
        heroTag:'surface_navigation_entry',
        tooltip:'Test the new walking engine',
        onPressed:()=>Navigator.of(context).pushNamed('/surface-navigation'),
        icon:const Icon(Icons.directions_walk),
        label:const Text('New router (test)'),
      ),
    )),
    Positioned(right:12,bottom:190,child:SafeArea(
      child:FloatingActionButton.small(
        heroTag:'trace_navigation_entry',
        tooltip:AppState.instance.isArabic?'مراجعة المسارات':'Trace navigation review',
        onPressed:()=>Navigator.of(context).pushNamed('/trace-navigation'),
        child:const Icon(Icons.route),
      ),
    )),
  ]);
}
