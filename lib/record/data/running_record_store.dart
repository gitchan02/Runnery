import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/running_record.dart';

/// Flush a temporary file before publishing each run as an independent JSON file.
class RunningRecordStore extends ChangeNotifier {
  RunningRecordStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationDocumentsDirectory;
  static final instance = RunningRecordStore();
  final Future<Directory> Function() _directory;
  Future<void> _pending = Future.value();

  Future<Directory> _folder() async {
    final base = await _directory();
    return Directory('${base.path}/running_records').create(recursive: true);
  }

  Future<List<RunningRecord>> load() async {
    await _pending;
    final folder = await _folder();
    final records = <RunningRecord>[];
    await for (final file in folder.list()) {
      if (file is! File || !file.path.endsWith('.json')) continue;
      records.add(
        RunningRecord.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        ),
      );
    }
    records.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return List.unmodifiable(records);
  }

  /// 기록 목록 썸네일 지도 사진 파일. 기록과 같은 폴더에 두어 삭제·초기화 때 함께 지워집니다.
  Future<File> thumbnailFile(String id) async =>
      File('${(await _folder()).path}/$id.png');

  /// 저장된 러닝 기록을 모두 지웁니다. 새 계정을 만들 때 씁니다.
  Future<void> clear() {
    final operation = _pending.then((_) async {
      final folder = await _folder();
      await for (final file in folder.list()) {
        if (file is File) await file.delete();
      }
      notifyListeners();
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  /// 기록 하나를 지웁니다. 없는 기록이면 아무 일도 하지 않습니다.
  Future<void> delete(String id) {
    final operation = _pending.then((_) async {
      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
        throw const FormatException('Invalid record id');
      }
      final folder = (await _folder()).path;
      for (final file in [File('$folder/$id.json'), File('$folder/$id.png')]) {
        if (await file.exists()) await file.delete();
      }
      notifyListeners();
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> save(RunningRecord record) {
    final operation = _pending.then((_) async {
      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(record.id)) {
        throw const FormatException('Invalid record id');
      }
      final folder = await _folder();
      final target = '${folder.path}/${record.id}.json';
      final temporary = File('$target.tmp');
      await temporary.writeAsString(jsonEncode(record.toJson()), flush: true);
      await temporary.rename(target);
      notifyListeners();
    });
    // Failed writes must not block a retry or reading existing records.
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
