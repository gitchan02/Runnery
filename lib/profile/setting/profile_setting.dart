import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';

/// 화면을 나갔다 돌아와도 유지되는 세션 설정. 저장소 연결 시 주입합니다.
class ProfileSettings extends ChangeNotifier {
  bool voice = true;
  bool autoPause = true;
  bool markers = true;
  String countdown = '3초';
  String distanceUnit = 'km';
  String gps = '높음';
  String notifications = '켜짐';
  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}

class ProfileSettingPage extends StatelessWidget {
  const ProfileSettingPage({super.key, required this.settings});
  final ProfileSettings settings;

  void _pending(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label 기능은 준비 중이에요')));
  }

  Future<void> _choose(
    BuildContext context,
    String title,
    String current,
    List<String> options,
    ValueChanged<String> onSelected,
  ) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              for (final option in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option),
                  trailing: option == current
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                  onTap: () => Navigator.pop(context, option),
                ),
            ],
          ),
        ),
      ),
    );
    if (value != null) settings.update(() => onSelected(value));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        tooltip: '뒤로',
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        '설정',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
    ),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                _section('러닝'),
                _toggle(
                  '음성 안내',
                  '1 km마다 거리와 페이스를 알려줘요',
                  settings.voice,
                  (v) => settings.update(() => settings.voice = v),
                ),
                _toggle(
                  '자동 일시정지',
                  '멈춰 서면 기록을 잠시 멈춰요',
                  settings.autoPause,
                  (v) => settings.update(() => settings.autoPause = v),
                ),
                _row(
                  '카운트다운',
                  value: settings.countdown,
                  onTap: () => _choose(context, '카운트다운', settings.countdown, [
                    '없음',
                    '3초',
                    '5초',
                    '10초',
                  ], (v) => settings.countdown = v),
                ),
                _row(
                  '거리 단위',
                  value: settings.distanceUnit,
                  divider: false,
                  onTap: () => _choose(
                    context,
                    '거리 단위',
                    settings.distanceUnit,
                    ['km', 'mi'],
                    (v) => settings.distanceUnit = v,
                  ),
                ),
                const SizedBox(height: 26),
                _section('지도'),
                _toggle(
                  '1 km 구간 표시',
                  '지도 경로 위에 1, 2, 3... 마커를 보여줘요',
                  settings.markers,
                  (v) => settings.update(() => settings.markers = v),
                ),
                _row(
                  'GPS 정확도',
                  subtitle: '높을수록 배터리를 더 사용해요',
                  value: settings.gps,
                  divider: false,
                  onTap: () => _choose(context, 'GPS 정확도', settings.gps, [
                    '높음',
                    '보통',
                    '낮음',
                  ], (v) => settings.gps = v),
                ),
                const SizedBox(height: 26),
                _section('계정'),
                _row('개인 정보 수정', onTap: () => _pending(context, '개인 정보 수정')),
                _row('비밀번호 변경', onTap: () => _pending(context, '비밀번호 변경')),
                _row(
                  '알림',
                  value: settings.notifications,
                  divider: false,
                  onTap: () => _choose(context, '알림', settings.notifications, [
                    '켜짐',
                    '꺼짐',
                  ], (v) => settings.notifications = v),
                ),
                const SizedBox(height: 26),
                _section('앱 정보'),
                _row('버전', value: '2.0.0'),
                _row('이용약관', onTap: () => _pending(context, '이용약관')),
                _row(
                  '개인정보 처리방침',
                  divider: false,
                  onTap: () => _pending(context, '개인정보 처리방침'),
                ),
                const SizedBox(height: 28),
                const Divider(color: AppColors.borderDefault, height: 1),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _pending(context, '로그아웃'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('로그아웃'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '|',
                        style: TextStyle(color: AppColors.borderDefault),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pending(context, '회원 탈퇴'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textTertiary,
                      ),
                      child: const Text('회원 탈퇴'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _toggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => _row(
    title,
    subtitle: subtitle,
    trailing: Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: Colors.white,
      activeThumbColor: AppColors.background,
      inactiveTrackColor: AppColors.divider,
      inactiveThumbColor: AppColors.textSecondary,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    onTap: () => onChanged(!value),
  );

  Widget _row(
    String title, {
    String? subtitle,
    String? value,
    Widget? trailing,
    VoidCallback? onTap,
    bool divider = true,
  }) => Container(
    decoration: BoxDecoration(
      border: divider
          ? const Border(bottom: BorderSide(color: AppColors.divider))
          : null,
    ),
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (trailing != null)
                trailing
              else ...[
                if (value != null)
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (onTap != null)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
