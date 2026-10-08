import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runnery_new/design_system/app_motion.dart';
import 'package:runnery_new/home/home_page.dart';
import 'package:runnery_new/home/main_tabs.dart';
import 'package:runnery_new/record/list/record_list_page.dart';

void main() {
  testWidgets('tabs slide by direction and keep pages alive', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: MainTabs()));
    await tester.pump();
    final home = tester.state(find.byType(HomePageV2));
    Rect bodyOf(Type type) =>
        tester.getRect(find.byType(type, skipOffstage: false));

    // 화면 안에 계속 도는 애니메이션이 있어 pumpAndSettle 대신 전환 시간만큼 진행합니다.
    // 홈 → 기록: 기록은 오른쪽에서 들어오고 홈은 왼쪽으로 나갑니다.
    await tester.tap(find.text('기록').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(bodyOf(RecordListPageV2).left, greaterThan(0));
    expect(bodyOf(HomePageV2).left, lessThan(0));
    await tester.pump(AppMotion.tabSlide);
    expect(bodyOf(RecordListPageV2).left, 0);

    // 기록 → 홈: 홈은 왼쪽에서 들어오고, 처음 만든 화면을 그대로 씁니다.
    await tester.tap(find.text('홈').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(bodyOf(HomePageV2).left, lessThan(0));
    expect(bodyOf(RecordListPageV2).left, greaterThan(0));
    await tester.pump(AppMotion.tabSlide);
    expect(tester.state(find.byType(HomePageV2)), same(home));
    expect(tester.takeException(), isNull);
  });
}
