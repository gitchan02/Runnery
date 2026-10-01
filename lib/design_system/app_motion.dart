import 'package:flutter/animation.dart';

/// 출처: 14 사용자 흐름, 05 현재 위치.
abstract final class AppMotion {
  static const splashDelay = Duration(milliseconds: 1900);
  static const splashTransition = Duration(milliseconds: 250);
  static const splashScale = 1.04;
  static const startSheet = Duration(milliseconds: 300);
  static const countdownTransition = Duration(milliseconds: 200);
  static const countdown = Duration(seconds: 3);
  static const runningTransition = Duration(milliseconds: 400);
  static const pauseTransition = Duration(milliseconds: 250);
  static const endConfirmation = Duration(milliseconds: 300);
  static const resultPush = Duration(milliseconds: 350);
  static const homeDissolve = Duration(milliseconds: 250);
  static const detailPush = Duration(milliseconds: 320);
  static const mapExpand = Duration(milliseconds: 300);
  static const logoutDissolve = Duration(milliseconds: 250);
  static const locationPulseInterval = Duration(milliseconds: 2200);
  static const pushSlideCurve = Cubic(0.2, 0, 0, 1);
  // Smart Animate의 'ease-out'은 정확한 제어점이 없어 Flutter 곡선으로 치환하지 않음.
}
