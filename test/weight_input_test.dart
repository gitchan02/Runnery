import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runnery_new/login/sign_up/running_info.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: RunningInfoPage()));
  }

  testWidgets('tapping the weight lets the user type it with the keypad', (
    tester,
  ) async {
    await open(tester);
    expect(find.textContaining('60.0', findRichText: true), findsOneWidget);
    await tester.tap(find.textContaining('60.0', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('체중 입력'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, '72.5');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('72.5', findRichText: true), findsOneWidget);
    // 눈금자도 같은 값으로 옮겨져, 살짝 밀어도 엉뚱한 값으로 튀지 않아야 합니다.
    final ruler = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).last)
        .controller!;
    expect(ruler.offset, closeTo(72.5 * 34, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('out-of-range weight is rejected and keeps the old value', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.textContaining('60.0', findRichText: true));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '5');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('사이로 입력해주세요'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.textContaining('60.0', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
