import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../data/model/apple_product.dart';
import '../../data/repository/purchase_fulfillment_repository.dart';
import '../../data/server/apple_purchase_gateway.dart';

class ApplePurchaseState {
  const ApplePurchaseState({
    this.products = const {},
    this.entitlements = const {},
    this.loading = false,
    this.busy = false,
    this.available = false,
    this.message,
    this.unfinishedCount = 0,
    this.recoveryFailed = false,
  });
  final Map<String, ProductDetails> products;
  final Map<String, PurchaseEntitlements> entitlements;
  final bool loading;
  final bool busy;
  final bool available;
  final String? message;
  final int unfinishedCount;
  final bool recoveryFailed;
}

/// 应用级交易监听器，离开页面不取消；所有交易按队列验证和 finish。
class ApplePurchaseController {
  ApplePurchaseController({
    required this.gateway,
    required this.fulfillment,
    required this.currentAccountId,
    required this.supported,
    Future<void> Function(Duration)? retryDelay,
  }) : _retryDelay = retryDelay ?? Future<void>.delayed;
  final Future<void> Function(Duration) _retryDelay;
  final ApplePurchaseGateway gateway;
  final PurchaseFulfillmentRepository fulfillment;
  final String? Function() currentAccountId;
  final bool supported;
  final _changes = StreamController<ApplePurchaseState>.broadcast(sync: true);
  final _products = <String, ProductDetails>{};
  final _entitlements = <String, PurchaseEntitlements>{};
  final _unfinished = <String, PurchaseDetails>{};
  final _delivered = <String>{};
  final _deliveryOwners = <String, String>{};
  final _entitlementRevision = <String, int>{};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void> _queue = Future.value();
  bool _disposed = false;
  bool _loading = false;
  bool _busy = false;
  bool _available = false;
  bool _started = false;
  bool _recoveryFailed = false;
  String? _message;

