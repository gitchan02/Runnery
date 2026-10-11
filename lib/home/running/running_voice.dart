import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 러닝 음성 안내. iOS 기본 한국어 음성으로 읽습니다(ios/Runner/VoiceGuide.swift).
/// 화면이 꺼져 있거나 다른 앱을 쓰는 중에도 들리고, 읽는 동안 음악 소리를 잠깐 줄입니다.
class RunningVoice {
  static const _channel = MethodChannel('runnery/voice');

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  void speak(String text) {
    if (!_supported) return;
    _channel.invokeMethod<void>('speak', text).catchError((_) {});
  }

  /// 6분 12초, 1시간 2분 15초
  static String duration(Duration d) {
    final h = d.inHours, m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return [if (h > 0) '$h시간', if (h > 0 || m > 0) '$m분', '$s초'].join(' ');
  }

  /// 5킬로미터, 5.5킬로미터
  static String km(double km) =>
      '${km == km.roundToDouble() ? km.toInt() : km}킬로미터';
}
