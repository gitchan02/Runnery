import 'package:flutter/material.dart';

import 'app_start.dart';
import 'design_system/app_theme.dart';

void main() => runApp(const MyApp());

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
