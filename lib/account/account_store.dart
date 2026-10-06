import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../login/auth_ui/auth_ui.dart' show RegistrationData;
import '../record/data/running_record_store.dart';

/// 로그인 정보가 맞지 않을 때.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 가입할 때 입력한 정보. 비밀번호는 담지 않습니다.
@immutable
class Account {
  const Account({
    required this.name,
    required this.email,
    required this.id,
    required this.age,
    required this.gender,
    required this.weightKg,
  });
  final String name, email, id, gender;
  final int age;
  final double weightKg;

  /// 아바타에 쓰는 이름 첫 글자.
  String get initial =>
      name.isEmpty ? '러' : String.fromCharCode(name.runes.first);
}

/// 이 기기에만 저장되는 계정 하나와 로그인 상태.
/// 서버가 없으므로 다른 기기에서는 불러올 수 없고, 앱을 지우면 함께 사라집니다.
class AccountStore extends ChangeNotifier {
  AccountStore({
    Future<Directory> Function()? directory,
    RunningRecordStore? records,
  }) : _directory = directory ?? getApplicationDocumentsDirectory,
       _records = records;

  /// 앱 전체가 쓰는 저장소. 테스트에서만 교체합니다.
  static AccountStore instance = AccountStore();

  static const _iterations = 10000;
  final Future<Directory> Function() _directory;
  final RunningRecordStore? _records;
  RunningRecordStore get records => _records ?? RunningRecordStore.instance;

  Account? _account;
  String? _salt, _hash;
  bool _loggedIn = false;
  bool _loaded = false;
  Future<void> _pending = Future.value();

  /// 가입된 계정이 있는지. 로그아웃 상태여도 true입니다.
  bool get hasAccount => _account != null;
  bool get isLoggedIn => _loggedIn && _account != null;

  /// 로그인한 사용자. 로그아웃 상태면 null.
  Account? get current => isLoggedIn ? _account : null;

  Future<File> _file() async =>
      File('${(await _directory()).path}/account.json');

  /// 저장된 계정과 로그인 상태를 읽습니다. 파일이 없거나 깨졌으면 계정 없음으로 봅니다.
  Future<void> load() async {
    await _pending;
    if (_loaded) return;
    try {
      final file = await _file();
      if (!await file.exists()) {
        _loaded = true;
        return;
      }
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _account = Account(
        name: json['name'] as String,
        email: json['email'] as String,
        id: json['id'] as String,
        age: json['age'] as int,
        gender: json['gender'] as String,
        weightKg: (json['weightKg'] as num).toDouble(),
      );
      _salt = json['salt'] as String;
      _hash = json['hash'] as String;
      _loggedIn = json['loggedIn'] as bool? ?? false;
    } catch (_) {
      _account = null;
      _loggedIn = false;
    }
    _loaded = true;
    notifyListeners();
  }

  static String _digest(String password, String salt) {
    var bytes = Uint8List.fromList(utf8.encode('$salt:$password'));
    for (var i = 0; i < _iterations; i++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }
    return base64Encode(bytes);
  }

  static String _newSalt() {
    final random = Random.secure();
    return base64Encode([for (var i = 0; i < 16; i++) random.nextInt(256)]);
  }

  Future<void> _write() {
    final operation = _pending.then((_) async {
      final a = _account!;
      final target = await _file();
      final temporary = File('${target.path}.tmp');
      await temporary.writeAsString(
        jsonEncode({
          'version': 1,
          'name': a.name,
          'email': a.email,
          'id': a.id,
          'age': a.age,
          'gender': a.gender,
          'weightKg': a.weightKg,
          'salt': _salt,
          'hash': _hash,
          'loggedIn': _loggedIn,
        }),
        flush: true,
      );
      await temporary.rename(target.path);
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  /// 새 계정을 만들고 바로 로그인합니다. 이전 계정과 그 러닝 기록은 삭제됩니다.
  Future<void> register(RegistrationData data) async {
    await records.clear();
    final salt = _newSalt();
    _account = Account(
      name: data.name.trim(),
      email: data.email.trim(),
      id: data.id.trim(),
      age: data.age,
      gender: data.gender,
      weightKg: data.weight,
    );
    _salt = salt;
    _hash = _digest(data.password, salt);
    _loggedIn = true;
    await _write();
    notifyListeners();
  }

  Future<void> login(String id, String password) async {
    final a = _account;
    final salt = _salt;
    final hash = _hash;
    if (a == null || salt == null || hash == null) {
      throw const AuthException('가입된 계정이 없어요');
    }
    final same = _digest(password, salt) == hash;
    if (id.trim() != a.id || !same) {
      throw const AuthException('아이디 또는 비밀번호가 맞지 않아요');
    }
    _loggedIn = true;
    await _write();
    notifyListeners();
  }

  /// 계정과 기록은 그대로 두고 로그인 상태만 해제합니다.
  Future<void> logout() async {
    if (_account == null) return;
    _loggedIn = false;
    await _write();
    notifyListeners();
  }
}
