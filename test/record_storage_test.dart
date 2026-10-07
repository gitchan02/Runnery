import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
    );
    final converted = recordFromSession(source);
    final decoded = RunningRecord.fromJson(
      jsonDecode(jsonEncode(converted.toJson())) as Map<String, dynamic>,
    );
    expect(decoded.distanceKm, .06);
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

  test('missing speed data does not become an invented maximum', () {
    final r = record('no-speed', DateTime(2026));
    expect(r.toJson()['maxSpeedKmh'], isNull);
    expect(r.toJson()['bestPaceSeconds'], isNull);
    expect(r.speeds, isEmpty);
  });
}
