import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app_framework/features/auth/data/model/auth_session.dart';
import 'package:flutter_app_framework/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_app_framework/features/purchases/presentation/providers/apple_purchase_provider.dart';
import 'package:flutter_app_framework/features/user/presentation/pages/profile_shop_page.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_app_framework/features/purchases/data/model/apple_product.dart';
import 'package:flutter_app_framework/features/purchases/data/repository/purchase_fulfillment_repository.dart';
import 'package:flutter_app_framework/features/purchases/data/server/apple_purchase_gateway.dart';
import 'package:flutter_app_framework/features/purchases/presentation/providers/apple_purchase_controller.dart';

const serverToken = '9b73ea44-cf23-43ba-902b-c1c8434dd0f3';
ProductDetails detail(AppleProduct p) => ProductDetails(
  id: p.productId,
  title: p.name,
  description: p.name,
  price: p == AppleProduct.coins820 ? 'HK\$88.00' : '¥${p.previewPrice}',
  rawPrice: p.previewPrice.toDouble(),
  currencyCode: 'CNY',
);
PurchaseDetails purchase({
  String? id = 'tx1',
  PurchaseStatus status = PurchaseStatus.purchased,
  AppleProduct product = AppleProduct.coins60,
}) => PurchaseDetails(
  purchaseID: id,
  productID: product.productId,
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: 'signed-jws',
    source: 'app_store',
  ),
  transactionDate: '1',
  status: status,
)..pendingCompletePurchase = status != PurchaseStatus.pending;

class FakeGateway implements ApplePurchaseGateway {
  final stream = StreamController<List<PurchaseDetails>>.broadcast(sync: true);
  final completions = <String?>[];
  Set<String> queried = {};
  int queryFailures = 0;
  int queryCalls = 0;
  String? boughtId;
  String? boughtToken;
  bool available = true;
  bool failComplete = false;
  bool buyResult = true;
  bool wrongType = false;
  List<ProductDetails>? results;
  List<PurchaseDetails> previous = [];
  @override
  Stream<List<PurchaseDetails>> get updates => stream.stream;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<ProductDetailsResponse> query(Set<String> ids) async {
    queried = ids;
    queryCalls++;
    if (queryFailures-- > 0) throw StateError('transient store error');
    return ProductDetailsResponse(
      productDetails: results ?? AppleProduct.values.map(detail).toList(),
      notFoundIDs: [],
    );
  }

  @override
  Future<List<PurchaseDetails>> unfinished() async => List.of(previous);
  @override
  bool isConsumable(ProductDetails product) => !wrongType;
  @override
  Future<bool> buy(ProductDetails product, String token) async {
    boughtId = product.id;
    boughtToken = token;
    return buyResult;
  }

  @override
  Future<void> complete(PurchaseDetails p) async {
    if (failComplete) throw StateError('offline');
    completions.add(p.purchaseID);
    previous.removeWhere((old) => old.purchaseID == p.purchaseID);
  }

  Future<void> send(PurchaseDetails p) async {
    stream.add([p]);
    await Future<void>.delayed(Duration.zero);
  }
}

class FakeFulfillment implements PurchaseFulfillmentRepository {
  bool configured = true;
  bool fail = false;
  int deliveries = 0;
  Completer<String>? tokenWait;
  Completer<PurchaseEntitlements>? loadWait;
  @override
  bool get isConfigured => configured;
  @override
  Future<String> accountToken(String id) async =>
      tokenWait == null ? serverToken : await tokenWait!.future;
  @override
  Future<PurchaseEntitlements> loadEntitlements(String id) async =>
      loadWait == null
      ? PurchaseEntitlements(accountId: id, coinBalance: 0)
      : await loadWait!.future;
  @override
  Future<PurchaseEntitlements> verifyAndDeliver(
    PurchaseDetails purchase,
  ) async {
    if (fail) throw StateError('verification failed');
    deliveries++;
    return const PurchaseEntitlements(accountId: 'A', coinBalance: 60);
  }
}

