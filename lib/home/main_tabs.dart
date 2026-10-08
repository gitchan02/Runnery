import 'package:flutter/material.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_motion.dart';
import '../profile/profile_main_page.dart';
import '../record/list/record_list_page.dart';
import 'home_page.dart';

/// 홈·기록·내 정보 세 탭을 한 번만 만들어 두고 옆으로 밀어서 바꿉니다.
/// 탭을 누를 때마다 화면(기록 읽기·지도)을 새로 만들지 않아 끊기지 않습니다.
class MainTabs extends StatefulWidget {
  const MainTabs({super.key, this.initialIndex = 0});

  /// 0 홈, 1 기록, 2 내 정보.
  final int initialIndex;

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    ('홈', Icons.home_outlined),
    ('기록', Icons.format_align_left),
    ('내 정보', Icons.person_outline),
  ];

  late int _index = widget.initialIndex;
  int? _from;

  /// 처음 연 탭만 만듭니다. 한 번 만든 탭은 다른 탭으로 가도 그대로 둡니다.
  late final Set<int> _opened = {_index};
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: AppMotion.tabSlide,
    value: 1,
  );

  late final List<Widget> _pages = [
    HomePageV2(
      showNavigation: false,
      onRecords: () => _go(1),
      onProfile: () => _go(2),
    ),
    RecordListPageV2(
      showNavigation: false,
      onHome: () => _go(0),
      onProfile: () => _go(2),
    ),
    ProfileMainPage(
      showNavigation: false,
      onHome: () => _go(0),
      onRecords: () => _go(1),
    ),
  ];

  void _go(int index) {
    if (index == _index) return;
    setState(() {
      _from = _index;
      _index = index;
      _opened.add(index);
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _slide.value = 1;
    } else {
      _slide.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  Widget _page(int i) {
    final moving = _slide.isAnimating && _from != null;
    final visible = i == _index || (moving && i == _from);
    // 오른쪽 탭으로 가면 새 화면이 오른쪽에서 들어오고, 이전 화면은 왼쪽으로 나갑니다.
    final direction = _from == null ? 0 : (_index > _from! ? 1 : -1);
    final t = AppMotion.pushSlideCurve.transform(_slide.value);
    final dx = !moving
        ? 0.0
        : i == _index
        ? direction * (1 - t)
        : -direction * t;
    return KeyedSubtree(
      key: ValueKey(i),
      child: Offstage(
        offstage: !visible,
        child: TickerMode(
          enabled: visible,
          child: FractionalTranslation(
            translation: Offset(dx, 0),
            child: _pages[i],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    bottomNavigationBar: _TabBar(index: _index, onTap: _go),
    body: ClipRect(
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, _) => Stack(
          children: [for (final i in _opened.toList()..sort()) _page(i)],
        ),
      ),
    ),
  );
}

/// 탭 묶음의 하단 탭. 각 화면이 그리던 탭과 같은 모양입니다.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            for (final (i, (label, icon)) in _MainTabsState._tabs.indexed)
              Expanded(
                child: Semantics(
                  selected: i == index,
                  button: true,
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      children: [
                        Container(
                          height: 2,
                          width: 28,
                          color: i == index ? Colors.white : Colors.transparent,
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          icon,
                          size: 22,
                          color: i == index
                              ? Colors.white
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: i == index
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: i == index
                                ? Colors.white
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
