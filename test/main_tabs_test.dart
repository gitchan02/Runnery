import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runnery_new/home/home_page.dart';
import 'package:runnery_new/home/main_tabs.dart';
import 'package:runnery_new/record/list/record_list_page.dart';

void main() {
  testWidgets('tabs switch instantly, hide others and keep pages alive', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: MainTabs()));
    await tester.pump();
    final home = tester.state(find.byType(HomePageV2));

    // 한 프레임 만에 기록만 보이고 홈은 그려지지 않습니다.
    await tester.tap(find.text('기록').last);
    await tester.pump();
    expect(find.byType(RecordListPageV2), findsOneWidget);
    expect(find.byType(HomePageV2), findsNothing);
    expect(find.byType(HomePageV2, skipOffstage: false), findsOneWidget);

    // 다시 홈으로 오면 처음 만든 화면을 그대로 씁니다.
    await tester.tap(find.text('홈').last);
    await tester.pump();
    expect(find.byType(RecordListPageV2), findsNothing);
    expect(tester.state(find.byType(HomePageV2)), same(home));
    expect(tester.takeException(), isNull);
  });
}
