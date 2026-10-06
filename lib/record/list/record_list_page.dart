import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../home/home_page.dart';
import '../../profile/profile_main_page.dart';
import '../record_calendar_page.dart';
import 'detail/record_detail_page.dart';
import '../data/running_record_store.dart';

/// 로컬 러닝 기록을 표시하는 테스트용 Record 탭.
class RecordListPageV2 extends StatefulWidget {
  const RecordListPageV2({
    super.key,
    this.records,
    this.store,
    this.initialMonth,
    this.initialCalendar = false,
    this.onHome,
    this.onProfile,
  });
  final List<RunningRecord>? records;
  final RunningRecordStore? store;
  final DateTime? initialMonth;
  final bool initialCalendar;
  final VoidCallback? onHome, onProfile;
  @override
  State<RecordListPageV2> createState() => _RecordListPageV2State();
}

class _RecordListPageV2State extends State<RecordListPageV2> {
  late bool calendar = widget.initialCalendar;
  late DateTime month = widget.initialMonth ?? DateTime.now();
  DateTime? selectedDay;
  late final _store = widget.store ?? RunningRecordStore.instance;
  List<RunningRecord> _saved = const [];
  bool _loading = true;
  Object? _error;
  List<RunningRecord> get records => widget.records ?? _saved;

  @override
  void initState() {
    super.initState();
    _store.addListener(_reload);
    _reload();
  }

  Future<void> _reload() async {
    try {
      final saved = widget.records ?? await _store.load();
      if (mounted) {
        setState(() {
          _saved = saved;
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _store.removeListener(_reload);
    super.dispose();
  }

  List<RunningRecord> get monthly =>
      records
          .where(
            (r) =>
                r.startedAt.year == month.year &&
                r.startedAt.month == month.month,
          )
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  void _changeMonth(int delta) => setState(() {
    month = DateTime(month.year, month.month + delta);
    selectedDay = null;
  });
  void _openRecord(RunningRecord r) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RecordDetailPage(
          record: r,
          onSaveMemo: (value) => _store.save(r.withMemo(value)),
        ),
      ),
    );
  }

  void _home() {
    if (widget.onHome != null) {
      widget.onHome!();
      return;
    }
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(builder: (_) => const HomePageV2()),
    );
  }

