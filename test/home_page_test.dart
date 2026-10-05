import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runnery_new/home/home_page.dart';
import 'package:runnery_new/login/login.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('Home fits width $width with enlarged text', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var started = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 844),
              textScaler: TextScaler.linear(1.3),
            ),
            child: HomePage(onStartRun: () => started = true),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('러닝 시작'));
      await tester.tap(find.text('러닝 시작'));
      expect(started, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Successful login replaces login with home', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(onLogin: (_, _) async {})),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'runner');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Failed login stays on login', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          onLogin: (_, _) async {
            throw Exception('denied');
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'runner');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
