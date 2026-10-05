import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runnery_new/main.dart';
import 'package:runnery_new/app_start.dart';
import 'package:runnery_new/login/login.dart';
import 'package:runnery_new/login/sign_up/basic_info.dart';
import 'package:runnery_new/login/sign_up/account.dart';
import 'package:runnery_new/login/sign_up/running_info.dart';

void main() {
  testWidgets('Startup opens login and replaces the splash route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    expect(find.byType(AppStartPage), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(AppStartPage), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();
    expect(find.byType(BasicInfoPage), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '김민지');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'minji@example.com',
    );
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountPage), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'minji_run');
    await tester.enterText(find.byType(TextFormField).at(1), 'runner123');
    await tester.enterText(find.byType(TextFormField).at(2), 'runner123');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.byType(RunningInfoPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Disposing splash cancels delayed navigation', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
