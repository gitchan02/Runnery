
import 'package:flutter/material.dart';

/// 출처: 02 원칙, 05 로고, 06 컴포넌트. 미명시 속성은 지정하지 않습니다.
/// 폰트 파일·등록은 미포함. width는 fontSize가 아닌 가변 폰트 wdth 축입니다.
abstract final class AppTextStyles {
  static const bodyFontFamily = 'Pretendard';
  static const numberFontFamily = 'Archivo';
  static const numberWidth = FontVariation('wdth', 75);
  static const brandWidth = FontVariation('wdth', 125);
  static const statHero = TextStyle(
    fontFamily: numberFontFamily,
    fontSize: 112,
    fontVariations: [numberWidth],
  );
  static const statHeroUnit = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 22,
  );
  static const statValue = TextStyle(
    fontFamily: numberFontFamily,
    fontSize: 34,
    fontVariations: [numberWidth],
  );
  static const statLabelSmall = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 12,
  );
  static const statLabelLarge = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 13,
  );
  static const inputLabel = TextStyle(fontFamily: bodyFontFamily, fontSize: 13);
  static const inputValue = TextStyle(fontFamily: bodyFontFamily, fontSize: 17);
  static const inputHint = TextStyle(fontFamily: bodyFontFamily, fontSize: 12);
  // 11px × 14% = 1.54px. Flutter letterSpacing은 비율이 아닌 논리 픽셀.
  static const authLabel = TextStyle(
    fontFamily: numberFontFamily,
    fontSize: 11,
    letterSpacing: 1.54,
    fontVariations: [brandWidth],
  );
  static const koreanLogo = TextStyle(
    fontFamily: bodyFontFamily,
    fontWeight: FontWeight.w800,
  ); // ExtraBold. 글자 크기 미제공.
  static const wordmark = TextStyle(
    fontFamily: numberFontFamily,
    fontWeight: FontWeight.w800,
    fontVariations: [brandWidth],
  );
  static const koreanLogoLetterSpacingRatio = -0.04; // 원문 -4%, 크기 확정 후 환산.
  static const wordmarkLetterSpacingRatio = 0.06; // 원문 6%, 크기 확정 후 환산.
  static const compactRunningNumberSize = 56.0;
  static const baseRunningNumberSize = 64.0;
  static const largeRunningNumberSize = 72.0;
  static const androidRunningNumberSize = 60.0;
  static const statLabelToNumberRatio = 1 / 8; // 원칙 페이지. 고정 크기와의 관계 미확정.
}
