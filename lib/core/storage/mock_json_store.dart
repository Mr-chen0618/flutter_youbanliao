import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final mockJsonStoreProvider = Provider<MockJsonStore>((ref) => MockJsonStore());

/// 读取打包样本并串行更新应用目录中的 JSON。
class MockJsonStore {
  MockJsonStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;
  final _pending = <String, Future<void>>{};

  /// 检查已有文件，供旧账号迁移使用，不触发种子复制。
  Future<bool> exists(String path) async => (await _file(path)).exists();

  /// 在文件队列内检查并初始化，避免并发首次读取覆盖已有修改。
  Future<void> initialize(String path, Map<String, dynamic> data) =>
      _serialized(path, () async {
        final file = await _file(path);
        if (!await file.exists()) await _replace(file, jsonEncode(data));
      });

  Future<void> delete(String path) => _serialized(path, () async {
    final file = await _file(path);
    if (await file.exists()) await file.delete();
  });

  Future<T> seed<T>(String path, T Function(Object?) decode) async =>
      decode(jsonDecode(await rootBundle.loadString('assets/mock/$path.json')));

  Future<T> read<T>(String path, T Function(Object?) decode) =>
      _serialized(path, () async {
        final file = await _file(path);
        if (!await file.exists()) {
          final source = await rootBundle.loadString('assets/mock/$path.json');
          final value = decode(jsonDecode(source));
          await _replace(file, source);
          return value;
        }
        return decode(jsonDecode(await file.readAsString()));
      });

  /// 在同一队列内完成读取、修改和替换。
  Future<void> update<T>(
    String path,
    T Function(Object?) decode,
    Map<String, dynamic> Function(T) change,
  ) => _serialized(path, () async {
    final file = await _file(path);
    final source = await file.exists()
        ? await file.readAsString()
        : await rootBundle.loadString('assets/mock/$path.json');
    await _replace(file, jsonEncode(change(decode(jsonDecode(source)))));
  });

  Future<void> write(String path, Map<String, dynamic> data) {
    final json = jsonEncode(data);
    return _serialized(path, () async => _replace(await _file(path), json));
  }

  Future<T> _serialized<T>(String path, Future<T> Function() action) {
    final result = (_pending[path] ?? Future<void>.value()).then(
      (_) => action(),
    );
    final completion = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending[path] = completion;
    return result.whenComplete(() {
      if (identical(_pending[path], completion)) _pending.remove(path);
    });
  }

  Future<File> _file(String path) async {
    final directory = await _directory();
    return File('${directory.path}/mock/$path.json');
  }

  Future<void> _replace(File file, String json) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(json, flush: true);
    await temporary.rename(file.path);
  }
}

final mockWritesProvider =
    NotifierProvider<MockWrites, Map<String, Future<void> Function()>>(
      MockWrites.new,
    );

/// 记录各模块最近一次写入失败，保留可重试的最新快照。
class MockWrites extends Notifier<Map<String, Future<void> Function()>> {
  final _latest = <String, Future<void> Function()>{};

  @override
  Map<String, Future<void> Function()> build() => const {};

  Future<void> save(String module, Future<void> Function() write) async {
    _latest[module] = write;
    if (state.containsKey(module)) state = {...state}..remove(module);
    try {
      await write();
      if (ref.mounted && identical(_latest[module], write)) {
        _latest.remove(module);
        if (state.containsKey(module)) state = {...state}..remove(module);
      }
    } catch (error) {
      if (ref.mounted && identical(_latest[module], write)) {
        state = {...state, module: write};
      }
    }
  }

  Future<void> retry() async {
    await Future.wait([
      for (final entry in state.entries) save(entry.key, entry.value),
    ]);
  }
}
