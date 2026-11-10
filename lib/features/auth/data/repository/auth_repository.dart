import '../../../user/data/model/member_profile.dart';
import '../model/auth_session.dart';
import '../request-model/phone_login_request.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restore();
  Future<void> sendCode(String phone);
  Future<AuthSession> login(PhoneLoginRequest request);
  Future<void> completeProfile(String accountId, MemberProfile profile);
  Future<void> signOut();
  Future<void> deleteAccount(String accountId);
}
