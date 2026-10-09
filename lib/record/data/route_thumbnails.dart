import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../home/running/running_home_page.dart' show runneryThumbnailStyle;
import '../models/running_record.dart';
import 'running_record_store.dart';

/// 기록 목록 썸네일 지도 사진. 기록마다 한 번 iOS 지도 엔진으로 사진을 만들어 저장하고 다시 씁니다.
/// 실제 지도를 화면에 띄우지 않으므로 기록이 많아도 지도 잔상이 생기지 않습니다.
class RouteThumbnails {
  RouteThumbnails({RunningRecordStore? store})
    : _store = store ?? RunningRecordStore.instance;

  static final instance = RouteThumbnails();
  static const _channel = MethodChannel('runnery/route_snapshot');

  /// 썸네일 칸 크기(pt). 화면 배율은 iOS가 맞춥니다.
  static const size = 88.0;

  final RunningRecordStore _store;

  /// 지도 사진은 한 장씩 만듭니다. 여러 장을 한꺼번에 만들면 지도 엔진이 무거워집니다.
  Future<void> _queue = Future.value();

  /// 이번 실행에서 만들지 못한 기록(인터넷 없음 등). 다음 실행 때 다시 시도합니다.
  final _failed = <String>{};
  final _making = <String, Future<File?>>{};

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// 저장된 사진이 있으면 바로, 없으면 만들어서 돌려줍니다. 만들 수 없으면 null.
  Future<File?> get(RunningRecord record) async {
    if (!_supported || record.route.length < 2) return null;
    final file = await _store.thumbnailFile(record.id);
    if (await file.exists()) return file;
    if (_failed.contains(record.id)) return null;
    return _making[record.id] ??= _make(
      record,
      file,
    ).whenComplete(() => _making.remove(record.id));
  }

  Future<File?> _make(RunningRecord record, File file) {
    final made = _queue.then((_) async {
      try {
        final ok = await _channel.invokeMethod<bool>('snapshot', {
          'style': runneryThumbnailStyle(),
          'lat': [for (final p in record.route) p.latitude],
          'lng': [for (final p in record.route) p.longitude],
          'starts': [
            for (final (i, p) in record.route.indexed)
              i == 0 || p.startsSegment,
          ],
          'size': size,
          'output': file.path,
        });
        if (ok == true && await file.exists()) return file;
      } catch (_) {
        // 지도 엔진 오류는 경로 그림으로 대신 보여 줍니다.
      }
      _failed.add(record.id);
      return null;
    });
    _queue = made.then<void>((_) {});
    return made;
  }
}
