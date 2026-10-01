import 'package:flutter/material.dart';

/// 출처: 02 레이아웃.
abstract final class AppRadius {
  static const none = 0.0; // 선·표·입력 밑줄.
  static const thumbnail = 16.0; // 지도 썸네일·입력 박스.
  static const card = 24.0; // 지도·햇반 카드.
  static const sheet = 28.0; // 데이터 카드·바텀 시트·시작 슬래브.
  static const pill = 999.0; // 버튼·세그먼트·칩·지도 버튼.
  static const thumbnailBorder = BorderRadius.all(Radius.circular(thumbnail));
  static const cardBorder = BorderRadius.all(Radius.circular(card));
  static const sheetBorder = BorderRadius.all(Radius.circular(sheet));
  static const pillBorder = BorderRadius.all(Radius.circular(pill));
}
