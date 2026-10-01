import 'package:flutter/material.dart';

/// 출처: 06 버튼, 지도 위 원형 버튼의 '그림자 0 10 28 / 50%'.
/// 색상·spread가 명시되지 않아 BoxShadow는 만들지 않습니다.
abstract final class AppShadows {
  static const mapButtonOffset = Offset(0, 10);
  static const mapButtonBlurRadius = 28.0;
  static const mapButtonOpacity = 0.5;
}