void main() {
  late FakeGateway gateway;
  late FakeFulfillment backend;
  late ApplePurchaseController controller;
  String? active;
  setUp(() {
    gateway = FakeGateway();
    backend = FakeFulfillment();
    active = 'A';
    controller = ApplePurchaseController(
      gateway: gateway,
      fulfillment: backend,
      currentAccountId: () => active,
      supported: true,
      retryDelay: (_) async {},
    );
  });
  tearDown(() async {
    await controller.dispose();
    await gateway.stream.close();
  });
  test(
    'catalog queries all six exact product IDs and preserves StoreKit price',
    () async {
      await controller.start();
      expect(gateway.queried, {
        'youbanliao.coins.60',
        'youbanliao.coins.320',
        'youbanliao.coins.820',
        'youbanliao.vip.1month',
        'youbanliao.vip.3months',
        'youbanliao.vip.12months',
      });
      expect(
        controller.state.products[AppleProduct.coins820.productId]!.price,
        'HK\$88.00',
      );
      expect(AppleProduct.coins820.previewPrice, 80);
    },
  );
  test(
    'missing products and wrong StoreKit product type cannot be bought',
    () async {
      gateway.results = [detail(AppleProduct.coins60)];
      await controller.start();
      expect(controller.canBuy(AppleProduct.coins820), isFalse);
      gateway.wrongType = true;
      await controller.reloadProducts();
      expect(controller.canBuy(AppleProduct.coins60), isFalse);
    },
  );
  test('no backend or no signed-in account cannot open payment', () async {
    backend.configured = false;
    await controller.start();
    await controller.buy(AppleProduct.coins60);
    expect(gateway.boughtId, isNull);
    backend.configured = true;
    active = null;
    expect(controller.canBuy(AppleProduct.coins60), isFalse);
  });
  test('unavailable store never sends purchase', () async {
    gateway.available = false;
    await controller.start();
    await controller.buy(AppleProduct.coins60);
    expect(gateway.boughtId, isNull);
  });
  test(
    'membership uses consumable flow with server UUID and waits for callback',
    () async {
      await controller.start();
      await controller.buy(AppleProduct.vip12);
      expect(gateway.boughtId, 'youbanliao.vip.12months');
      expect(gateway.boughtToken, serverToken);
      expect(controller.state.busy, isTrue);
      expect(backend.deliveries, 0);
      await controller.buy(AppleProduct.coins60);
      expect(gateway.boughtId, 'youbanliao.vip.12months');
      await gateway.send(purchase(status: PurchaseStatus.canceled));
      expect(controller.state.busy, isFalse);
      expect(backend.deliveries, 0);
    },
  );
  test('failed purchase start releases button lock', () async {
    gateway.buyResult = false;
    await controller.start();
    await controller.buy(AppleProduct.coins60);
    expect(controller.state.busy, isFalse);
  });
  test('switching accounts during account token fetch stops payment', () async {
    backend.tokenWait = Completer();
    await controller.start();
    final buying = controller.buy(AppleProduct.coins60);
    active = 'B';
    backend.tokenWait!.complete(serverToken);
    await buying;
    expect(gateway.boughtId, isNull);
  });
  test('pending and errors do not deliver credits', () async {
    await controller.start();
    await gateway.send(purchase(status: PurchaseStatus.pending));
    expect(controller.state.busy, isTrue);
    expect(gateway.completions, isEmpty);
    await gateway.send(purchase(status: PurchaseStatus.error));
    expect(controller.state.busy, isFalse);
    expect(backend.deliveries, 0);
  });
  test(
    'verification failure keeps transaction unfinished and retry delivers once',
    () async {
      backend.fail = true;
      await controller.start();
      await gateway.send(purchase());
      expect(gateway.completions, isEmpty);
      expect(controller.state.unfinishedCount, 1);
      expect(controller.canBuy(AppleProduct.coins60), isFalse);
      backend.fail = false;
      await controller.retryUnfinished();
      expect(backend.deliveries, 1);
      expect(gateway.completions, ['tx1']);
      expect(controller.state.unfinishedCount, 0);
    },
  );
  test(
    'duplicate callbacks and finish retry never redeliver in same launch',
    () async {
      gateway.failComplete = true;
      await controller.start();
      await gateway.send(purchase());
      expect(backend.deliveries, 1);
      expect(controller.state.unfinishedCount, 1);
      gateway.failComplete = false;
      await controller.retryUnfinished();
      await gateway.send(purchase());
      expect(backend.deliveries, 1);
      expect(controller.state.unfinishedCount, 0);
    },
  );
  test(
    'startup queries unfinished StoreKit transactions without a shop page',
    () async {
      gateway.previous = [purchase()];
      await controller.start();
      expect(backend.deliveries, 1);
      expect(gateway.completions, ['tx1']);
    },
  );
  test(
    'late transaction after account switch updates only original account',
    () async {
      await controller.start();
      active = 'B';
      await gateway.send(purchase());
      expect(controller.state.entitlements['A']!.coinBalance, 60);
      expect(controller.state.entitlements['B'], isNull);
    },
  );
  test(
    'slow entitlement fetch cannot overwrite a newly delivered balance',
    () async {
      await controller.start();
      backend.loadWait = Completer();
      final loading = controller.refreshEntitlements('A');
      await gateway.send(purchase());
      backend.loadWait!.complete(
        const PurchaseEntitlements(accountId: 'A', coinBalance: 0),
      );
      await loading;
      expect(controller.state.entitlements['A']!.coinBalance, 60);
    },
  );
  test(
    'transient Apple query failure retries and returns real products',
    () async {
      gateway.queryFailures = 1;
      await controller.start();
      expect(gateway.queryCalls, 2);
      expect(controller.canBuy(AppleProduct.coins60), isTrue);
      expect(controller.state.message, isNull);
    },
  );
  test('failed refresh keeps products already obtained from Apple', () async {
    await controller.start();
    gateway.queryFailures = 3;
    await controller.reloadProducts();
    expect(gateway.queryCalls, 4);
    expect(controller.canBuy(AppleProduct.coins820), isTrue);
    await controller.buy(AppleProduct.coins820);
    expect(gateway.boughtId, 'youbanliao.coins.820');
  });
  test('failed cold query cannot buy; later refresh recovers', () async {
    gateway.queryFailures = 3;
    await controller.start();
    expect(controller.state.products, isEmpty);
    expect(controller.canBuy(AppleProduct.coins60), isFalse);
    await controller.reloadProducts();
    expect(controller.canBuy(AppleProduct.coins60), isTrue);
  });
  testWidgets('coin page displays Apple price and submits selected product', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(controller.start);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          applePurchaseControllerProvider.overrideWithValue(controller),
          authSessionProvider.overrideWith(
            (ref) async => const AuthSession('A', profileCompleted: true),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) =>
              const MaterialApp(home: CoinRechargePage(balance: 0)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(gateway.queryCalls, greaterThanOrEqualTo(2));
    expect(find.text('HK\$88.00'), findsOneWidget);
    expect(find.text('¥80'), findsNothing);
    await tester.tap(find.text('HK\$88.00'));
    await tester.pump();
    await tester.tap(find.text('立即充值'));
    await tester.pumpAndSettle();
    expect(gateway.boughtId, 'youbanliao.coins.820');
    expect(find.text('处理中…'), findsOneWidget);
    await tester.runAsync(
      () => gateway.send(purchase(status: PurchaseStatus.canceled)),
    );
    await tester.pumpAndSettle();
    expect(find.text('已取消购买'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
