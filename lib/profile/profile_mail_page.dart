import 'package:flutter/material.dart';

import '../account/account_store.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_text_styles.dart';
import '../home/home_page.dart';
import '../login/login.dart';
import '../record/data/running_record_store.dart';
import '../record/models/running_record.dart';
import '../record/list/record_list_page.dart';
import 'setting/profile_setting.dart';

/// 로그인한 계정(AccountStore)과 저장된 러닝 기록(RunningRecordStore)을 보여주는 내 정보.
class ProfileMailPage extends StatefulWidget {
  const ProfileMailPage({
    super.key,
    this.onHome,
    this.onRecords,
    this.onEditProfile,
    this.onLogout,
    this.account,
    this.records,
  });

  /// 기본값은 AccountStore.instance / RunningRecordStore.instance.
  final AccountStore? account;
  final RunningRecordStore? records;
  final VoidCallback? onHome;
  final VoidCallback? onRecords;
  final VoidCallback? onEditProfile;
  final VoidCallback? onLogout;
  @override
  State<ProfileMailPage> createState() => _ProfileMailPageState();
}

class _ProfileMailPageState extends State<ProfileMailPage> {
  final settings = ProfileSettings();
  late final AccountStore _account = widget.account ?? AccountStore.instance;
  late final RunningRecordStore _store =
      widget.records ?? RunningRecordStore.instance;
  List<RunningRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _store.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _store.removeListener(_reload);
    settings.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final loaded = await _store.load();
      if (mounted) setState(() => _records = loaded);
    } catch (_) {
      // 기록을 못 읽으면 누적 기록은 0으로 둡니다.
    }
  }

  Future<void> _logout() async {
    await _account.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute(builder: (_) => LoginPageV2(store: _account)),
      (_) => false,
    );
  }

  void _action(VoidCallback? action, String label) {
    if (action != null) {
      action();
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label 기능은 준비 중이에요')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _tab('홈', Icons.home_outlined, false, () {
                if (widget.onHome != null) {
                  widget.onHome!();
                } else {
                  Navigator.of(context).pushReplacement<void, void>(
                    MaterialPageRoute(builder: (_) => const HomePageV2()),
                  );
                }
              }),
              _tab('기록', Icons.format_align_left, false, () {
                if (widget.onRecords != null) {
                  widget.onRecords!();
                } else {
                  Navigator.of(context).pushReplacement<void, void>(
                    MaterialPageRoute(builder: (_) => const RecordListPageV2()),
                  );
                }
              }),
              _tab('내 정보', Icons.person_outline, true, () {}),
            ],
          ),
        ),
      ),
    ),
    body: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '내 정보',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '설정',
                    icon: const Icon(Icons.tune, size: 20),
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => ProfileSettingPage(
                          settings: settings,
                          onLogout: widget.onLogout ?? _logout,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderControl),
                    ),
                    child: Text(
                      _account.current?.initial ?? '러',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _account.current?.name ?? '러너',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _account.current == null
                              ? ''
                              : '@${_account.current!.id}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _action(widget.onEditProfile, '프로필 수정'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.borderDefault),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      '프로필 수정',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              _heading('나의 러닝 지도', '여의도 주변'),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 230,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const CustomPaint(painter: _RunningMapPainter()),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xEE0B0B0B)],
                            stops: [0.48, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '지금까지 달린 길',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  _value('$_routeCount', ' 개의 경로', size: 28),
                                ],
                              ),
                            ),
                            const Text(
                              '겹쳐 달린 길일수록\n더 밝게 보여요',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _heading('누적 기록'),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _stat(
                        '총 거리',
                        _value(_totalKm.toStringAsFixed(1), ' km'),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: AppColors.divider),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 18),
                        child: _stat(
                          '총 러닝',
                          _value('${_records.length}', ' 회'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _stat(
                        '총 운동 시간',
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${_totalSeconds ~/ 3600}',
                                style: _numberStyle(30),
                              ),
                              const TextSpan(
                                text: ' 시간 ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextSpan(
                                text: '${_totalSeconds ~/ 60 % 60}',
                                style: _numberStyle(30),
                              ),
                              const TextSpan(
                                text: ' 분',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: AppColors.divider),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 18),
                        child: _stat(
                          '소모 햇반',
                          _value(_totalHetbahn.toStringAsFixed(1), ' 개'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _heading('신체 정보', '칼로리 계산에 사용돼요'),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _stat(
                        '체중',
                        _value(
                          _account.current?.weightKg.toStringAsFixed(1) ?? '-',
                          ' kg',
                          size: 24,
                        ),
                        compact: true,
                      ),
                    ),
                    const VerticalDivider(width: 24, color: AppColors.divider),
                    Expanded(
                      child: _stat(
                        '나이',
                        _value(
                          '${_account.current?.age ?? '-'}',
                          ' 세',
                          size: 24,
                        ),
                        compact: true,
                      ),
                    ),
                    const VerticalDivider(width: 24, color: AppColors.divider),
                    Expanded(
                      child: _stat(
                        '성별',
                        Text(
                          _account.current?.gender ?? '-',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.onLogout ?? _logout,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.textSecondary,
                  ),
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('로그아웃'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  int get _routeCount => _records.where((r) => r.route.length >= 2).length;
  double get _totalKm =>
      _records.fold<double>(0, (sum, r) => sum + r.distanceKm);
  int get _totalSeconds =>
      _records.fold<int>(0, (sum, r) => sum + r.movingSeconds);
  double get _totalHetbahn =>
      _records.fold<double>(0, (sum, r) => sum + r.hetbahnCount);

  TextStyle _numberStyle(double size) => AppTextStyles.statValue.copyWith(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.15,
  );
  Widget _value(String value, String unit, {double size = 30}) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: value, style: _numberStyle(size)),
        TextSpan(
          text: unit,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
  Widget _stat(String label, Widget value, {bool compact = false}) => Padding(
    padding: EdgeInsets.symmetric(vertical: compact ? 0 : 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: value,
        ),
      ],
    ),
  );
  Widget _heading(String title, [String? caption]) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Divider(color: AppColors.borderDefault)),
      if (caption != null) ...[
        const SizedBox(width: 12),
        Text(
          caption,
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
      ],
    ],
  );
  Widget _tab(String label, IconData icon, bool selected, VoidCallback onTap) =>
      Expanded(
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
                size: 23,
                color: selected ? Colors.white : AppColors.textTertiary,
              ),
              const SizedBox(height: 3),
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
      );
}

