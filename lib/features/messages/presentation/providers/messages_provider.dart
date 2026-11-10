import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/mock_json_store.dart';
import '../../data/messages_repository.dart';

export '../../data/messages_repository.dart' show MessagesState;

final messagesRepositoryProvider = Provider<MessagesRepository>(
  (ref) => MessagesMockRepository(ref.watch(mockJsonStoreProvider)),
);
final messagesInitialProvider = FutureProvider<MessagesState>(
  (ref) => ref.watch(messagesRepositoryProvider).load(),
);
final messagesProvider = NotifierProvider<MessagesNotifier, MessagesState>(
  MessagesNotifier.new,
);

class MessagesNotifier extends Notifier<MessagesState> {
  @override
  MessagesState build() {
    final repository = ref.watch(messagesRepositoryProvider);
    listenSelf((previous, next) {
      if (previous != null) {
        ref
            .read(mockWritesProvider.notifier)
            .save('messages', () => repository.save(next));
      }
    });
    return ref.watch(messagesInitialProvider).requireValue;
  }

  Future<void> reload() async {
    final loaded = await ref.read(messagesRepositoryProvider).load();
    if (ref.mounted) state = loaded;
  }

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

  String greet(String author, String avatar) {
    final existing = state.threads
        .where((thread) => thread.name == author)
        .firstOrNull;
    final blocked = state.blocked.values
        .where((thread) => thread.name == author)
        .firstOrNull;
    if (blocked != null) return blocked.id;
    final id = existing?.id ?? 'greeting-$author';
    const greeting = ChatEntry('你好，很高兴认识你！', isMine: true);
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
        .where((item) => item.id == id || item.name == name)
        .firstOrNull;
    block(
      thread ??
          MessageThread(id: id, name: name, avatar: avatar, entries: const []),
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
