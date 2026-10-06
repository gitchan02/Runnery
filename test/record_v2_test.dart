import 'package:runnery_new/record/data/running_record_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runnery_new/record/list/record_list_page.dart';
import 'package:runnery_new/record/list/detail/record_detail_page.dart';
import 'package:runnery_new/record/record_calendar_page.dart';

void main() {
  testWidgets('store records load on entry and refresh after saving', (
    tester,
  ) async {
    final store = _MemoryStore();
    final run = RunningRecord(
      id: 'live',
      startedAt: DateTime.now(),
      distanceKm: 1,
      movingSeconds: 300,
      calories: 50,
      route: const [],
    );
    await tester.pumpWidget(MaterialApp(home: RecordListPageV2(store: store)));
    await tester.pumpAndSettle();
    expect(find.text('아직 저장된 러닝 기록이 없습니다.'), findsOneWidget);
    await store.save(run);
    await tester.pumpAndSettle();
    expect(find.text('1회 러닝'), findsOneWidget);
    expect(find.text(run.dateLabel), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  testWidgets(
    'empty history shows zero stats without fabricated rows or calendar routes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RecordListPageV2(
            records: const [],
            initialMonth: DateTime.now(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('아직 저장된 러닝 기록이 없습니다.'), findsOneWidget);
      expect(find.text('0회 러닝'), findsOneWidget);
      expect(find.text('0분'), findsOneWidget);
      expect(find.text('햇반 0개'), findsOneWidget);
      expect(find.byType(RecordRouteMap), findsNothing);
      await tester.tap(find.text('달력'));
      await tester.pumpAndSettle();
      expect(find.byType(MiniRunningRoute), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'month changes update totals and a selected row opens the same record',
    (tester) async {
      final september = RunningRecord(
        id: 'sep',
        startedAt: DateTime(2026, 9, 30, 8),
        distanceKm: 2,
        movingSeconds: 600,
        calories: 50,
        route: const [],
      );
      final october = RunningRecord(
        id: 'oct',
        startedAt: DateTime(2026, 10, 1, 9),
        distanceKm: 3,
        movingSeconds: 1200,
        calories: 75,
        route: const [],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RecordListPageV2(
            records: [september, october],
            initialMonth: DateTime(2026, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1회 러닝'), findsOneWidget);
      expect(find.text('20분'), findsOneWidget);
      expect(
        find.text('5.00'),
        findsOneWidget,
      ); // Full week across the month boundary.
      await tester.tap(find.byTooltip('이전 달'));
      await tester.pumpAndSettle();
      expect(find.text('10분'), findsOneWidget);
      expect(find.text(september.dateLabel), findsOneWidget);
      expect(find.text(october.dateLabel), findsNothing);
      await tester.tap(find.text(september.dateLabel));
      await tester.pumpAndSettle();
      expect(
        tester.widget<RecordDetailPage>(find.byType(RecordDetailPage)).record,
        same(september),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('calendar mini routes use only actual saved coordinates', (
    tester,
  ) async {
    final points = [
      RecordCoordinate(37.5, 127, timestamp: DateTime(2026, 10, 1)),
      const RecordCoordinate(37.501, 127.002),
    ];
    final run = RunningRecord(
      id: 'gps',
      startedAt: DateTime(2026, 10, 1),
      distanceKm: .2,
      movingSeconds: 60,
      calories: 10,
      route: points,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecordCalendarPage(
              embedded: true,
              records: [run],
              month: DateTime(2026, 10),
              selectedDay: DateTime(2026, 10, 2),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MiniRunningRoute), findsOneWidget);
    expect(
      tester
          .widget<MiniRunningRoute>(find.byType(MiniRunningRoute))
          .coordinates,
      same(points),
    );
    expect(find.byType(RecordRouteMap), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _MemoryStore extends RunningRecordStore {
  final _records = <RunningRecord>[];
  @override
  Future<List<RunningRecord>> load() async => List.unmodifiable(_records);
  @override
  Future<void> save(RunningRecord record) async {
    _records.add(record);
    notifyListeners();
  }
}
