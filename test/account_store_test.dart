import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:runnery_new/account/account_store.dart';
import 'package:runnery_new/login/auth_ui/auth_ui.dart';
import 'package:runnery_new/record/data/running_record_store.dart';
import 'package:runnery_new/record/models/running_record.dart';

void main() {
  late Directory directory;
  late RunningRecordStore records;
  AccountStore open() =>
      AccountStore(directory: () async => directory, records: records);

  RegistrationData data({
    String id = 'minji_run',
    String password = 'runner123',
  }) => RegistrationData(
    name: '김민지',
    email: 'minji@example.com',
    id: id,
    password: password,
    age: 26,
    gender: '여성',
    weight: 58.5,
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('runnery_account_test_');
    records = RunningRecordStore(directory: () async => directory);
  });
  tearDown(() => directory.delete(recursive: true));

  test(
    'register logs in, persists, and never stores the plain password',
    () async {
      final store = open();
      await store.register(data());
      expect(store.current?.name, '김민지');
      expect(store.current?.initial, '김');
      expect(store.current?.weightKg, 58.5);

      final reopened = open();
      await reopened.load();
      expect(reopened.isLoggedIn, isTrue);
      expect(reopened.current?.id, 'minji_run');
      final raw = await File('${directory.path}/account.json').readAsString();
      expect(raw.contains('runner123'), isFalse);
    },
  );

  test('logout keeps the account; login checks id and password', () async {
    final store = open();
    await store.register(data());
    await store.logout();
    expect(store.isLoggedIn, isFalse);
    expect(store.hasAccount, isTrue);

    final reopened = open();
    await reopened.load();
    expect(reopened.isLoggedIn, isFalse);
    await expectLater(
      reopened.login('minji_run', 'wrong'),
      throwsA(isA<AuthException>()),
    );
    await expectLater(
      reopened.login('other', 'runner123'),
      throwsA(isA<AuthException>()),
    );
    await reopened.login('minji_run', 'runner123');
    expect(reopened.isLoggedIn, isTrue);
  });

  test('registering again replaces the account and clears records', () async {
    await records.save(
      RunningRecord(
        id: 'run-1',
        startedAt: DateTime(2026, 10, 6),
        distanceKm: 3,
        movingSeconds: 900,
        calories: 200,
        route: const [],
      ),
    );
    expect(await records.load(), hasLength(1));
    final store = open();
    await store.register(data());
    expect(await records.load(), isEmpty);
    await store.register(data(id: 'second', password: 'another123'));
    expect(store.current?.id, 'second');
    await expectLater(
      store.login('minji_run', 'runner123'),
      throwsA(isA<AuthException>()),
    );
  });

  test('missing or broken account file means logged out', () async {
    final store = open();
    await store.load();
    expect(store.hasAccount, isFalse);
    await File('${directory.path}/account.json').writeAsString('{broken');
    await store.load();
    expect(store.isLoggedIn, isFalse);
  });
}
