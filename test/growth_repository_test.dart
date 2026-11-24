import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/user/data/repository/growth_repository.dart';
import 'package:flutter_app_framework/features/purchases/data/local/purchase_ledger_store.dart';

void main() {
  test('签到重试不重复发币，账户隔离且重启恢复', () async {
    final dir = await Directory.systemTemp.createTemp('growth-test');
    addTearDown(() => dir.delete(recursive: true));
    final store = MockJsonStore(directory: () async => dir);
    final ledger = PurchaseLedgerStore(directory: () async => dir);
    await ledger.transaction((root) {
      for (final id in ['a', 'b']) {
        (root['accounts'] as Map)[id] = {
          'activeEnvironment': 'Production',
          'environments': {
            'Production': {'coins': 0},
          },
        };
      }
    });
    final a = GrowthRepository(store, ledger, 'a');
    final day = DateTime(2026, 11, 23);
    await Future.wait([a.checkIn(day), a.checkIn(day)]);
    expect((await a.load())['checks'], ['2026-11-23']);
    await ledger.transaction((r) {
      expect(
        ((r['accounts'] as Map)['a']['environments']['Production']['coins']),
        1,
      );
      expect(
        ((r['accounts'] as Map)['b']['environments']['Production']['coins']),
        0,
      );
    });
    final restored = GrowthRepository(
      store,
      PurchaseLedgerStore(directory: () async => dir),
      'a',
    );
    await restored.checkIn(day);
    expect((await restored.load())['checks'], hasLength(1));
    await expectLater(restored.claimDaily('chat', day), throwsStateError);
    await restored.set('chatDay', '2026-11-23');
    await restored.claimDaily('chat', day);
    await restored.claimDaily('chat', day);
    await ledger.transaction((r) {
      expect(
        (r['accounts'] as Map)['a']['environments']['Production']['coins'],
        11,
      );
    });
  });
}
