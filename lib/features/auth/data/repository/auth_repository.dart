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

/// 支持冷静期撤销的认证实现提供此扩展能力。
abstract interface class AuthRecoveryRepository {
  Future<AuthSession> recoverAccount(
    String accountId,
    PhoneLoginRequest request,
  );
}
