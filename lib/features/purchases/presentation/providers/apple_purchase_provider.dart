import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repository/purchase_fulfillment_repository.dart';
import '../../data/repository/local_purchase_fulfillment_repository.dart';
import '../../data/local/purchase_ledger_store.dart';
import '../../data/server/local_apple_transaction_verifier.dart';
import '../../data/server/apple_purchase_gateway.dart';
import 'apple_purchase_controller.dart';

final purchaseLedgerStoreProvider = Provider<PurchaseLedgerStore>(
  (ref) => PurchaseLedgerStore(),
);
final localAppleTransactionVerifierProvider =
    Provider<LocalAppleTransactionVerifier>(
      (ref) => StoreKitLocalTransactionVerifier(),
    );
final purchaseFulfillmentProvider = Provider<PurchaseFulfillmentRepository>(
  (ref) => kIsWeb || defaultTargetPlatform != TargetPlatform.iOS
      ? const UnavailablePurchaseFulfillment()
      : LocalPurchaseFulfillmentRepository(
          ref.watch(purchaseLedgerStoreProvider),
          ref.watch(localAppleTransactionVerifierProvider),
        ),
);
final applePurchaseGatewayProvider = Provider<ApplePurchaseGateway>(
  (ref) => StoreKitPurchaseGateway(),
);
final applePurchaseControllerProvider = Provider<ApplePurchaseController>((
  ref,
) {
  final controller = ApplePurchaseController(
    gateway: ref.watch(applePurchaseGatewayProvider),
    fulfillment: ref.watch(purchaseFulfillmentProvider),
    currentAccountId: () => ref.read(authSessionProvider).value?.accountId,
    supported: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS,
  );
  ref.listen(authSessionProvider, (_, next) {
    final id = next.value?.accountId;
    if (id != null) unawaited(controller.refreshEntitlements(id));
  }, fireImmediately: true);
  unawaited(controller.start());
  ref.onDispose(() => unawaited(controller.dispose()));
  return controller;
});
final applePurchaseStateProvider = StreamProvider<ApplePurchaseState>(
  (ref) => ref.watch(applePurchaseControllerProvider).watch(),
);
