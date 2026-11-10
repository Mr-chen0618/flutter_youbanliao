import 'dart:convert';
import 'dart:io';

import 'package:flutter_app_framework/core/storage/mock_json_store.dart';

/// Widget 测试在虚拟时钟之外预读业务样本。
class WidgetMockJsonStore extends MockJsonStore {
  WidgetMockJsonStore._(this._samples);
  final Map<String, String> _samples;

  static Future<WidgetMockJsonStore> load() async {
    const paths = [
      'activity/participation',
      'activity/my_activities',
      'home/catalog',
      'report/reports',
      'activity/published',
      'home/invites',
      'messages/inbox',
      'square/feed',
      'user/account',
      'user/interests',
    ];
    return WidgetMockJsonStore._({
      for (final path in paths)
        path: await File('assets/mock/$path.json').readAsString(),
    });
  }

  @override
  Future<T> seed<T>(String path, T Function(Object?) decode) async =>
      decode(jsonDecode(_samples[path]!));

  @override
  Future<T> read<T>(String path, T Function(Object?) decode) =>
      seed(path, decode);

  @override
  Future<void> update<T>(
    String path,
    T Function(Object?) decode,
    Map<String, dynamic> Function(T) change,
  ) async {
    _samples[path] = jsonEncode(change(decode(jsonDecode(_samples[path]!))));
  }

  @override
  Future<void> write(String path, Map<String, dynamic> data) async {
    _samples[path] = jsonEncode(data);
  }
}
