import 'dart:convert';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';

/// 认证Widget测试使用的账号隔离存储夹具。
class AuthTestStore extends MockJsonStore {
  AuthTestStore(this.seeds);
  final Map<String, String> seeds;
  final data = <String, String>{};
  @override
  Future<void> initialize(String path, Map<String, dynamic> value) async {
    data.putIfAbsent(path, () => jsonEncode(value));
  }

  @override
  Future<bool> exists(String path) async => data.containsKey(path);
  @override
  Future<void> delete(String path) async {
    data.remove(path);
  }

  @override
  Future<T> seed<T>(String path, T Function(Object?) decode) async =>
      decode(jsonDecode(seeds[path]!));
  @override
  Future<T> read<T>(String path, T Function(Object?) decode) async =>
      decode(jsonDecode(data[path] ??= seeds[path]!));
  @override
  Future<void> write(String path, Map<String, dynamic> value) async {
    data[path] = jsonEncode(value);
  }

  @override
  Future<void> update<T>(
    String path,
    T Function(Object?) decode,
    Map<String, dynamic> Function(T) change,
  ) async {
    data[path] = jsonEncode(change(await read(path, decode)));
  }
}
