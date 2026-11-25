import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_app_framework/features/purchases/data/local/purchase_ledger_store.dart';
import 'package:flutter_app_framework/features/purchases/data/model/apple_product.dart';
import 'package:flutter_app_framework/features/purchases/data/repository/local_purchase_fulfillment_repository.dart';
import 'package:flutter_app_framework/features/purchases/data/server/local_apple_transaction_verifier.dart';

class FakeVerifier implements LocalAppleTransactionVerifier {
  String token = '';
  String environment = 'Sandbox';
  bool reject = false;
  @override
  Future<VerifiedAppleTransaction> verify(String id, String product) async {
    if (reject) throw StateError('unverified');
    return VerifiedAppleTransaction(
      transactionId: id,
      productId: product,
      accountToken: token,
      environment: environment,
      purchaseDate: DateTime.utc(2026, 11, 18),
    );
  }
}

PurchaseDetails transaction(AppleProduct product, String id) => PurchaseDetails(
  purchaseID: id,
  productID: product.productId,
  transactionDate: '1',
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: '',
    source: 'app_store',
  ),
  status: PurchaseStatus.purchased,
);

void main() {
  late Directory directory;
  late FakeVerifier verifier;
  late LocalPurchaseFulfillmentRepository repository;
  late DateTime now;
  LocalPurchaseFulfillmentRepository open() =>
      LocalPurchaseFulfillmentRepository(
        PurchaseLedgerStore(directory: () async => directory),
        verifier,
        initialCoins: 0,
        now: () => now,
      );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('apple-local-ledger-');
    verifier = FakeVerifier();
    now = DateTime.utc(2026, 11, 18, 8);
    repository = open();
    verifier.token = await repository.accountToken('A');
  });
  tearDown(() async => directory.delete(recursive: true));

  test('default coins grant once and persist after spending', () async {
    final store = PurchaseLedgerStore(directory: () async => directory);
    final defaults = LocalPurchaseFulfillmentRepository(store, verifier);
    expect((await defaults.loadEntitlements('new')).coinBalance, 10000);
    await store.transaction((ledger) {
      final account = (ledger['accounts'] as Map)['new'] as Map;
      ((account['environments'] as Map)['Production'] as Map)['coins'] = 9972;
    });
    final reopened = LocalPurchaseFulfillmentRepository(
      PurchaseLedgerStore(directory: () async => directory),
      verifier,
    );
    expect((await reopened.loadEntitlements('new')).coinBalance, 9972);
    await store.transaction((ledger) {
      final account = (ledger['accounts'] as Map)['new'] as Map;
      account.remove('initialCoinsGranted');
      ((account['environments'] as Map)['Production'] as Map)['coins'] = 60;
    });
    expect((await reopened.loadEntitlements('new')).coinBalance, 10060);
    expect((await reopened.loadEntitlements('new')).coinBalance, 10060);
  });
  test('payment UUID persists across restart and differs by account', () async {
    expect(await open().accountToken('A'), verifier.token);
    expect(await repository.accountToken('B'), isNot(verifier.token));
    expect(
      verifier.token,
      matches(
        RegExp(
          r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
        ),
      ),
    );
  });
  test(
    'verified coins and transaction ledger persist together across restart',
    () async {
      final result = await repository.verifyAndDeliver(
        transaction(AppleProduct.coins820, 't1'),
      );
      expect(result.coinBalance, 820);
      expect(result.environment, 'Sandbox');
      expect((await open().loadEntitlements('A')).coinBalance, 820);
      await open().verifyAndDeliver(transaction(AppleProduct.coins820, 't1'));
      expect((await open().loadEntitlements('A')).coinBalance, 820);
    },
  );
  test('concurrent duplicate transactions credit only once', () async {
    await Future.wait(
      List.generate(
        8,
        (_) => repository.verifyAndDeliver(
          transaction(AppleProduct.coins320, 'same'),
        ),
      ),
    );
    expect((await repository.loadEntitlements('A')).coinBalance, 320);
  });
  test('different coin purchases accumulate', () async {
    await repository.verifyAndDeliver(transaction(AppleProduct.coins60, 't1'));
    await repository.verifyAndDeliver(transaction(AppleProduct.coins320, 't2'));
    expect((await repository.loadEntitlements('A')).coinBalance, 380);
  });
  test(
    'Dart purchased status without native verification never credits',
    () async {
      verifier.reject = true;
      await expectLater(
        repository.verifyAndDeliver(transaction(AppleProduct.coins820, 't1')),
        throwsStateError,
      );
      expect((await repository.loadEntitlements('A')).coinBalance, 0);
    },
  );
  test('unknown account token cannot claim transaction', () async {
    verifier.token = 'unknown-token';
    await expectLater(
      repository.verifyAndDeliver(transaction(AppleProduct.coins820, 't1')),
      throwsStateError,
    );
    expect((await repository.loadEntitlements('A')).coinBalance, 0);
  });
  test(
    'late transaction is bound to original account, not last opened account',
    () async {
      await repository.accountToken('B');
      final result = await repository.verifyAndDeliver(
        transaction(AppleProduct.coins60, 't1'),
      );
      expect(result.accountId, 'A');
      expect((await repository.loadEntitlements('B')).coinBalance, 0);
    },
  );
  test(
    'Sandbox and Production transactions with same ID do not share balance',
    () async {
      await repository.verifyAndDeliver(
        transaction(AppleProduct.coins820, 'same'),
      );
      verifier.environment = 'Production';
      final production = await repository.verifyAndDeliver(
        transaction(AppleProduct.coins60, 'same'),
      );
      expect(production.coinBalance, 60);
      expect(production.environment, 'Production');
      verifier.environment = 'Sandbox';
      final sandbox = await repository.verifyAndDeliver(
        transaction(AppleProduct.coins820, 'same'),
      );
      expect(sandbox.coinBalance, 820);
    },
  );
  test('membership starts now, stacks calendar months and persists', () async {
    await repository.verifyAndDeliver(transaction(AppleProduct.vip1, 'v1'));
    final result = await repository.verifyAndDeliver(
      transaction(AppleProduct.vip3, 'v2'),
    );
    expect(result.vipExpiresAt, DateTime.utc(2027, 3, 18, 8));
    expect(
      (await open().loadEntitlements('A')).vipExpiresAt,
      result.vipExpiresAt,
    );
    await open().verifyAndDeliver(transaction(AppleProduct.vip3, 'v2'));
    expect(
      (await open().loadEntitlements('A')).vipExpiresAt,
      result.vipExpiresAt,
    );
  });
  test(
    'expired membership starts at current time and month-end clamps',
    () async {
      now = DateTime.utc(2027, 1, 31, 8);
      var result = await repository.verifyAndDeliver(
        transaction(AppleProduct.vip1, 'v1'),
      );
      expect(result.vipExpiresAt, DateTime.utc(2027, 2, 28, 8));
      now = DateTime.utc(2028, 1, 31, 8);
      result = await repository.verifyAndDeliver(
        transaction(AppleProduct.vip1, 'v2'),
      );
      expect(result.vipExpiresAt, DateTime.utc(2028, 2, 29, 8));
    },
  );
  test('corrupt ledger is not silently reset or overwritten', () async {
    final file = File('${directory.path}/purchases/apple_ledger.json');
    await file.writeAsString('broken-json');
    await expectLater(repository.accountToken('A'), throwsFormatException);
    expect(await file.readAsString(), 'broken-json');
  });
  test(
    'failed grant write leaves old balance and can retry exactly once',
    () async {
      final blocked = Directory(
        '${directory.path}/purchases/apple_ledger.json.tmp',
      );
      await blocked.create();
      await expectLater(
        repository.verifyAndDeliver(transaction(AppleProduct.coins60, 't1')),
        throwsA(isA<FileSystemException>()),
      );
      await blocked.delete();
      expect((await open().loadEntitlements('A')).coinBalance, 0);
      await repository.verifyAndDeliver(
        transaction(AppleProduct.coins60, 't1'),
      );
      expect((await open().loadEntitlements('A')).coinBalance, 60);
    },
  );
}
