import 'package:flutter/material.dart';

import 'design_system/app_theme.dart';
import 'home/running/running_home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runnery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RunningHomePage(),
    );
  }
}
