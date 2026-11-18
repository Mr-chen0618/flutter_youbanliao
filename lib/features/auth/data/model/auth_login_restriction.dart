/// 验证码通过后仍需用户明确选择是否撤销注销。
class AuthAccountPendingDeletion implements Exception {
  const AuthAccountPendingDeletion(this.accountId, this.deadline);
  final String accountId;
  final DateTime deadline;
}

/// 账号受限状态由认证数据提供，不由页面虚构。
class AuthAccountSuspended implements Exception {
  const AuthAccountSuspended({required this.reason, this.unblocksAt});
  final String reason;
  final DateTime? unblocksAt;
}
