import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runnery_new/account/account_store.dart';
import 'package:runnery_new/design_system/app_theme.dart';
import 'package:runnery_new/login/auth_ui/auth_ui.dart';
import 'package:runnery_new/login/login.dart';
import 'package:runnery_new/profile/profile_mail_page.dart';
import 'package:runnery_new/record/data/running_record_store.dart';
import 'package:runnery_new/record/models/running_record.dart';

import 'support/fake_account_backend.dart';

void main() {
  testWidgets('profile shows the signed-in account and real totals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dir = Directory.systemTemp.createTempSync('runnery_profile_test_');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // 윈도우에서 아직 열려 있는 임시 폴더는 OS가 나중에 정리합니다.
      }
    });
    late final RunningRecordStore records;
    late final AccountStore account;
    // 저장소의 Future는 가짜 시간 영역 밖(runAsync)에서 만들어야 실제 파일 I/O가 끝납니다.
    await tester.runAsync(() async {
      records = RunningRecordStore(directory: () async => dir);
      account = AccountStore(
        directory: () async => dir,
        records: records,
        backend: FakeAccountBackend(),
      );
      await account.register(
        const RegistrationData(
          name: '김민지',
          email: 'minji@example.com',
          id: 'minji_run',
          password: 'runner123',
          age: 31,
          gender: '여성',
          weight: 58.5,
        ),
      );
      for (final (id, km, sec) in [('a', 3.0, 1200), ('b', 5.5, 2400)]) {
        await records.save(
          RunningRecord(
            id: id,
            startedAt: DateTime(2026, 10, 6),
            distanceKm: km,
            movingSeconds: sec,
            calories: 300,
            route: const [
              RecordCoordinate(37.0, 127.0),
              RecordCoordinate(37.001, 127.001),
            ],
          ),
        );
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ProfileMailPage(account: account, records: records),
      ),
    );
    // 기록 읽기는 실제 파일 I/O라서 실제 시간을 흘려보내며 여러 번 갱신합니다.
    for (var i = 0; i < 60; i++) {
      if (find
          .textContaining('8.5 km', findRichText: true)
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(find.text('김민지'), findsOneWidget);
    expect(find.text('@minji_run'), findsOneWidget);
    expect(find.textContaining('8.5 km', findRichText: true), findsOneWidget);
    expect(find.textContaining('0 개의 경로', findRichText: true), findsNothing);
    expect(find.textContaining('2 개의 경로', findRichText: true), findsOneWidget);
    expect(find.textContaining('2 회', findRichText: true), findsOneWidget);
    expect(find.textContaining('58.5', findRichText: true), findsOneWidget);
    expect(find.textContaining('31', findRichText: true), findsOneWidget);
    expect(find.text('여성'), findsOneWidget);
    expect(find.textContaining('1', findRichText: true), findsWidgets);
  });

  testWidgets('logout asks first; cancel keeps the login', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dir = Directory.systemTemp.createTempSync('runnery_logout_test_');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // 윈도우에서 아직 열려 있는 임시 폴더는 OS가 나중에 정리합니다.
      }
    });
    late final RunningRecordStore records;
    late final AccountStore account;
    await tester.runAsync(() async {
      records = RunningRecordStore(directory: () async => dir);
      account = AccountStore(
        directory: () async => dir,
        records: records,
        backend: FakeAccountBackend(),
      );
      await account.register(
        const RegistrationData(
          name: '김민지',
          email: 'minji@example.com',
          id: 'minji_run',
          password: 'runner123',
          age: 31,
          gender: '여성',
          weight: 58.5,
        ),
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ProfileMailPage(account: account, records: records),
      ),
    );
    Finder inDialog(String text) => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text(text),
    );

    // 눌러도 바로 로그아웃되지 않고 확인 창이 뜹니다. 취소하면 로그인이 그대로입니다.
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(find.text('로그아웃할까요?'), findsOneWidget);
    expect(account.isLoggedIn, isTrue);
    await tester.tap(inDialog('취소'));
    await tester.pumpAndSettle();
    expect(find.text('로그아웃할까요?'), findsNothing);
    expect(account.isLoggedIn, isTrue);
    expect(find.byType(LoginPageV2), findsNothing);

    // 확인하면 로그아웃하고 로그인 화면으로 갑니다. 계정 저장은 실제 파일 I/O라서 실제 시간을 흘려보냅니다.
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('로그아웃'));
    for (
      var i = 0;
      i < 40 && find.byType(LoginPageV2).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(account.isLoggedIn, isFalse);
    expect(find.byType(LoginPageV2), findsOneWidget);
  });
}