  ApplePurchaseState get state => ApplePurchaseState(
    products: Map.unmodifiable(_products),
    entitlements: Map.unmodifiable(_entitlements),
    loading: _loading,
    busy: _busy,
    available: _available,
    message: _message,
    unfinishedCount: _unfinished.length,
    recoveryFailed: _recoveryFailed,
  );
  Stream<ApplePurchaseState> watch() => Stream.multi((sink) {
    final subscription = _changes.stream.listen(sink.addSync);
    sink.addSync(state);
    sink.onCancel = subscription.cancel;
  });
  void _emit([String? message]) {
    if (_disposed) return;
    _message = message;
    _changes.add(state);
  }

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    if (!supported) {
      _emit('苹果支付仅支持 iOS');
      return;
    }
    try {
      // 先订阅，再查询商品，接收上次启动尚未完成的交易。
      _subscription = gateway.updates.listen(
        _enqueue,
        onError: (Object _) {
          _busy = false;
          _emit('购买状态获取失败，请稍后重试');
        },
      );
      await _recoverUnfinished();
      await reloadProducts();
    } catch (_) {
      _emit('苹果商店连接失败，请稍后重试');
    }
  }

  Future<void> reloadProducts() async {
    if (!supported || _loading || _disposed) return;
    _loading = true;
    _emit();
    try {
      _available = await gateway.isAvailable().timeout(
        const Duration(seconds: 12),
      );
      if (!_available) {
        _emit('当前无法使用苹果支付');
        return;
      }
      for (var attempt = 0; attempt < 3; attempt++) {
        if (_disposed) return;
        try {
          final response = await gateway
              .query(AppleProduct.values.map((p) => p.productId).toSet())
              .timeout(const Duration(seconds: 12));
          final products = <String, ProductDetails>{
            for (final product in response.productDetails)
              if (AppleProduct.find(product.id) != null &&
                  gateway.isConsumable(product))
                product.id: product,
          };
          if (products.isEmpty &&
              (response.error != null || response.productDetails.isEmpty)) {
            throw StateError('苹果商品尚未返回');
          }
          // 仅在查询返回有效结果后替换；短暂网络失败不丢弃本次启动中已获取的商品。
          _products
            ..clear()
            ..addAll(products);
          _emit(
            products.length < AppleProduct.values.length
                ? '部分商品暂不可购买，请稍后刷新'
                : null,
          );
          return;
        } catch (_) {
          if (attempt == 2) rethrow;
          _emit('正在连接苹果商店…');
          await _retryDelay(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    } catch (_) {
      _available = _products.isNotEmpty;
      _emit(_products.isEmpty ? '暂时无法连接苹果商店，请稍后重试' : '商品刷新未完成，可稍后重试');
    } finally {
      _loading = false;
      _emit(_message);
    }
  }

  bool canBuy(AppleProduct product) =>
      supported &&
      fulfillment.isConfigured &&
      currentAccountId() != null &&
      _available &&
      !_loading &&
      !_busy &&
      !_recoveryFailed &&
      _unfinished.isEmpty &&
      _products.containsKey(product.productId);

  Future<void> buy(AppleProduct product) async {
    if (!canBuy(product)) return;
    final accountId = currentAccountId()!;
    _busy = true;
    _emit('正在连接苹果支付');
    try {
      final token = await fulfillment
          .accountToken(accountId)
          .timeout(const Duration(seconds: 20));
      if (_disposed) return;
      if (currentAccountId() != accountId) throw StateError('登录账号已变化');
      if (!RegExp(
        r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
      ).hasMatch(token)) {
        throw StateError('无效账号标识');
      }
      // 返回 true 只代表发起购买，不代表支付或权益发放成功。
      if (!await gateway.buy(_products[product.productId]!, token)) {
        _busy = false;
        _emit('未能发起购买，请重试');
      }
    } catch (_) {
      _busy = false;
      _emit('购买未能发起，请检查账号与网络后重试');
    }
  }

  void _enqueue(List<PurchaseDetails> purchases) {
    _queue = _queue.then((_) async {
      for (final purchase in purchases) {
        if (_disposed) return;
        await _handle(purchase);
      }
    });
  }

  Future<void> _handle(PurchaseDetails purchase) async {
    if (AppleProduct.find(purchase.productID) == null) return;
    if (purchase.status == PurchaseStatus.pending) {
      _busy = true;
      _emit('等待苹果确认付款');
      return;
    }
    if (purchase.status == PurchaseStatus.error ||
        purchase.status == PurchaseStatus.canceled) {
      _busy = false;
      try {
        if (purchase.pendingCompletePurchase) await gateway.complete(purchase);
        _emit(
          purchase.status == PurchaseStatus.canceled ? '已取消购买' : '购买失败，请稍后重试',
        );
      } catch (_) {
        _emit('交易结束处理失败，请稍后重试');
      }
      return;
    }
    final id = purchase.purchaseID;
    if (id == null || id.isEmpty) {
      _busy = false;
      _emit('交易信息不完整，请联系客服核实');
      _unfinished['${purchase.productID}:missing-id'] = purchase;
      _emit(_message);
      return;
    }
    // 不同签名交易（含不同环境/更新后的撤销信息）不能共享内存发放缓存。
    final key =
        '${purchase.productID}:$id:${purchase.verificationData.serverVerificationData}';
    _unfinished[key] = purchase;
    _busy = true;
    _emit('正在确认购买结果');
    try {
      if (!_delivered.contains(key)) {
        final result = await fulfillment
            .verifyAndDeliver(purchase)
            .timeout(const Duration(seconds: 30));
        if (result.accountId.isEmpty || result.coinBalance < 0) {
          throw StateError('无效权益');
        }
        _entitlements[result.accountId] = result;
        _entitlementRevision[result.accountId] =
            (_entitlementRevision[result.accountId] ?? 0) + 1;
        _delivered.add(key);
        _deliveryOwners[key] = result.accountId;
      }
      // 只有已验证并持久化发放，才结束 Apple 交易。
      if (purchase.pendingCompletePurchase) {
        await gateway.complete(purchase).timeout(const Duration(seconds: 20));
      }
      _unfinished.remove(key);
      _emit(
        _deliveryOwners[key] == currentAccountId() ? '购买成功，权益已到账' : '购买已保存至原账号',
      );
    } catch (_) {
      _emit('购买结果待确认，请重试确认或联系客服');
    } finally {
      _busy = false;
      _emit(_message);
    }
  }

  Future<void> retryUnfinished() async {
    if (_busy || _disposed) return;
    _busy = true;
    _emit('正在重新确认购买结果');
    _enqueue(List.of(_unfinished.values));
    await _queue;
    await _recoverUnfinished();
    _busy = false;
    _emit(_message);
  }

  Future<void> _recoverUnfinished() async {
    try {
      final purchases = await gateway.unfinished().timeout(
        const Duration(seconds: 20),
      );
      if (_disposed) return;
      _recoveryFailed = false;
      _enqueue(purchases);
      await _queue;
    } catch (_) {
      _recoveryFailed = true;
      _emit('未完成交易查询失败，请稍后重试');
    }
  }

  Future<void> refreshEntitlements(String accountId) async {
    if (!fulfillment.isConfigured) return;
    final revision = _entitlementRevision[accountId] ?? 0;
    try {
      final result = await fulfillment
          .loadEntitlements(accountId)
          .timeout(const Duration(seconds: 20));
      if (result.accountId != accountId) throw StateError('账号不匹配');
      if (result.coinBalance < 0) throw StateError('无效余额');
      if ((_entitlementRevision[accountId] ?? 0) != revision) return;
      _entitlements[accountId] = result;
      _emit();
    } catch (_) {
      _emit('权益更新失败，请稍后重试');
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
    await _queue;
    await _changes.close();
  }
}
