import '../../home/running/running_start_page.dart' as session;
import '../models/running_record.dart';

/// Reuse the GPS team's calculations without generating additional points.
RunningRecord recordFromSession(session.RunningRecord source) => RunningRecord(
  id: 'run-${source.startedAt.microsecondsSinceEpoch}-${source.endedAt.microsecondsSinceEpoch}',
  startedAt: source.startedAt,
  finishedAt: source.endedAt,
  distanceKm: source.distanceMeters / 1000,
  movingSeconds: source.movingDuration.inSeconds,
  movingMilliseconds: source.movingDuration.inMilliseconds,
  pauseSeconds: source.pausedDuration.inSeconds,
  calories: source.calories.round(),
  caloriesKcal: source.calories,
  weightKg: source.weightKg,
  route: List.unmodifiable([
    for (final segment in source.segments)
      for (var i = 0; i < segment.length; i++)
        RecordCoordinate(
          segment[i].latLng.latitude,
          segment[i].latLng.longitude,
          timestamp: segment[i].time,
          startsSegment: i == 0,
        ),
  ]),
  speeds: List.unmodifiable(source.speedSamples.map((s) => s.kmh)),
  speedDistancesKm: List.unmodifiable(source.speedSamples.map((s) => s.km)),
  splitSeconds: List.unmodifiable(
    source.splits.where((s) => s.isFull).map((s) => s.duration.inSeconds),
  ),
  pauseFractions: source.distanceMeters <= 0
      ? const []
      : List.unmodifiable(
          source.pausePoints.map(
            (p) => (p.meters / source.distanceMeters).clamp(0.0, 1.0),
          ),
        ),
);
