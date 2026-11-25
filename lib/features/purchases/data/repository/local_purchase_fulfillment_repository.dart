import 'dart:math';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../local/purchase_ledger_store.dart';
import '../model/apple_product.dart';
import '../server/local_apple_transaction_verifier.dart';
import 'purchase_fulfillment_repository.dart';

/// 用户选择的无业务后端方案：本机验证后，本地原子记账。
class LocalPurchaseFulfillmentRepository
    implements PurchaseFulfillmentRepository {
  LocalPurchaseFulfillmentRepository(
    this.store,
    this.verifier, {
    DateTime Function()? now,
    this.initialCoins = 10000,
  }) : _now = now ?? DateTime.now;
  final PurchaseLedgerStore store;
  final int initialCoins;
  final LocalAppleTransactionVerifier verifier;
  final DateTime Function() _now;
  @override
  bool get isConfigured => true;

  Map<String, dynamic> _account(Map<String, dynamic> ledger, String id) {
    if (id.isEmpty) throw StateError('请先登录');
    final accounts = ledger['accounts'] as Map<String, dynamic>;
    final account =
        (accounts.putIfAbsent(
                  id,
                  () => <String, dynamic>{
                    'token': _uuid(),
                    'activeEnvironment': 'Production',
                    'environments': <String, dynamic>{},
                  },
                )
                as Map)
            .cast<String, dynamic>();
    // 每账号仅初始化一次；保留已有充值与消费，重启不会补满余额。
    if (account['initialCoinsGranted'] != true) {
      final environment = account['activeEnvironment'] as String;
      final environments = account['environments'] as Map<String, dynamic>;
      final wallet =
          environments.putIfAbsent(
                environment,
                () => <String, dynamic>{'coins': 0, 'vipExpiresAt': null},
              )
              as Map;
      wallet['coins'] = (wallet['coins'] as int? ?? 0) + initialCoins;
      account['initialCoinsGranted'] = true;
      accounts[id] = account;
    }
    return account;
  }

  @override
  Future<String> accountToken(String accountId) => store.transaction(
    (ledger) => _account(ledger, accountId)['token'] as String,
  );

  @override
  Future<PurchaseEntitlements> loadEntitlements(String accountId) =>
      store.transaction((ledger) {
        final account = _account(ledger, accountId);
        return _snapshot(
          accountId,
          account,
          account['activeEnvironment'] as String,
        );
      });

  @override
  Future<PurchaseEntitlements> verifyAndDeliver(
    PurchaseDetails purchase,
  ) async {
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      throw StateError('交易尚未付款');
    }
    final id = purchase.purchaseID;
    final product = AppleProduct.find(purchase.productID);
    if (id == null || id.isEmpty || product == null) {
      throw StateError('无效商品或交易');
    }
    final verified = await verifier.verify(id, product.productId);
    if (verified.transactionId != id ||
        verified.productId != product.productId ||
        !const {
          'Production',
          'Sandbox',
          'Xcode',
        }.contains(verified.environment) ||
        verified.purchaseDate.isAfter(
          _now().toUtc().add(const Duration(minutes: 5)),
        )) {
      throw StateError('交易信息不一致');
    }
    return store.transaction((ledger) {
      final accounts = ledger['accounts'] as Map<String, dynamic>;
      String? owner;
      Map<String, dynamic>? account;
      for (final entry in accounts.entries) {
        final candidate = (entry.value as Map).cast<String, dynamic>();
        if (candidate['token'] == verified.accountToken) {
          owner = entry.key;
          account = candidate;
          break;
        }
      }
      // 不把来源不明的历史交易绑定到回调时的登录用户。
      if (owner == null || account == null) throw StateError('交易账号无法匹配，请联系客服');
      final environment = verified.environment;
      final key = '$environment:$id';
      final transactions = ledger['transactions'] as Map<String, dynamic>;
      final existing = transactions[key] as Map?;
      if (existing != null) {
        if (existing['accountId'] != owner ||
            existing['productId'] != product.productId) {
          throw StateError('交易归属不一致');
        }
        return _snapshot(owner, account, environment);
      }
      final environments = account['environments'] as Map<String, dynamic>;
      final wallet =
          (environments.putIfAbsent(
                    environment,
                    () => <String, dynamic>{'coins': 0, 'vipExpiresAt': null},
                  )
                  as Map)
              .cast<String, dynamic>();
      final now = _now().toUtc();
      if (product.isMembership) {
        final expiry = DateTime.tryParse(
          wallet['vipExpiresAt'] as String? ?? '',
        )?.toUtc();
        final base = expiry != null && expiry.isAfter(now) ? expiry : now;
        wallet['vipExpiresAt'] = addCalendarMonths(
          base,
          product.quantity,
        ).toIso8601String();
      } else {
        wallet['coins'] = (wallet['coins'] as int) + product.quantity;
      }
      environments[environment] = wallet;
      account['activeEnvironment'] = environment;
      accounts[owner] = account;
      transactions[key] = {
        'accountId': owner,
        'productId': product.productId,
        'purchaseDate': verified.purchaseDate.toIso8601String(),
        'deliveredAt': now.toIso8601String(),
        'coins': product.isMembership ? 0 : product.quantity,
        'months': product.isMembership ? product.quantity : 0,
      };
      return _snapshot(owner, account, environment);
    });
  }

  PurchaseEntitlements _snapshot(
    String owner,
    Map<String, dynamic> account,
    String environment,
  ) {
    final wallet = (account['environments'] as Map)[environment] as Map?;
    return PurchaseEntitlements(
      accountId: owner,
      coinBalance: wallet?['coins'] as int? ?? 0,
      vipExpiresAt: DateTime.tryParse(wallet?['vipExpiresAt'] as String? ?? ''),
      environment: environment,
    );
  }

  static DateTime addCalendarMonths(DateTime base, int months) {
    final month = DateTime.utc(base.year, base.month + months, 1);
    final day = min(base.day, DateTime.utc(month.year, month.month + 1, 0).day);
    return DateTime.utc(
      month.year,
      month.month,
      day,
      base.hour,
      base.minute,
      base.second,
      base.millisecond,
      base.microsecond,
    );
  }

  String _uuid() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
