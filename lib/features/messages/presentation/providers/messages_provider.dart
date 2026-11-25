import '../../../user/presentation/providers/growth_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../purchases/presentation/providers/apple_purchase_provider.dart';
import '../../data/repository/chat_gift_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/mock_json_store.dart';
import '../../data/messages_repository.dart';

export '../../data/messages_repository.dart' show MessagesState;

final messagesRepositoryProvider = Provider<MessagesRepository>(
  (ref) => MessagesMockRepository(ref.watch(mockJsonStoreProvider)),
);
final chatGiftRepositoryProvider = Provider<ChatGiftRepository>(
  (ref) => ChatGiftRepository(ref.watch(purchaseLedgerStoreProvider)),
);
final messagesInitialProvider = FutureProvider<MessagesState>((ref) async {
  final repository = ref.watch(messagesRepositoryProvider);
  final gifts = ref.watch(chatGiftRepositoryProvider);
  final accountId = ref.watch(authSessionProvider).value?.accountId;
  final loaded = await repository.load();
  return accountId == null ? loaded : gifts.restore(accountId, loaded);
});
final messagesProvider = NotifierProvider<MessagesNotifier, MessagesState>(
  MessagesNotifier.new,
);

class MessagesNotifier extends Notifier<MessagesState> {
  @override
  MessagesState build() {
    final repository = ref.watch(messagesRepositoryProvider);
    listenSelf((previous, next) {
      if (previous != null) {
        final growth = ref.read(growthRepositoryProvider);
        ref.read(mockWritesProvider.notifier).save('messages', () async {
          await repository.save(next);
          final oldCount = previous.threads.fold<int>(
            0,
            (n, t) => n + t.entries.where((e) => e.isMine).length,
          );
          final newCount = next.threads.fold<int>(
            0,
            (n, t) => n + t.entries.where((e) => e.isMine).length,
          );
          if (newCount > oldCount) {
            try {
              await growth.recordChat();
              if (ref.mounted) ref.invalidate(growthProvider);
            } catch (_) {
              // 消息已落盘，任务记录失败不回滚消息。
            }
          }
        });
      }
    });
    return ref.watch(messagesInitialProvider).requireValue;
  }

  Future<void> reload() async {
    final loaded = await ref.read(messagesRepositoryProvider).load();
    if (ref.mounted) state = loaded;
  }

  void setRemark(String id, String remark) => state = state.copyWith(
    threads: List.unmodifiable(
      state.threads.map(
        (thread) =>
            thread.id == id ? thread.copyWith(remark: remark.trim()) : thread,
      ),
    ),
  );

  void readThread(String id) => state = state.copyWith(
    threads: List.unmodifiable(
      state.threads.map(
        (thread) => thread.id == id ? thread.copyWith(unread: 0) : thread,
      ),
    ),
  );

  void readNotice(MessageNotice notice) => state = state.copyWith(
    readNotices: Set.unmodifiable({...state.readNotices, notice}),
  );

  void send(String id, ChatEntry entry) {
    if (entry.content.trim().isEmpty) return;
    final index = state.threads.indexWhere((thread) => thread.id == id);
    if (index < 0) return;
    if (entry.idempotencyKey != null &&
        state.threads[index].entries.any(
          (e) => e.idempotencyKey == entry.idempotencyKey,
        )) {
      return;
    }
    final threads = [...state.threads];
    final thread = threads.removeAt(index);
    threads.insert(
      0,
      thread.copyWith(
        entries: List.unmodifiable([...thread.entries, entry]),
        unread: 0,
        time: '刚刚',
      ),
    );
    state = state.copyWith(threads: List.unmodifiable(threads));
  }

  /// 打开已存在的私信，或为真实对端创建一个空会话。
  String? openConversation(String peerId, String name, String avatar) {
    final id = peerId.trim();
    if (id.isEmpty ||
        isBlocked(id) ||
        state.blocked.values.any(
          (thread) =>
              thread.peerId == null &&
              thread.name == name &&
              thread.avatar == avatar,
        )) {
      return null;
    }
    final existing = state.threads
        .where((thread) => thread.peerId == id || thread.id == id)
        .firstOrNull;
    if (existing != null) return existing.id;
    // 旧版打招呼会话仅通过昵称命名，精确匹配后迁移其对端 ID。
    final legacy = state.threads
        .where(
          (thread) =>
              thread.peerId == null &&
              thread.name == name &&
              thread.avatar == avatar,
        )
        .firstOrNull;
    if (legacy != null) {
      state = state.copyWith(
        threads: [
          for (final thread in state.threads)
            if (thread.id == legacy.id) thread.copyWith(peerId: id) else thread,
        ],
      );
      return legacy.id;
    }
    final thread = MessageThread(
      id: 'peer-$id',
      peerId: id,
      name: name,
      avatar: avatar,
      entries: const [],
      time: '',
    );
    state = state.copyWith(threads: [thread, ...state.threads]);
    return thread.id;
  }

  bool isBlocked(String id) => state.blocked.values.any(
    (thread) => thread.peerId == id || thread.id == id,
  );

  String? greet(String author, String avatar, {String? peerId}) {
    const greeting = ChatEntry('你好，很高兴认识你！', isMine: true);
    if (peerId != null) {
      final id = openConversation(peerId, author, avatar);
      if (id == null) return null;
      send(id, greeting);
      return id;
    }
    final blocked = state.blocked.values
        .where((thread) => thread.name == author && thread.avatar == avatar)
        .firstOrNull;
    if (blocked != null) return null;
    final existing = state.threads
        .where((thread) => thread.name == author && thread.avatar == avatar)
        .firstOrNull;
    final id = existing?.id ?? 'greeting-$author';
    if (existing == null) {
      state = state.copyWith(
        threads: List.unmodifiable([
          MessageThread(
            id: id,
            name: author,
            avatar: avatar,
            entries: const [greeting],
            time: '刚刚',
          ),
          ...state.threads,
        ]),
      );
    } else {
      send(id, greeting);
    }
    return id;
  }

  void block(MessageThread thread) => state = state.copyWith(
    threads: List.unmodifiable(
      state.threads.where((item) => item.id != thread.id),
    ),
    blocked: Map.unmodifiable({...state.blocked, thread.id: thread}),
  );

  /// 记录对当前会话提交的举报。
  void report(String threadId, String reason) {
    state = state.copyWith(
      reports: List.unmodifiable([
        ...state.reports,
        (
          threadId: threadId,
          reason: reason,
          submittedAt: DateTime.now().toIso8601String(),
        ),
      ]),
    );
  }

  /// 从动态入口拉黑作者，复用消息模块的黑名单记录。
  void blockAuthor(String id, String name, String avatar) {
    final thread = state.threads
        .where(
          (item) =>
              item.peerId == id ||
              item.id == id ||
              (item.peerId == null &&
                  item.name == name &&
                  item.avatar == avatar),
        )
        .firstOrNull;
    block(
      thread?.copyWith(peerId: id) ??
          MessageThread(
            id: id,
            peerId: id,
            name: name,
            avatar: avatar,
            entries: const [],
          ),
    );
  }

  void unblock(String id) {
    final thread = state.blocked[id];
    if (thread == null) return;
    state = state.copyWith(
      blocked: Map.unmodifiable({...state.blocked}..remove(id)),
      threads: List.unmodifiable([...state.threads, thread]),
    );
  }
}
