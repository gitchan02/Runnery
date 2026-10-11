import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../home/running/running_start_page.dart' show resolveRunningPlaces;
import '../models/running_record.dart';
import 'running_record_store.dart';

/// 출발·도착·동네 이름을 찾아 기록에 채웁니다. 새 러닝과, 이름 없이 저장된 예전 기록 모두에 씁니다.
/// 지명 찾기는 기기 서비스에 무리가 가지 않게 한 번에 하나씩 합니다.
class RecordPlaces {
  static final instance = RecordPlaces();

  /// 이번 실행에서 이미 시도한 기록. 찾지 못해도(인터넷 없음 등) 다음 실행 때 다시 시도합니다.
  final _tried = <String>{};
  Future<void> _queue = Future.value();

  void fill(RunningRecordStore store, Iterable<RunningRecord> records) {
    for (final r in records) {
      if (r.route.isEmpty || !r.missingPlaces || !_tried.add(r.id)) continue;
      final first = r.route.first, last = r.route.last;
      _queue = _queue.then((_) async {
        try {
          final places = await resolveRunningPlaces(
            LatLng(first.latitude, first.longitude),
            LatLng(last.latitude, last.longitude),
          );
          if (places.start == null &&
              places.end == null &&
              places.area == null) {
            return;
          }
          await store.update(
            r.id,
            (current) => current.withPlaces(
              area: places.area,
              start: places.start,
              end: places.end,
            ),
          );
        } catch (_) {
          // 기록을 못 읽거나 저장하지 못하면 다음 실행 때 다시 시도합니다.
        }
      });
    }
  }
}
