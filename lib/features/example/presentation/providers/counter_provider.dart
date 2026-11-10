import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/mock_json_store.dart';

final counterProvider = AsyncNotifierProvider<CounterNotifier, int>(
  CounterNotifier.new,
);

/// 计数器示例使用本地 JSON 保存数值。
class CounterNotifier extends AsyncNotifier<int> {
  static const _path = 'example/counter';

  @override
  Future<int> build() => ref.watch(mockJsonStoreProvider).read(_path, _decode);

  int _decode(Object? json) => (json as Map<String, dynamic>)['count'] as int;

  Future<void> increment() => _change((count) => count + 1);
  Future<void> decrement() => _change((count) => count - 1);
  Future<void> reset() => _change((count) => 0);

  Future<void> _change(int Function(int) update) async {
    final store = ref.read(mockJsonStoreProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await store.update(_path, _decode, (count) => {'count': update(count)});
      return store.read(_path, _decode);
    });
    if (ref.mounted) state = result;
  }
}
