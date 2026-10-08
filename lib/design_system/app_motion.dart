import 'package:flutter/animation.dart';

/// 출처: 14 사용자 흐름, 05 현재 위치.
abstract final class AppMotion {
  /// 시작 화면: 선 → 로고 → 속도선 → 하단 정보 순서로 나타나는 시간.
  static const splashIntro = Duration(milliseconds: 1300);
  static const splashDelay = Duration(milliseconds: 3000);
  static const splashTransition = Duration(milliseconds: 400);
  static const splashScale = 1.04;
  static const startSheet = Duration(milliseconds: 300);
  static const countdownTransition = Duration(milliseconds: 200);
  static const countdown = Duration(seconds: 3);
  static const runningTransition = Duration(milliseconds: 400);
  static const pauseTransition = Duration(milliseconds: 250);
  static const endConfirmation = Duration(milliseconds: 300);
  static const resultPush = Duration(milliseconds: 350);

  /// 하단 탭 이동: 오른쪽 탭으로 가면 오른쪽에서, 왼쪽 탭으로 가면 왼쪽에서 들어옵니다.
  static const tabSlide = Duration(milliseconds: 300);
  static const homeDissolve = Duration(milliseconds: 250);
  static const detailPush = Duration(milliseconds: 320);
  static const mapExpand = Duration(milliseconds: 300);
  static const logoutDissolve = Duration(milliseconds: 250);
  static const locationPulseInterval = Duration(milliseconds: 2200);
  static const pushSlideCurve = Cubic(0.2, 0, 0, 1);
  // Smart Animate의 'ease-out'은 정확한 제어점이 없어 Flutter 곡선으로 치환하지 않음.
}
