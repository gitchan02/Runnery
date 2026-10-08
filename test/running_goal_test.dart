import 'package:flutter_test/flutter_test.dart';
import 'package:runnery_new/home/running/running_home_page.dart';

void main() {
  RunningStartOptions options(RunningMode mode) => RunningStartOptions(
    mode: mode,
    voiceGuide: false,
    autoPause: false,
    goalKm: 5,
    goalMinutes: 30,
  );

  test('free run has no goal', () {
    final free = options(RunningMode.free);
    expect(free.goalProgress(3000, const Duration(minutes: 20)), isNull);
    expect(free.goalStatus(3000, const Duration(minutes: 20)), isNull);
  });

  test('distance goal shows remaining km and then reached', () {
    final goal = options(RunningMode.distanceGoal);
    expect(goal.goalProgress(3210, Duration.zero), closeTo(.642, 1e-9));
    expect(goal.goalStatus(3210, Duration.zero), '5 km 목표 · 1.79 km 남음');
    expect(goal.goalStatus(5000, Duration.zero), '5 km 목표 달성!');
  });

  test('time goal shows remaining time and then reached', () {
    final goal = options(RunningMode.timeGoal);
    const elapsed = Duration(minutes: 12, seconds: 30);
    expect(goal.goalStatus(0, elapsed), '30분 목표 · 17:30 남음');
    expect(goal.goalStatus(0, const Duration(minutes: 30)), '30분 목표 달성!');
  });

  test('goal labels', () {
    expect(RunningGoal.km(5), '5 km');
    expect(RunningGoal.km(21.1), '21.1 km');
    expect(RunningGoal.minutes(45), '45분');
    expect(RunningGoal.minutes(60), '1시간');
    expect(RunningGoal.minutes(90), '1시간 30분');
  });
}
