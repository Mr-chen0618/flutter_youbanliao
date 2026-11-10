import '../model/user_detail.dart';

abstract interface class UserDetailRepository {
  Future<UserDetail?> load(String id);
}
