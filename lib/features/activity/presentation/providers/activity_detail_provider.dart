import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/mock_json_store.dart';
import '../../data/mock/activity_detail_mock_repository.dart';
import '../../data/repository/activity_detail_repository.dart';

final activityDetailRepositoryProvider = Provider<ActivityDetailRepository>(
  (ref) => ActivityDetailMockRepository(ref.watch(mockJsonStoreProvider)),
);

final activityDetailProvider = FutureProvider.autoDispose.family(
  (ref, String id) => ref.watch(activityDetailRepositoryProvider).load(id),
);

final joinedActivityIdsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(activityDetailRepositoryProvider).joinedIds(),
);

final followedActivityPublisherIdsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(activityDetailRepositoryProvider).followedIds(),
);
