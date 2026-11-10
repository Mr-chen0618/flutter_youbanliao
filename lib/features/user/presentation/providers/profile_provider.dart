import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/mock_json_store.dart';
import '../../data/profile_repository.dart';
import '../bloc/user_bloc.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileMockRepository(ref.watch(mockJsonStoreProvider)),
);

final profileInitialProvider = FutureProvider<UserState>(
  (ref) => ref.watch(profileRepositoryProvider).load(),
);

final userBlocProvider = Provider<UserBloc>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final writes = ref.read(mockWritesProvider.notifier);
  final bloc = UserBloc(
    repository,
    ref.watch(profileInitialProvider).requireValue,
  );
  final subscription = bloc.stream.listen(
    (state) => unawaited(writes.save('user', () => repository.save(state))),
  );
  ref.onDispose(() => unawaited(subscription.cancel()));
  ref.onDispose(() => unawaited(bloc.close()));
  return bloc;
});

/// 将 Bloc 状态接到现有 Riverpod 页面和跨模块读取入口。
final profileProvider = StreamProvider<UserState>((ref) {
  final bloc = ref.watch(userBlocProvider);
  return Stream.multi((controller) {
    final subscription = bloc.stream.listen(
      controller.addSync,
      onDone: controller.closeSync,
    );
    controller.onCancel = subscription.cancel;
    controller.addSync(bloc.state);
  });
});

/// 读取资料编辑可选的兴趣和标签。
final profileInterestsProvider = FutureProvider<Map<String, List<String>>>(
  (ref) => ref.watch(mockJsonStoreProvider).seed('user/interests', (json) {
    final labels = <String, List<String>>{};
    for (final entry in (json as List).cast<Map<String, dynamic>>()) {
      labels
          .putIfAbsent(entry['type'] as String, () => [])
          .add(entry['label'] as String);
    }
    return labels;
  }),
);
