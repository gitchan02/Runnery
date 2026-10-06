import 'package:flutter/material.dart';

import 'app_start.dart';
import 'design_system/app_theme.dart';
import 'record/list/detail/record_detail_page.dart';

void main() {
  RecordRouteMap.basemapEnabled = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '러너리',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const AppStartPage(),
  );
}