  void _profile() {
    if (widget.onProfile != null) {
      widget.onProfile!();
      return;
    }
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(builder: (_) => const ProfileMainPage()),
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: recordBackground,
    ),
    child: Scaffold(
      backgroundColor: recordBackground,
      bottomNavigationBar: _navigation(),
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              key: PageStorageKey(calendar ? 'record-calendar' : 'record-list'),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('러닝 기록', style: recordText(26, weight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF343D43)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [_toggle('목록', false), _toggle('달력', true)],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: '이전 달',
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left, size: 20),
                        ),
                        Expanded(
                          child: Text(
                            '${month.year}년 ${month.month}월',
                            textAlign: TextAlign.center,
                            style: recordText(18, weight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          tooltip: '다음 달',
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: recordMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFF343D43)),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text('러닝 기록을 불러오지 못했습니다.'),
                          TextButton(
                            onPressed: _reload,
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    )
                  else if (calendar)
                    RecordCalendarPage(
                      embedded: true,
                      records: records,
                      month: month,
                      selectedDay: selectedDay,
                      onDaySelected: (day) => setState(() => selectedDay = day),
                      onRecordTap: _openRecord,
                    )
                  else
                    ..._list(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _toggle(String label, bool value) => Expanded(
    child: Semantics(
      selected: calendar == value,
      button: true,
      child: Material(
        color: calendar == value ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => setState(() => calendar = value),
          child: Center(
            child: Text(
              label,
              style: recordText(
                14,
                color: calendar == value ? recordBackground : recordSecondary,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  List<Widget> _list() {
    final runs = monthly;
    final total = runs.fold(0.0, (sum, r) => sum + r.distanceKm);
    final seconds = runs.fold(0, (sum, r) => sum + r.movingSeconds);
    final kcal = runs.fold(0.0, (sum, r) => sum + r.energyKcal);
    final groups = <DateTime, List<RunningRecord>>{};
    for (final r in runs) {
      final d = DateTime(r.startedAt.year, r.startedAt.month, r.startedAt.day);
      final monday = d.subtract(Duration(days: d.weekday - 1));
      groups.putIfAbsent(monday, () => []).add(r);
    }
    final reference = DateTime.now();
    final currentMonday = DateTime(
      reference.year,
      reference.month,
      reference.day,
    ).subtract(Duration(days: reference.weekday - 1));
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateUtils.isSameMonth(month, DateTime.now())
                        ? '이번 달 달린 거리'
                        : '${month.month}월 달린 거리',
                    style: recordText(
                      12,
                      color: recordSecondary,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: total.toStringAsFixed(2),
                            style: recordNumber(52),
                          ),
                          TextSpan(
                            text: ' km',
                            style: recordText(16, color: recordSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${runs.length}회 러닝',
                  style: recordText(13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  seconds < 3600
                      ? '${seconds ~/ 60}분'
                      : '${seconds ~/ 3600}시간 ${seconds ~/ 60 % 60}분',
                  style: recordText(12, color: recordSecondary),
                ),
                const SizedBox(height: 5),
                Text(
                  '햇반 ${kcal == 0 ? '0' : (kcal / 315).toStringAsFixed(1)}개',
                  style: recordText(12, color: recordSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
      const Divider(height: 1, color: recordLine),
      if (runs.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Text(
            records.isEmpty ? '아직 저장된 러닝 기록이 없습니다.' : '이번 달에는 러닝 기록이 없습니다.',
            textAlign: TextAlign.center,
            style: recordText(14, color: recordMuted),
          ),
        ),
      for (final group in groups.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 26, bottom: 10),
          child: Row(
            children: [
              Text(
                _weekLabel(group.key, currentMonday),
                style: recordText(15, weight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _range(group.key),
                  style: recordText(11, color: recordMuted),
                ),
              ),
              Text(
                records
                    .where(
                      (r) =>
                          !r.startedAt.isBefore(group.key) &&
                          r.startedAt.isBefore(
                            DateTime(
                              group.key.year,
                              group.key.month,
                              group.key.day + 7,
                            ),
                          ),
                    )
                    .fold(0.0, (s, r) => s + r.distanceKm)
                    .toStringAsFixed(2),
                style: recordNumber(16, color: recordSecondary),
              ),
              Text(' km', style: recordText(10, color: recordMuted)),
            ],
          ),
        ),
        const Divider(height: 1, color: recordLine),
        for (final r in group.value) _recordTile(r),
      ],
    ];
  }

  String _weekLabel(DateTime day, DateTime monday) {
    final weeks = monday.difference(day).inDays ~/ 7;
    return weeks == 0
        ? '이번 주'
        : weeks == 1
        ? '지난주'
        : weeks > 1 && weeks < 5
        ? '$weeks주 전'
        : '${day.month}월 ${day.day}일 주';
  }

  String _range(DateTime first) {
    final last = first.add(const Duration(days: 6));
    return '${first.month}월 ${first.day}일 – ${last.month != first.month ? '${last.month}월 ' : ''}${last.day}일';
  }

  Widget _recordTile(RunningRecord r) => InkWell(
    onTap: () => _openRecord(r),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: recordLine)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: RecordRouteMap(record: r, borderRadius: 17, basemap: true),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.dateLabel,
                        style: recordText(14, weight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      clockText(r.startedAt),
                      style: recordText(11, color: recordMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: r.distanceKm.toStringAsFixed(2),
                        style: recordNumber(30),
                      ),
                      TextSpan(
                        text: ' km',
                        style: recordText(12, color: recordSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${r.durationLabel} · ${r.paceLabel}/km · ${r.calories} kcal',
                  style: recordText(11, color: recordSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 17, color: recordMuted),
        ],
      ),
    ),
  );
  Widget _navigation() => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: recordLine)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _nav('홈', Icons.home_outlined, false, _home),
            _nav('기록', Icons.format_align_left, true, () {}),
            _nav('내 정보', Icons.person_outline, false, _profile),
          ],
        ),
      ),
    ),
  );
  Widget _nav(String label, IconData icon, bool selected, VoidCallback onTap) =>
      Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          child: InkWell(
            onTap: onTap,
            child: Column(
              children: [
                Container(
                  height: 3,
                  width: 28,
                  color: selected ? Colors.white : Colors.transparent,
                ),
                const SizedBox(height: 8),
                Icon(
                  icon,
                  size: 22,
                  color: selected ? Colors.white : recordMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: recordText(
                    11,
                    color: selected ? Colors.white : recordMuted,
                    weight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
