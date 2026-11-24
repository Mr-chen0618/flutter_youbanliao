import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/features/messages/data/repository/chat_gift_repository.dart';
import 'package:flutter_app_framework/features/messages/data/messages_repository.dart';
import 'package:flutter_app_framework/features/purchases/data/local/purchase_ledger_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late PurchaseLedgerStore store;
  late ChatGiftRepository gifts;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('chat-gifts-');
    store = PurchaseLedgerStore(directory: () async => directory);
    gifts = ChatGiftRepository(store);
    await store.transaction((ledger) {
      (ledger['accounts'] as Map)['alice'] = {
        'activeEnvironment': 'Sandbox',
        'environments': {
          'Sandbox': {'coins': 1000},
          'Production': {'coins': 80},
        },
      };
    });
  });
  tearDown(() => directory.delete(recursive: true));
  test('catalog uses the eight supplied names and valid assets', () async {
    final catalog = await gifts.catalog();
    expect(catalog.map((g) => g.name), [
      '冰可乐',
      '幸运星',
      '笔芯',
      '彩虹桥',
      '扎啤',
      '幸运锦鲤',
      '泰迪熊',
      '玫瑰花',
    ]);
    for (final gift in catalog) {
      expect(await File(gift.asset).length(), greaterThan(0));
    }
  });
  test(
    'atomic debit, duplicate request, account/environment isolation and restart recovery',
    () async {
      final gift = (await gifts.catalog()).first;
      final entry = await gifts.send(
        accountId: 'alice',
        requestId: 'one',
        threadId: 'peer',
        gift: gift,
        quantity: 10,
      );
      await gifts.send(
        accountId: 'alice',
        requestId: 'one',
        threadId: 'peer',
        gift: gift,
        quantity: 10,
      );
      expect(ChatEntry.fromJson(entry.toJson()).giftQuantity, 10);
      await store.transaction((ledger) {
        final wallets =
            ((ledger['accounts'] as Map)['alice'] as Map)['environments']
                as Map;
        expect((wallets['Sandbox'] as Map)['coins'], 720);
        expect((wallets['Production'] as Map)['coins'], 80);
      });
      final restarted = ChatGiftRepository(
        PurchaseLedgerStore(directory: () async => directory),
      );
      final state = const MessagesState([
        MessageThread(id: 'peer', name: 'Peer', avatar: '', entries: []),
      ]);
      final restored = await restarted.restore('alice', state);
      expect(restored.threads.single.entries.single.gift!.name, '冰可乐');
      expect(
        (await restarted.restore(
          'alice',
          restored,
        )).threads.single.entries.length,
        1,
      );
      expect(
        (await restarted.restore('bob', state)).threads.single.entries,
        isEmpty,
      );
    },
  );
  test(
    'insufficient funds and invalid quantities leave ledger unchanged',
    () async {
      final gift = (await gifts.catalog()).first;
      for (final quantity in [0, -1, 1315, 100]) {
        await expectLater(
          gifts.send(
            accountId: 'alice',
            requestId: '$quantity',
            threadId: 'peer',
            gift: gift,
            quantity: quantity,
          ),
          throwsStateError,
        );
      }
      await expectLater(
        gifts.send(
          accountId: 'bob',
          requestId: 'bob',
          threadId: 'peer',
          gift: gift,
          quantity: 1,
        ),
        throwsStateError,
      );
      await store.transaction((ledger) {
        expect(
          (((ledger['accounts'] as Map)['alice'] as Map)['environments']
              as Map)['Sandbox']['coins'],
          1000,
        );
        expect(ledger['chatGifts'], isNull);
      });
    },
  );
  test('concurrent sends cannot overspend', () async {
    final gift = (await gifts.catalog()).first;
    final results = await Future.wait(
      List.generate(2, (i) async {
        try {
          await gifts.send(
            accountId: 'alice',
            requestId: '$i',
            threadId: 'peer',
            gift: gift,
            quantity: 30,
          );
          return true;
        } on StateError {
          return false;
        }
      }),
    );
    expect(results.where((r) => r).length, 1);
  });
}
