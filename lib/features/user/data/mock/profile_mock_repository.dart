import '../../../../core/storage/mock_json_store.dart';
import '../model/user_state.dart';
import '../repository/profile_repository.dart';

class ProfileMockRepository implements ProfileRepository {
  const ProfileMockRepository(this.store);
  final MockJsonStore store;
  static const _path = 'user/account';

  UserState _decode(Object? json) =>
      UserState.fromJson(json as Map<String, dynamic>);

  @override
  Future<UserState> load() => store.read(_path, _decode);

  @override
  Future<void> save(UserState data) => store.write(_path, data.toJson());

  @override
  Future<UserState> reset() => store.seed(_path, _decode);
}
