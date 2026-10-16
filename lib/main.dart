import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_start.dart';
import 'design_system/app_theme.dart';
import 'firebase_options.dart';
import 'record/list/detail/record_detail_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 서버에 연결하지 못해도 앱은 켜지도록, 실패는 로그만 남깁니다.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase 초기화 실패: $e');
  }
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
