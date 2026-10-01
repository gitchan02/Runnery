import 'package:flutter/material.dart';

/// 출처: 03 컬러. 별도 라이트 모드 팔레트는 제공되지 않았습니다.
abstract final class AppColors {
  static const primary = Color(0xFFFF7A00); // #FF7A00: 러닝 행동·경로·현재 위치.
  static const primaryPressed = Color(0xFFE06B00); // #E06B00: 주황 버튼 눌림.
  static const primarySoft = Color.fromRGBO(
    255,
    122,
    0,
    0.16,
  ); // rgba(255,122,0,.16): GPS 오차·방향.
  static const background = Color(0xFF0B0B0B); // #0B0B0B: 앱 배경.
  static const surface = Color(0xFF111111); // #111111: 노드·보조 면.
  static const card = Color(0xFF151515); // #151515: 햇반 카드·종료 확인 시트.
  static const surfacePressed = Color(0xFF1B1D20); // #1B1D20: 목록 눌림.
  static const divider = Color(0xFF22272C); // #22272C: 목록·표 구분선.
  static const borderDefault = Color(0xFF3A434C); // #3A434C: 섹션 선·테두리 버튼.
  static const borderControl = Color(0xFF5C6771); // #5C6771: 입력 밑줄·아바타.
  static const textPrimary = Color(0xFFFFFFFF); // #FFFFFF: 숫자·제목·주요 버튼 배경.
  static const textSecondary = Color(0xFFA0A0A0); // #A0A0A0: 라벨·설명·단위.
  static const textTertiary = Color(0xFF7D8791); // #7D8791: 캡션·비활성 탭·지명.
  static const error = Color(0xFFFF5A4F); // #FF5A4F: 입력 오류에만 사용.
  static const mapLand = Color(0xFF1D2331); // #1D2331: 지도 바탕.
  static const mapBuilding = Color(0xFF28303F); // #28303F: 건물.
  static const mapPark = Color(0xFF1C4A31); // #1C4A31: 공원.
  static const mapWater = Color(0xFF153A5C); // #153A5C: 강·하천.
  static const mapRoad = Color(0xFF4A5467); // #4A5467: 도로 기본 토큰.
  static const mapRoadLight = Color(0xFF5C6882); // #5C6882: 지도 예시 도로 밝은 끝값.
  static const mapRoadDark = Color(0xFF2F3746); // #2F3746: 지도 예시 도로 어두운 끝값.
  static const mapButtonBase = Color(
    0xFF0E0F11,
  ); // #0E0F11: 지도 버튼 바탕, opacity 별도.
  static const mapButtonOpacity = 0.94; // 지도 버튼 바탕 94%.
  static const mapButtonBorder = Color(0xFF2C3238); // #2C3238: 지도 버튼 테두리.
}
