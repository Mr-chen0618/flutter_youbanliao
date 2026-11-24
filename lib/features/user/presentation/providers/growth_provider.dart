import '../../data/model/growth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/mock_json_store.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../purchases/presentation/providers/apple_purchase_provider.dart';
import '../../data/repository/growth_repository.dart';

final growthRepositoryProvider = Provider<GrowthRepository>(
  (ref) => GrowthRepository(
    ref.watch(mockJsonStoreProvider),
    ref.watch(purchaseLedgerStoreProvider),
    ref.watch(authSessionProvider).value?.accountId ?? '',
  ),
);
final growthProvider = FutureProvider<GrowthState>(
  (ref) async =>
      GrowthState.fromJson(await ref.watch(growthRepositoryProvider).load()),
);
