import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/messages/data/messages_repository.dart';
import 'package:flutter_app_framework/features/messages/presentation/providers/messages_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_json_test_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerFor(MessagesState state) async {
    final store = await WidgetMockJsonStore.load();
    final container = ProviderContainer(
      overrides: [
        mockJsonStoreProvider.overrideWithValue(store),
        messagesInitialProvider.overrideWith((ref) async => state),
      ],
    );
    await container.read(messagesInitialProvider.future);
    addTearDown(container.dispose);
    return container;
  }

  test(
    'private message reuses peer identity without adding greetings',
    () async {
      final container = await containerFor(const MessagesState([]));
      final notifier = container.read(messagesProvider.notifier);
      final first = notifier.openConversation('U020', '同名用户', 'avatar-a');
      final reopened = notifier.openConversation('U020', '改名用户', 'avatar-b');
      final other = notifier.openConversation('U021', '同名用户', 'avatar-a');
      expect(first, reopened);
      expect(other, isNot(first));
      final threads = container.read(messagesProvider).threads;
      expect(threads, hasLength(2));
      expect(threads.every((thread) => thread.entries.isEmpty), isTrue);
      await Future<void>.delayed(Duration.zero);
    },
  );

  test(
    'legacy chat is migrated once and retains messages when unblocked',
    () async {
      const original = MessageThread(
        id: 'greeting-旧会话',
        name: '旧会话',
        avatar: 'avatar-a',
        entries: [ChatEntry('历史消息')],
      );
      final container = await containerFor(const MessagesState([original]));
      final notifier = container.read(messagesProvider.notifier);
      final id = notifier.openConversation(
        'U020',
        original.name,
        original.avatar,
      );
      expect(id, original.id);
      final migrated = container.read(messagesProvider).threads.single;
      expect(migrated.peerId, 'U020');
      expect(migrated.entries.single.content, '历史消息');
      notifier.block(migrated);
      expect(notifier.openConversation('U020', '已改名', 'avatar-b'), isNull);
      expect(container.read(messagesProvider).threads, isEmpty);
      notifier.unblock(id!);
      expect(
        container.read(messagesProvider).threads.single.entries.single.content,
        '历史消息',
      );
      expect(notifier.openConversation('U020', '已改名', 'avatar-b'), id);
      await Future<void>.delayed(Duration.zero);
    },
  );

  test(
    'legacy blocked identity cannot create a replacement conversation',
    () async {
      const blocked = MessageThread(
        id: 'legacy-blocked',
        name: '旧拉黑用户',
        avatar: 'avatar-a',
        entries: [],
      );
      final container = await containerFor(
        const MessagesState([], blocked: {'legacy-blocked': blocked}),
      );
      final notifier = container.read(messagesProvider.notifier);
      expect(
        notifier.openConversation('U020', blocked.name, blocked.avatar),
        isNull,
      );
      expect(container.read(messagesProvider).threads, isEmpty);
    },
  );

  test(
    'greeting reuses the same peer conversation and respects blocking',
    () async {
      final container = await containerFor(const MessagesState([]));
      final notifier = container.read(messagesProvider.notifier);
      final id = notifier.openConversation('U020', '用户', 'avatar-a');
      expect(notifier.greet('用户', 'avatar-a', peerId: 'U020'), id);
      final thread = container.read(messagesProvider).threads.single;
      expect(thread.entries.single.content, '你好，很高兴认识你！');
      notifier.block(thread);
      expect(notifier.greet('用户', 'avatar-a', peerId: 'U020'), isNull);
      expect(container.read(messagesProvider).threads, isEmpty);
      expect(
        container.read(messagesProvider).blocked.values.single.entries,
        hasLength(1),
      );
      await Future<void>.delayed(Duration.zero);
    },
  );

  test('voice and call durations persist with legacy text compatibility', () {
    const voice = ChatEntry(
      '/account/U020/voice.m4a',
      kind: ChatEntryKind.voice,
      durationSeconds: 7,
      isMine: true,
    );
    final decodedVoice = ChatEntry.fromJson(voice.toJson());
    expect(decodedVoice.kind, ChatEntryKind.voice);
    expect(decodedVoice.durationSeconds, 7);
    expect(decodedVoice.content, voice.content);
    const call = ChatEntry(
      '通话时长01:12',
      kind: ChatEntryKind.videoCall,
      durationSeconds: 72,
    );
    const thread = MessageThread(
      id: 'peer-U020',
      peerId: 'U020',
      name: '用户',
      avatar: 'avatar-a',
      entries: [voice, call],
    );
    final reopened = MessageThread.fromJson(thread.toJson());
    expect(reopened.peerId, 'U020');
    expect(reopened.entries.last.durationSeconds, 72);
    expect(reopened.preview, '[视频通话]');
    final legacy = ChatEntry.fromJson({'content': '旧消息', 'kind': 'old-kind'});
    expect(legacy.kind, ChatEntryKind.text);
    expect(legacy.durationSeconds, isNull);
  });
}
