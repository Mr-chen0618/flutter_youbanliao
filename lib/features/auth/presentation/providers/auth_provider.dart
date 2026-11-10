import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/mock_json_store.dart';
import '../../data/mock/auth_mock_repository.dart';
import '../../data/repository/auth_repository.dart';
import '../../data/model/auth_session.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthMockRepository(ref.watch(mockJsonStoreProvider)),
);
final authSessionProvider = FutureProvider<AuthSession?>(
  (ref) => ref.watch(authRepositoryProvider).restore(),
);
