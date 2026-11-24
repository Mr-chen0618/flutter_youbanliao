import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_app_framework/app/navigation/main_tab_shell.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/messages/data/model/message_thread.dart';
import 'package:flutter_app_framework/features/messages/data/model/chat_entry.dart';
import 'package:flutter_app_framework/features/messages/data/enum/chat_entry_kind.dart';
import 'package:flutter_app_framework/features/messages/presentation/pages/chat_page.dart';
import 'package:flutter_app_framework/features/user/presentation/pages/user_detail_page.dart';
import 'mock_json_test_store.dart';

void main() {
  test(
    'heat counts one per sent message or gift, persists, and excludes receipts',
    () {
      const thread = MessageThread(
        id: 't',
        name: 'peer',
        avatar: '',
        entries: [
          ChatEntry('text', isMine: true),
          ChatEntry(
            'gift',
            isMine: true,
            kind: ChatEntryKind.gift,
            giftQuantity: 99,
          ),
          ChatEntry('photo', isMine: true, kind: ChatEntryKind.photo),
          ChatEntry('received'),
          ChatEntry('call', isMine: true, kind: ChatEntryKind.voiceCall),
          ChatEntry('video', isMine: true, kind: ChatEntryKind.videoCall),
        ],
      );
      expect(thread.heat, 3);
      expect(MessageThread.fromJson(thread.toJson()).heat, 3);
    },
  );
  testWidgets(
    'three inline message tabs and noninteractive profile card with left avatar',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = (await tester.runAsync(WidgetMockJsonStore.load))!;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mockJsonStoreProvider.overrideWithValue(store)],
          child: const Application(startPage: MainTabShell()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('main-tab-2')));
      await tester.pumpAndSettle();
      final message = find.text('消息').hitTestable().first;
      final friends = find.text('好友').hitTestable();
      final calls = find.text('通话记录').hitTestable();
      expect(
        tester.getCenter(message).dy,
        closeTo(tester.getCenter(friends).dy, 12),
      );
      expect(
        tester.getCenter(friends).dy,
        closeTo(tester.getCenter(calls).dy, 1),
      );
      await tester.tap(friends);
      await tester.pumpAndSettle();
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
      await tester.drag(find.byType(TabBarView), const Offset(-320, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 2);
      await tester.tap(calls);
      await tester.pumpAndSettle();
      await tester.tap(message);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('main-tab-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('打招呼').hitTestable().first);
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('chat-profile-card'));
      await tester.scrollUntilVisible(
        card,
        -300,
        scrollable: find
            .descendant(
              of: find.byType(ChatPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final avatar = find.byKey(const ValueKey('chat-profile-avatar'));
      expect(
        tester.getTopLeft(avatar).dx,
        lessThan(tester.getTopLeft(card).dx),
      );
      await tester.tap(card, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.byType(UserDetailPage), findsNothing);
      await tester.tap(find.byTooltip('更多操作'));
      await tester.pumpAndSettle();
      expect(find.text('聊天设置'), findsOneWidget);
      for (final title in ['查看主页', '关注', '设置备注', '举报', '拉黑']) {
        expect(find.text(title), findsOneWidget);
      }
      await tester.tap(find.text('海盐芝士').hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.byType(UserDetailPage), findsOneWidget);
      expect(find.textContaining('ID: U002'), findsOneWidget);
      await tester.tap(find.byTooltip('返回').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('查看主页'));
      await tester.pumpAndSettle();
      expect(find.byType(UserDetailPage), findsOneWidget);
      expect(find.textContaining('ID: U002'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
