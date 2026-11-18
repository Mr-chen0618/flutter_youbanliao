import 'package:in_app_purchase/in_app_purchase.dart';

/// 验证并持久化后的权益快照；可由本机或未来服务端实现提供。
class PurchaseEntitlements {
  const PurchaseEntitlements({
    required this.accountId,
    required this.coinBalance,
    this.vipExpiresAt,
    this.environment,
  });
  final String accountId;
  final int coinBalance;
  final DateTime? vipExpiresAt;
  final String? environment;
}

/// 交易验证和发放扩展点，当前采用本机 StoreKit 验证及本地账本。
abstract class PurchaseFulfillmentRepository {
  bool get isConfigured;

  /// 返回为当前账号持久化分配的稳定 UUID (StoreKit appAccountToken)。
  Future<String> accountToken(String accountId);

  Future<PurchaseEntitlements> loadEntitlements(String accountId);

  /// 校验 Apple 签名、bundle/environment/product/transaction/appAccountToken，
  /// 幂等落账并发放金币/固定月数会员，持久化成功后返回权益。
  /// 必须按交易自身的 token 归属，禁止按回调时的当前登录账号发放。
  /// 被拒绝、跨账号及暂时失败均抛异常；客户端不 finish，保留待处理交易。
  Future<PurchaseEntitlements> verifyAndDeliver(PurchaseDetails purchase);
}

/// 尚无后端：关闭付款入口，避免真实扣款后无法到账。
class UnavailablePurchaseFulfillment implements PurchaseFulfillmentRepository {
  const UnavailablePurchaseFulfillment();
  @override
  bool get isConfigured => false;
  Never _unavailable() => throw StateError('充值服务暂未开放');
  @override
  Future<String> accountToken(String accountId) async => _unavailable();
  @override
  Future<PurchaseEntitlements> loadEntitlements(String accountId) async =>
      _unavailable();
  @override
  Future<PurchaseEntitlements> verifyAndDeliver(
    PurchaseDetails purchase,
  ) async => _unavailable();
}
