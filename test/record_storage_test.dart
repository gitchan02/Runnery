import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:runnery_new/home/running/running_start_page.dart' as gps;
import 'package:runnery_new/record/data/record_from_session.dart';
import 'package:runnery_new/record/data/running_record_store.dart';
import 'package:runnery_new/record/models/running_record.dart';

void main() {
  late Directory directory;
  late RunningRecordStore store;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('runnery_record_test_');
    store = RunningRecordStore(directory: () async => directory);
  });
  tearDown(() async {
    store.dispose();
    await directory.delete(recursive: true);
  });

  RunningRecord record(String id, DateTime date) => RunningRecord(
    id: id,
    startedAt: date,
    finishedAt: date.add(const Duration(seconds: 660)),
    distanceKm: 1.5,
    movingSeconds: 600,
    movingMilliseconds: 600125,
    pauseSeconds: 60,
    calories: 100,
    caloriesKcal: 100.4,
    route: [RecordCoordinate(37.5, 127, timestamp: date, startsSegment: true)],
  );

  test('fresh install is empty; saved runs survive a new store and sort newest first', () async {
    expect(await store.load(), isEmpty);
    final first = record('first', DateTime(2026, 9, 30));
    final last = record('last', DateTime(2026, 10, 1));
    await Future.wait([store.save(first), store.save(last)]);
    final reopened = RunningRecordStore(directory: () async => directory);
    final loaded = await reopened.load();
    expect(loaded.map((r) => r.id), ['last', 'first']);
    expect(loaded.last.toJson(), first.toJson());
    reopened.dispose();
  });

  test('delete removes only that run and notifies listeners', () async {
    await store.save(record('keep', DateTime(2026, 9, 30)));
    await store.save(record('gone', DateTime(2026, 10, 1)));
    var notified = 0;
    store.addListener(() => notified++);
    await store.delete('gone');
    await store.delete('missing');
    expect((await store.load()).map((r) => r.id), ['keep']);
    expect(notified, 2);
  });

  test(
    'retries and memo updates replace the same id without losing GPS',
    () async {
      final run = record('same-id', DateTime(2026, 10, 1));
      await store.save(run);
      await store.save(run);
      await store.save(run.withMemo('test memo'));
      final loaded = await store.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.memo, 'test memo');
      expect(loaded.single.route.single.timestamp, run.startedAt);
      expect(loaded.single.route.single.startsSegment, isTrue);
      expect(loaded.single.finishedAt, run.finishedAt);
    },
  );

  test(
    'invalid or corrupt storage is reported, not presented as an empty history',
    () async {
      final folder = Directory('${directory.path}/running_records');
      await folder.create();
      await File('${folder.path}/corrupt.json').writeAsString('{broken');
      await expectLater(store.load(), throwsFormatException);
    },
  );

  test(
    'a failed save can be retried without poisoning the write queue',
    () async {
      var fail = true;
      final flaky = RunningRecordStore(
        directory: () async {
          if (fail) throw const FileSystemException('simulated failure');
          return directory;
        },
      );
      final run = record('retry', DateTime(2026, 10, 1));
      await expectLater(flaky.save(run), throwsA(isA<FileSystemException>()));
      fail = false;
      await flaky.save(run);
      expect(await flaky.load(), hasLength(1));
      flaky.dispose();
    },
  );

  test('GPS conversion preserves timestamps, segment boundaries and measured metrics', () {
    final start = DateTime(2026, 10, 1, 8);
    gps.TrackPoint point(int second, double meters, double lng) =>
        gps.TrackPoint(
          latLng: LatLng(37.5, lng),
          time: start.add(Duration(seconds: second)),
          moving: Duration(seconds: second),
          meters: meters,
          accuracy: 5,
        );
    final a = point(0, 0, 127), b = point(10, 30, 127.0003);
    final c = point(20, 30, 127.0004), d = point(30, 60, 127.0007);
    final source = gps.RunningRecord(
      startedAt: start,
      endedAt: start.add(const Duration(seconds: 50)),
      distanceMeters: 60,
      movingDuration: const Duration(seconds: 30),
      weightKg: 65,
      segments: [
        [a, b],
        [c, d],
      ],
      pausePoints: [b],
      diagnostics: {'received': 4, 'droppedAccuracy': 1},
    );
    final converted = recordFromSession(source);
    final decoded = RunningRecord.fromJson(
      jsonDecode(jsonEncode(converted.toJson())) as Map<String, dynamic>,
    );
    expect(decoded.distanceKm, .06);
    expect(decoded.diagnostics?['droppedAccuracy'], 1);
    // 메모를 고쳐 다시 저장해도 진단 기록은 남습니다.
    expect(decoded.withMemo('memo').diagnostics?['received'], 4);
    expect(decoded.pauseSeconds, 20);
    expect(decoded.averageSpeed, source.averageSpeedKmh);
    expect(decoded.maxSpeed, source.maxSpeedKmh);
    expect(decoded.energyKcal, source.calories);
    expect(decoded.hetbahnCount, source.hetbahnCount);
    expect(decoded.route.map((p) => p.startsSegment), [
      true,
      false,
      true,
      false,
    ]);
    expect(decoded.route.map((p) => p.timestamp), [
      a.time,
      b.time,
      c.time,
      d.time,
    ]);
  });

  test('GPS jitter while walking is not counted as running calories', () {
    final start = DateTime(2026, 10, 1, 8);
    var meters = 0.0;
    // 1초마다 0.3m·2.7m를 번갈아 가는 걷기(평균 분속 90m). 쌍마다 보면 분속 162m로 달리기처럼 튑니다.
    final points = [
      for (var i = 0; i <= 120; i++)
        gps.TrackPoint(
          latLng: const LatLng(37.5, 127),
          time: start.add(Duration(seconds: i)),
          moving: Duration(seconds: i),
          meters: meters += i == 0 ? 0 : (i.isOdd ? .3 : 2.7),
          accuracy: 5,
        ),
    ];
    final kcal = gps.RunningCalc.activeCalories([points], 65);
    expect(kcal, closeTo(.1 * points.last.meters * 65 / 1000 * 5, .01));
  });

  test('diagnostics keep counts and long accuracy losses', () {
    final d = gps.RunningDiagnostics();
    for (var i = 0; i < 6; i++) {
      d.accuracyDropped(40.0 + i);
    }
    d.accuracyOk();
    d.accuracyDropped(30);
    d.accuracyOk();
    final json = d.toJson();
    expect(json['droppedAccuracy'], 7);
    expect(json['worstAccuracyMeters'], 45);
    final events = json['events']! as List;
    // 5개 이상 연달아 버린 구간만 사건으로 남습니다.
    expect(events, hasLength(1));
    expect((events.single as Map)['dropped'], 6);
  });

  test('places fill in later without losing a memo saved meanwhile', () async {
    final run = record('placed', DateTime(2026, 10, 1));
    expect(run.missingPlaces, isTrue);
    await store.save(run);
    await store.update('placed', (r) => r.withMemo('good run'));
    await store.update(
      'placed',
      (r) => r.withPlaces(area: '오류동', start: '오류역', end: null),
    );
    final loaded = (await store.load()).single;
    expect(loaded.memo, 'good run');
    expect(loaded.place, '오류동');
    expect(loaded.startPlace, '오류역');
    expect(loaded.endPlace, unknownPlace);
    await store.update('missing', (r) => r.withMemo('x'));
    expect(await store.load(), hasLength(1));
  });

  test('auto pause stops only the clock and keeps distance continuous', () {
    var clock = DateTime(2026, 10, 11, 8);
    final session = gps.RunningSession(
      weightKg: 65,
      autoPause: true,
      now: () => clock,
    );
    Position at(double north, {double speed = -1}) => Position(
      latitude: 37.5 + north / 111000,
      longitude: 127,
      timestamp: clock,
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: speed,
      speedAccuracy: 0,
    );
    session.startWithoutGps();
    session.addPosition(at(0));
    clock = clock.add(const Duration(seconds: 5));
    session.addPosition(at(10, speed: 2));
    expect(session.distanceMeters, closeTo(10, .5));

    // 11초 동안 움직임이 없으면 자동 일시정지.
    clock = clock.add(const Duration(seconds: 11));
    session.checkAutoPause();
    expect(session.autoPaused, isTrue);
    expect(session.status, gps.RunningStatus.running);

    // 제자리 흔들림(4m, 속도 0)은 거리로 더하지 않고 계속 멈춰 있습니다.
    clock = clock.add(const Duration(seconds: 20));
    session.addPosition(at(14, speed: 0));
    expect(session.autoPaused, isTrue);
    expect(session.distanceMeters, closeTo(10, .5));

    // 다시 걷기 시작하면 멈춘 곳부터 거리가 이어지고 시간도 다시 잽니다.
    clock = clock.add(const Duration(seconds: 3));
    session.addPosition(at(13, speed: 1.4));
    expect(session.autoPaused, isFalse);
    expect(session.distanceMeters, closeTo(13, .5));
    expect(session.segments, hasLength(1));
    session.dispose();
  });

  test('missing speed data does not become an invented maximum', () {
    final r = record('no-speed', DateTime(2026));
    expect(r.toJson()['maxSpeedKmh'], isNull);
    expect(r.toJson()['bestPaceSeconds'], isNull);
    expect(r.speeds, isEmpty);
  });
}
