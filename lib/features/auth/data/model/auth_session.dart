/// 认证会话仅保存稳定账号标识，资料由 user 模块持有。
class AuthSession {
  const AuthSession(this.accountId, {this.profileCompleted = false});
  final String accountId;
  final bool profileCompleted;
}
