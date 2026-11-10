import '../model/user_state.dart';

abstract interface class ProfileRepository {
  Future<UserState> load();
  Future<void> save(UserState data);
  Future<UserState> reset();
}
