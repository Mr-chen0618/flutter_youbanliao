import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_framework/app/di/home_dependencies.dart';
import 'package:flutter_app_framework/app/navigation/main_tab_shell.dart';
import 'package:flutter_app_framework/features/home/data/enum/home_mock_scenario_enum.dart';
import 'package:flutter_app_framework/features/home/data/mock/home_mock_server.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_app_framework/features/user/presentation/pages/user_detail_page.dart';
import 'package:flutter_app_framework/features/messages/presentation/pages/chat_page.dart';
import 'package:flutter_app_framework/features/messages/presentation/pages/call_page.dart';
import 'package:flutter_app_framework/features/messages/data/messages_repository.dart';
import 'package:flutter_app_framework/features/messages/presentation/providers/messages_provider.dart';
import 'package:flutter_app_framework/features/home/presentation/pages/home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_json_test_store.dart';

Future<void> openHome(
  WidgetTester tester,
  HomeMockScenarioEnum scenario, {
  CallRingback? ringback,
}) async {
  final store = (await tester.runAsync(WidgetMockJsonStore.load))!;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mockJsonStoreProvider.overrideWithValue(store),
        if (ringback != null)
          callRingbackFactoryProvider.overrideWithValue(() => ringback),
        homeServerProvider.overrideWithValue(
          HomeMockServer(store: store, scenario: scenario),
        ),
      ],
      child: const Application(startPage: MainTabShell()),
    ),
  );
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(375, 812),
    const Size(430, 932),
  ]) {
    testWidgets('home lays out, scrolls and switches tabs at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openHome(tester, HomeMockScenarioEnum.success);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('海盐芝士'), findsOneWidget);
      expect(find.text('首页'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
      await tester.pumpAndSettle();
      expect(find.text('小满同学').hitTestable(), findsOneWidget);
      await tester.tap(find.text('广场'));
      await tester.pumpAndSettle();
      expect(
        find
            .descendant(of: find.byType(HomePage), matching: find.text('海盐芝士'))
            .hitTestable(),
        findsNothing,
      );
      await tester.tap(find.text('首页'));
      await tester.pumpAndSettle();
      expect(find.text('小满同学').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('home greets the selected peer and opens publish page', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await openHome(tester, HomeMockScenarioEnum.success);
    await tester.pumpAndSettle();
    await tester.tap(find.text('打招呼').hitTestable().first);
    await tester.pumpAndSettle();
    final chat = tester.widget<ChatPage>(find.byType(ChatPage));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ChatPage)),
    );
    final thread = container
        .read(messagesProvider)
        .threads
        .firstWhere((item) => item.id == chat.threadId);
    expect(thread.peerId, 'U002');
    expect(thread.name, '海盐芝士');
    expect(thread.entries.last.content, '你好，很高兴认识你！');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('活动').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('发布活动').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('创建搭子'), findsOneWidget);
    expect(find.text('性别限制'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home companion opens profile and its published activity', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openHome(tester, HomeMockScenarioEnum.success);
    await tester.pumpAndSettle();

    await tester.tap(find.text('海盐芝士'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ID: U002'), findsOneWidget);
    expect(find.text('直接邀约'), findsOneWidget);

    final activity = find.text('潮汕牛肉火锅');
    await tester.scrollUntilVisible(
      activity,
      200,
      scrollable: find
          .descendant(
            of: find.byType(UserDetailPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(activity);
    await tester.pumpAndSettle();
    expect(find.text('发布人：海盐芝士'), findsOneWidget);
    await tester.tap(find.byTooltip('返回').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('返回').hitTestable().first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile messaging and block use the same stable peer ID', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await openHome(tester, HomeMockScenarioEnum.success);
    await tester.pumpAndSettle();
    await tester.tap(find.text('海盐芝士').hitTestable());
    await tester.pumpAndSettle();
    final profile = find.byType(UserDetailPage);
    final container = ProviderScope.containerOf(tester.element(profile));
    await tester.tap(find.text('私信').hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(ChatPage), findsOneWidget);
    final messages = container.read(messagesProvider);
    final thread = messages.threads.singleWhere(
      (item) => item.peerId == 'U002',
    );
    expect(thread.entries, isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('更多').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('加入黑名单').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定拉黑').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('你已将对方拉黑，无法查看主页'), findsOneWidget);
    expect(find.text('私信').hitTestable(), findsNothing);
    expect(container.read(messagesProvider).blocked[thread.id]?.peerId, 'U002');
    await tester.tap(find.byTooltip('更多').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('移除黑名单').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('私信').hitTestable(), findsOneWidget);
    expect(
      container.read(messagesProvider).blocked,
      isNot(contains(thread.id)),
    );
    await tester.tap(find.byTooltip('返回').hitTestable().first);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'video call keeps session in small window and writes one call receipt',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await openHome(tester, HomeMockScenarioEnum.success);
      await tester.pumpAndSettle();
      await tester.tap(find.text('海盐芝士').hitTestable());
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(UserDetailPage)),
      );
      await tester.tap(find.text('视频通话').hitTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(CallPage), findsOneWidget);
      expect(find.text('正在发起呼叫…'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();
      expect(find.text('等待对方接受邀请…'), findsOneWidget);
      expect(find.text('模拟接通'), findsNothing);
      await tester.tap(find.byTooltip('切换小窗').hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(CallPage), findsNothing);
      await tester.tap(find.text('待接通').hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(CallPage), findsOneWidget);
      expect(find.text('模拟接通'), findsNothing);
      await tester.tap(find.text('挂断').hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(CallPage), findsNothing);
      final thread = container
          .read(messagesProvider)
          .threads
          .singleWhere((it) => it.peerId == 'U002');
      expect(
        thread.entries.where((entry) => entry.kind == ChatEntryKind.videoCall),
        hasLength(1),
      );
      await tester.tap(find.byTooltip('返回').hitTestable().first);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'voice call quick cancel and video timeout do not connect or duplicate receipts',
    (tester) async {
      await openHome(tester, HomeMockScenarioEnum.success);
      await tester.pumpAndSettle();
      await tester.tap(find.text('海盐芝士').hitTestable());
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(UserDetailPage));
      final container = ProviderScope.containerOf(context);
      CallPage.open(context, peerId: 'U002', name: '海盐芝士', avatar: '');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      // 准备阶段重复呼叫不能再压入通话页。
      CallPage.open(
        context,
        peerId: 'U002',
        name: '海盐芝士',
        avatar: '',
        video: true,
      );
      await tester.pump();
      expect(find.byType(CallPage), findsOneWidget);
      expect(find.text('正在发起呼叫…'), findsOneWidget);
      expect(find.text('模拟接通'), findsNothing);
      await tester.tap(find.text('挂断').hitTestable());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 28));
      expect(find.byType(CallPage), findsNothing);
      CallPage.open(
        context,
        peerId: 'U002',
        name: '海盐芝士',
        avatar: '',
        video: true,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump(const Duration(seconds: 26));
      await tester.pumpAndSettle();
      expect(find.byType(CallPage), findsNothing);
      final entries = container
          .read(messagesProvider)
          .threads
          .singleWhere((it) => it.peerId == 'U002')
          .entries;
      expect(
        entries
            .where((it) => it.kind == ChatEntryKind.voiceCall)
            .single
            .content,
        '已取消',
      );
      expect(
        entries
            .where((it) => it.kind == ChatEntryKind.videoCall)
            .single
            .content,
        '对方无应答',
      );
      expect(entries.every((it) => it.durationSeconds == null), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ringback starts after preparation, stops in background and disposes',
    (tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      final ring = _FakeRingback();
      await openHome(tester, HomeMockScenarioEnum.success, ringback: ring);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(MainTabShell));
      CallPage.open(context, peerId: 'U002', name: '海盐芝士', avatar: '');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(ring.starts, 0);
      await tester.pump(const Duration(milliseconds: 1300));
      expect(ring.starts, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(ring.stops, greaterThanOrEqualTo(1));
      final starts = ring.starts;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(ring.starts, starts + 1);
      final stops = ring.stops;
      await tester.tap(find.text('挂断').hitTestable());
      await tester.pumpAndSettle();
      expect(ring.stops, greaterThan(stops));
      final afterEnd = ring.starts;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(ring.starts, afterEnd);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(ring.disposals, 1);
    },
  );

  testWidgets('empty scenario renders empty state', (tester) async {
    await openHome(tester, HomeMockScenarioEnum.empty);
    await tester.pumpAndSettle();
    expect(find.text('暂无友伴'), findsOneWidget);
  });

  testWidgets('failure can be retried, activity and category are interactive', (
    tester,
  ) async {
    await openHome(tester, HomeMockScenarioEnum.failOnce);
    await tester.pumpAndSettle();
    expect(find.text('加载失败，请重试'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('活动'));
    await tester.pumpAndSettle();
    expect(find.text('海鲜大排档'), findsWidgets);
    await tester.tap(find.text('户外搭子'));
    await tester.pumpAndSettle();
    expect(find.text('海鲜大排档'), findsNothing);
    expect(find.text('找搭子'), findsOneWidget);
    expect(find.text('薄荷日记'), findsOneWidget);
    await tester.tap(find.text('探店搭子'));
    await tester.pumpAndSettle();
    expect(find.text('晚风有信'), findsOneWidget);
    expect(find.text('薄荷日记'), findsNothing);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('海鲜大排档'), findsWidgets);
  });
}

class _FakeRingback implements CallRingback {
  int starts = 0, stops = 0, disposals = 0;
  @override
  Future<void> start() async {
    starts++;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}
