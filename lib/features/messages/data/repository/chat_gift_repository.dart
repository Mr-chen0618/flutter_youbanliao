import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../purchases/data/local/purchase_ledger_store.dart';
import '../model/chat_gift.dart';
import '../messages_repository.dart';

/// 扣款与消息凭据在支付账本中一次提交；聊天快照可从凭据幂等恢复。
class ChatGiftRepository {
  ChatGiftRepository(this.store);
  final PurchaseLedgerStore store;
  Future<List<ChatGift>> catalog() async {
    final json =
        jsonDecode(
              await rootBundle.loadString('assets/mock/messages/gifts.json'),
            )
            as Map;
    return (json['gifts'] as List)
        .map((e) => ChatGift.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ChatEntry> send({
    required String accountId,
    required String requestId,
    required String threadId,
    required ChatGift gift,
    required int quantity,
  }) async {
    final products = await catalog();
    final product = products.where((p) => p.id == gift.id).firstOrNull;
    if (accountId.isEmpty ||
        product == null ||
        quantity < 1 ||
        quantity > 1314) {
      throw StateError('礼物或数量无效');
    }
    return store.transaction((ledger) {
      final records =
          ledger.putIfAbsent('chatGifts', () => <String, dynamic>{}) as Map;
      final key = '$accountId:$requestId';
      if (records[key] case final Map previous) {
        if (previous['threadId'] != threadId) throw StateError('赠送记录不一致');
        return ChatEntry.fromJson(
          Map<String, dynamic>.from(previous['entry'] as Map),
        );
      }
      final account = (ledger['accounts'] as Map)[accountId] as Map?;
      final environment = account?['activeEnvironment'];
      final wallet = (account?['environments'] as Map?)?[environment] as Map?;
      final balance = wallet?['coins'] as int? ?? 0;
      final cost = product.coins * quantity;
      if (balance < cost) throw StateError('金币不足，请先充值');
      final entry = ChatEntry(
        '${product.name}x$quantity',
        isMine: true,
        kind: ChatEntryKind.gift,
        gift: product,
        giftQuantity: quantity,
        idempotencyKey: key,
      );
      wallet!['coins'] = balance - cost;
      records[key] = {
        'accountId': accountId,
        'environment': environment,
        'threadId': threadId,
        'cost': cost,
        'entry': entry.toJson(),
      };
      return entry;
    });
  }

  Future<MessagesState> restore(String accountId, MessagesState state) =>
      store.transaction((ledger) {
        final records = (ledger['chatGifts'] as Map? ?? {}).values
            .whereType<Map>()
            .where((r) => r['accountId'] == accountId);
        MessageThread merge(MessageThread thread) {
          final entries = [...thread.entries];
          for (final r in records.where((r) => r['threadId'] == thread.id)) {
            final entry = ChatEntry.fromJson(
              Map<String, dynamic>.from(r['entry'] as Map),
            );
            if (!entries.any((e) => e.idempotencyKey == entry.idempotencyKey)) {
              entries.add(entry);
            }
          }
          return entries.length == thread.entries.length
              ? thread
              : thread.copyWith(entries: entries);
        }

        return state.copyWith(
          threads: state.threads.map(merge).toList(),
          blocked: state.blocked.map((k, v) => MapEntry(k, merge(v))),
        );
      });
}
