import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/mock_json_store.dart';
import '../../data/mock/user_detail_mock_repository.dart';
import '../../data/repository/user_detail_repository.dart';

final userDetailRepositoryProvider = Provider<UserDetailRepository>(
  (ref) => UserDetailMockRepository(ref.watch(mockJsonStoreProvider)),
);

final userDetailProvider = FutureProvider.autoDispose.family(
  (ref, String id) => ref.watch(userDetailRepositoryProvider).load(id),
);
