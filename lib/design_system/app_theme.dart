import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_component_metrics.dart';
import 'app_text_styles.dart';

/// 정의만 제공하며 기존 앱에는 연결하지 않습니다.
/// ThemeData는 const 생성자가 없어 이 항목만 static final입니다.
/// 확인된 전역 값만 설정. 나머지 Flutter 기본값은 가이드의 확정값이 아닙니다.
/// 버튼 종류별 색·높이·모서리는 달라서 전역 버튼 테마를 임의로 만들지 않습니다.
abstract final class AppTheme {
  static final dark = ThemeData(
    // 화면 전환 애니메이션 없이 바로 넘어갑니다. 모든 플랫폼 공통.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _NoTransitionsBuilder(),
        TargetPlatform.iOS: _NoTransitionsBuilder(),
        TargetPlatform.fuchsia: _NoTransitionsBuilder(),
        TargetPlatform.linux: _NoTransitionsBuilder(),
        TargetPlatform.macOS: _NoTransitionsBuilder(),
        TargetPlatform.windows: _NoTransitionsBuilder(),
      },
    ),
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.card,
    dividerColor: AppColors.divider,
    fontFamily: AppTextStyles.bodyFontFamily,
    iconTheme: const IconThemeData(
      color: AppColors.textPrimary,
      size: AppComponentMetrics.iconSize,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: AppComponentMetrics.dividerWidth,
    ),
  );
}

/// 화면을 효과 없이 그대로 보여 주는 전환.
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
