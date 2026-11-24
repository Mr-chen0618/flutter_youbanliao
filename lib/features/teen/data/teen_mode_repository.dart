import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../../../core/storage/mock_json_store.dart';

/// 设备级监护设置，不随退出账号清除。仅保存随机盐和摘要。
class TeenModeRepository {
  TeenModeRepository(this.store);
  final MockJsonStore store;
  static const path = 'device/teen_mode';
  Future<Map<String, dynamic>> _read() async {
    await store.initialize(path, {'enabled': false});
    return store.read(path, (json) => Map<String, dynamic>.from(json as Map));
  }

  Future<bool> enabled() async => (await _read())['enabled'] == true;
  String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
  Future<void> enable(String pin) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) throw ArgumentError('请输入4位数字密码');
    final salt = base64Url.encode(
      List.generate(32, (_) => Random.secure().nextInt(256)),
    );
    await _read();
    await store.update<Map<String, dynamic>>(
      path,
      (json) => Map<String, dynamic>.from(json as Map),
      (data) {
        if (data['enabled'] == true) {
          throw StateError('请先验证监护密码并关闭模式');
        }
        return {'enabled': true, 'salt': salt, 'hash': _hash(salt, pin)};
      },
    );
  }

  Future<bool> disable(String pin) async {
    var accepted = false;
    await _read();
    await store.update<Map<String, dynamic>>(
      path,
      (json) => Map<String, dynamic>.from(json as Map),
      (data) {
        accepted =
            data['enabled'] == true &&
            data['hash'] == _hash(data['salt'] as String, pin);
        return accepted ? {'enabled': false} : data;
      },
    );
    return accepted;
  }
}
