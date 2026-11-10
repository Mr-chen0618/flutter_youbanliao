import '../../../../core/storage/mock_json_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/activity_reputation_mock_repository.dart';
import '../../data/repository/activity_reputation_repository.dart';

final activityReputationRepositoryProvider =
    Provider<ActivityReputationRepository>(
      (ref) =>
          ActivityReputationMockRepository(ref.watch(mockJsonStoreProvider)),
    );

final activityReputationProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(activityReputationRepositoryProvider).load(),
);