/// API 연결 전 표시하는 벡터 지도 예시.
class _RunningMapPainter extends CustomPainter {
  const _RunningMapPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 342, size.height / 230);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 342, 230),
      Paint()..color = AppColors.mapLand,
    );
    for (var i = 0; i < 12; i++) {
      final x = i * 33.0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - 14, 230),
        Paint()
          ..color = AppColors.mapRoad
          ..strokeWidth = i % 3 == 0 ? 2 : 1,
      );
      canvas.drawLine(
        Offset(0, i * 23.0),
        Offset(342, i * 23.0 + 20),
        Paint()
          ..color = AppColors.mapRoad
          ..strokeWidth = 1,
      );
    }
    for (final r in [
      const Rect.fromLTWH(35, 17, 14, 11),
      const Rect.fromLTWH(270, 22, 13, 13),
      const Rect.fromLTWH(76, 190, 20, 20),
    ]) {
      canvas.drawRect(r, Paint()..color = AppColors.mapPark);
    }
    final river = Path()
      ..moveTo(0, 61)
      ..lineTo(210, 42)
      ..lineTo(342, 49)
      ..lineTo(342, 103)
      ..lineTo(0, 123)
      ..close();
    canvas.drawPath(river, Paint()..color = AppColors.mapWater);
    final bank = Path()
      ..moveTo(26, 116)
      ..cubicTo(106, 192, 267, 207, 306, 104);
    canvas.drawPath(
      bank,
      Paint()
        ..color = AppColors.mapRoadLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    canvas.drawPath(
      bank,
      Paint()
        ..color = AppColors.mapPark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    for (var i = 0; i < 5; i++) {
      final d = i * 2.0;
      final route = Path()
        ..moveTo(56 + d, 118)
        ..lineTo(283 - d, 104 + d)
        ..cubicTo(251, 193 - d, 116, 188 - d, 56 + d, 118);
      canvas.drawPath(
        route,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.25 + i * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final route = Path()
      ..moveTo(98, 114)
      ..lineTo(94, 60)
      ..quadraticBezierTo(93, 55, 103, 54)
      ..lineTo(251, 44)
      ..quadraticBezierTo(259, 43, 256, 54)
      ..lineTo(254, 99)
      ..lineTo(181, 106)
      ..lineTo(185, 51);
    canvas.drawPath(
      route,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final bridge = Path()
      ..moveTo(177, 0)
      ..lineTo(196, 101)
      ..quadraticBezierTo(226, 145, 147, 139)
      ..lineTo(128, 230);
    canvas.drawPath(
      bridge,
      Paint()
        ..color = const Color(0xFF7966AE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (final position in [const Offset(19, 79), const Offset(192, 66)]) {
      final label = TextPainter(
        text: const TextSpan(
          text: '한 강',
          style: TextStyle(
            color: Color(0xFF79A9CB),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, position);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RunningMapPainter oldDelegate) => false;
}
