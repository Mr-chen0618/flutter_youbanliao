import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/mock_json_store.dart';
import '../../data/mock/my_activity_mock_repository.dart';
import '../../data/repository/my_activity_repository.dart';
import 'activity_detail_provider.dart';

final myActivityRepositoryProvider = Provider<MyActivityRepository>(
  (ref) => MyActivityMockRepository(ref.watch(mockJsonStoreProvider)),
);

final myActivitiesProvider = FutureProvider.autoDispose.family((
  ref,
  bool joined,
) async {
  final repository = ref.watch(myActivityRepositoryProvider);
  final ids = joined
      ? await ref.watch(joinedActivityIdsProvider.future)
      : const <String>{};
  return repository.load(joinedIds: ids);
});
