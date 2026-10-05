import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_motion.dart';
import '../design_system/app_text_styles.dart';
import '../profile/profile_mail_page.dart';
import '../record/list/record_list_page.dart';
import 'running/running_home_page.dart';

/// 로그인 후 홈. 기본 수치와 경로는 디자인 시안의 예시 데이터입니다.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onStartRun, this.onRecords, this.onProfile});

  final VoidCallback? onStartRun;
  final VoidCallback? onRecords;
  final VoidCallback? onProfile;

  void _open(BuildContext context, VoidCallback? action, String label) {
    if (action != null) {
      action();
    } else if (label == '내 정보') {
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => ProfileMailPage(onRecords: onRecords),
        ),
      );
    } else if (label == '기록') {
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => const RecordListPage()),
      );
    } else if (label == '러닝') {
      // 홈→러닝 시작: 아래에서 올라오기 300ms.
      Navigator.of(context).push<void>(
        PageRouteBuilder(
          transitionDuration: AppMotion.startSheet,
          reverseTransitionDuration: AppMotion.startSheet,
          pageBuilder: (_, _, _) => const RunningHomePage(),
          transitionsBuilder: (_, animation, _, child) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.pushSlideCurve,
                  ),
                ),
            child: child,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$label 화면은 준비 중이에요')));
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: AppColors.background,
    ),
    child: Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _navigation(context),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const CustomPaint(
                        size: Size(24, 24),
                        painter: _LogoPainter(),
                      ),
                      const SizedBox(width: 9),
                      const Text(
                        '러너리',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () => _open(context, onProfile, '내 정보'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: AppColors.borderControl,
                            ),
                            shape: const CircleBorder(),
                          ),
                          child: const Text(
                            '민',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Row(
                    children: [
                      Text(
                        '오늘의 러닝',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Divider(color: AppColors.borderDefault)),
                      SizedBox(width: 12),
                      Text(
                        '9월 28일 월요일',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _RunSummary(),
                  const SizedBox(height: 14),
                  // 지도는 남은 높이를 사용해 버튼까지 한 화면에 표시합니다.
                  Expanded(
                    child: _RouteCard(
                      onTap: () => _open(context, onRecords, '기록'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    hint: '예시 GPS 상태',
                    child: Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(30),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _open(context, onStartRun, '러닝'),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '러닝 시작',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.signal_cellular_alt,
                                          color: Colors.black,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            'GPS 신호 양호 · 바로 시작할 수 있어요',
                                            style: TextStyle(
                                              color: Colors.black.withValues(
                                                alpha: .85,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              const CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.background,
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  size: 28,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _navigation(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _NavItem(
              label: '홈',
              icon: Icons.home_outlined,
              selected: true,
              onTap: () {},
            ),
            _NavItem(
              label: '기록',
              icon: Icons.format_align_left,
              onTap: () => _open(context, onRecords, '기록'),
            ),
            _NavItem(
              label: '내 정보',
              icon: Icons.person_outline,
              onTap: () => _open(context, onProfile, '내 정보'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RunSummary extends StatelessWidget {
  const _RunSummary();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        flex: 3,
        child: Padding(
          padding: const EdgeInsets.only(right: 18),
          child: FittedBox(
            alignment: Alignment.bottomLeft,
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '5.24',
                    style: AppTextStyles.statHero.copyWith(
                      fontSize: 88,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -4,
                    ),
                  ),
                  const TextSpan(
                    text: ' km',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      Expanded(
        flex: 2,
        child: Container(
          padding: const EdgeInsets.only(left: 16),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '운동 시간',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              FittedBox(
                child: _value('32', '분 ', second: '15', lastUnit: '초'),
              ),
              const SizedBox(height: 8),
              const Text(
                '소모 칼로리',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              FittedBox(child: _value('315', 'kcal')),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _value(
    String number,
    String unit, {
    String? second,
    String? lastUnit,
  }) => Text.rich(
    TextSpan(
      style: AppTextStyles.statValue.copyWith(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w800,
      ),
      children: [
        TextSpan(text: number),
        TextSpan(
          text: unit,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        if (second != null) TextSpan(text: second),
        if (lastUnit != null)
          TextSpan(
            text: lastUnit,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    ),
  );
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '최근 러닝 경로 예시, 여의나루역에서 여의도공원',
    button: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _RouteMapPainter()),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [.65, 1],
                colors: [Colors.transparent, Color(0xEE0B0B0B)],
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.mapButtonBase.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.route, size: 14),
                  SizedBox(width: 6),
                  Text(
                    '최근 러닝 경로',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '여의나루역 → 여의도공원',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '기록 보기',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(onTap: onTap),
          ),
        ],
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 2,
              width: 28,
              color: selected ? Colors.white : Colors.transparent,
            ),
            const SizedBox(height: 8),
            Icon(
              icon,
              size: 22,
              color: selected ? Colors.white : AppColors.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? Colors.white : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(4, 19)
      ..lineTo(10, 16)
      ..lineTo(14, 8)
      ..lineTo(21, 5);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    for (final p in [const Offset(4, 19), const Offset(21, 5)]) {
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);
      canvas.drawCircle(p, 1.3, Paint()..color = AppColors.background);
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => false;
}

/// 네트워크 지도 대신 시안의 한강과 러닝 코스를 그리는 정적 미리보기.
class _RouteMapPainter extends CustomPainter {
  const _RouteMapPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 342, size.height / 348);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 342, 348),
      Paint()..color = AppColors.mapLand,
    );
    canvas.save();
    canvas.rotate(-.09);
    for (var y = 130.0; y < 390; y += 23) {
      for (var x = -30.0; x < 380; x += 18) {
        canvas.drawRect(
          Rect.fromLTWH(x + 3, y + 3, 10, 13),
          Paint()..color = AppColors.mapBuilding,
        );
      }
      canvas.drawLine(
        Offset(-30, y),
        Offset(380, y),
        Paint()
          ..color = AppColors.mapRoadDark
          ..strokeWidth = 4,
      );
    }
    for (var x = 0.0; x < 380; x += 69) {
      canvas.drawLine(
        Offset(x, 120),
        Offset(x, 390),
        Paint()
          ..color = AppColors.mapRoad
          ..strokeWidth = 5,
      );
    }
    canvas.restore();
    final river = Path()
      ..moveTo(0, 12)
      ..lineTo(342, 0)
      ..lineTo(342, 117)
      ..cubicTo(317, 120, 324, 176, 266, 210)
      ..cubicTo(192, 260, 66, 255, 0, 235)
      ..lineTo(0, 207)
      ..cubicTo(100, 230, 244, 244, 291, 163)
      ..lineTo(301, 119)
      ..lineTo(0, 141)
      ..close();
    canvas.drawPath(
      river,
      Paint()
        ..color = AppColors.mapPark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25,
    );
    canvas.drawPath(river, Paint()..color = AppColors.mapWater);
    void road(Path path, double width) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF111923)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width + 4,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.mapRoad
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      );
    }

    road(
      Path()
        ..moveTo(-10, 150)
        ..lineTo(300, 128),
      5,
    );
    road(
      Path()
        ..moveTo(101, 8)
        ..lineTo(80, 258),
      5,
    );
    road(
      Path()
        ..moveTo(252, 8)
        ..lineTo(245, 112),
      5,
    );
    road(
      Path()
        ..moveTo(0, 270)
        ..cubicTo(186, 278, 294, 249, 337, 137),
      7,
    );
    final rail = Path()
      ..moveTo(118, 0)
      ..lineTo(157, 143)
      ..cubicTo(153, 183, 51, 165, 35, 191)
      ..lineTo(0, 321);
    canvas.drawPath(
      rail,
      Paint()
        ..color = const Color(0xFF8875C7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 178)
        ..cubicTo(125, 173, 126, 224, 342, 257),
      Paint()
        ..color = const Color(0xFFA58D4D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    final route = Path()
      ..moveTo(34, 208)
      ..lineTo(78, 201)
      ..quadraticBezierTo(88, 199, 87, 211)
      ..lineTo(85, 227)
      ..quadraticBezierTo(196, 237, 272, 181)
      ..quadraticBezierTo(294, 161, 307, 121)
      ..quadraticBezierTo(240, 117, 168, 127)
      ..quadraticBezierTo(153, 128, 156, 150);
    for (final style in [
      (10.0, const Color(0xFF102D22)),
      (6.0, const Color(0xFFAC4F00)),
      (3.0, AppColors.primary),
    ]) {
      canvas.drawPath(
        route,
        Paint()
          ..color = style.$2
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.$1
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
    void label(String text, Offset offset, Color color, double fontSize) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, offset);
    }

    label('한  강', const Offset(142, 55), const Color(0xFF7DABD0), 17);
    label('원효대교', const Offset(257, 52), AppColors.textSecondary, 10);
    label('올림픽대로', const Offset(32, 262), AppColors.textSecondary, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(139, 255, 15, 16),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF429B61),
    );
    label('♣', const Offset(142, 255), Colors.white, 12);
    label('샛강생태공원', const Offset(158, 256), const Color(0xFFC9D0D6), 10);
    for (final marker in [const Offset(34, 208), const Offset(156, 150)]) {
      canvas.drawCircle(marker, 8, Paint()..color = AppColors.background);
      canvas.drawCircle(marker, 6.5, Paint()..color = Colors.white);
    }
    canvas.drawRect(
      const Rect.fromLTWH(31.5, 205.5, 5, 5),
      Paint()..color = AppColors.background,
    );
    canvas.drawPath(
      Path()
        ..moveTo(154, 146)
        ..lineTo(159, 150)
        ..lineTo(154, 154)
        ..close(),
      Paint()..color = AppColors.background,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) => false;
}
