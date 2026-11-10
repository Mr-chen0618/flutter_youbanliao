import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_framework/app/navigation/main_tab_shell.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_json_test_store.dart';
import 'package:flutter_app_framework/features/square/presentation/widgets/square_post_card_widget.dart';
import 'package:flutter_app_framework/core/media/app_media_picker.dart';
import 'package:flutter_app_framework/features/square/presentation/providers/square_provider.dart';

void main() {
  testWidgets(
    'feed and detail share only block/report actions; counts toggle numerically and refresh preserves likes',
    (tester) async {
      await _openTabs(tester);
      await tester.tap(find.byKey(const ValueKey('main-tab-1')));
      await tester.pumpAndSettle();
      final card = find.byType(SquarePostCardWidget).first;
      final post = tester.widget<SquarePostCardWidget>(card).post;
      final base = post.likeCount;
      Finder likeLabel(int count) => find.descendant(
        of: card,
        matching: find.text(count > 0 ? '$count' : '点赞'),
      );
      await tester.tap(likeLabel(base));
      await tester.pumpAndSettle();
      expect(likeLabel(base + 1), findsOneWidget);
      expect(find.text('已点赞'), findsNothing);
      final refresh = find.byType(RefreshIndicator).hitTestable().first;
      await tester.widget<RefreshIndicator>(refresh).onRefresh();
      await tester.pumpAndSettle();
      expect(likeLabel(base + 1), findsOneWidget);
      await tester.tap(likeLabel(base + 1));
      await tester.pumpAndSettle();
      expect(likeLabel(base), findsOneWidget);
      Future<void> menu() async {
        await tester.tap(find.byTooltip('更多操作').hitTestable().first);
        await tester.pumpAndSettle();
        expect(find.text('拉黑').hitTestable(), findsOneWidget);
        expect(find.text('举报').hitTestable(), findsOneWidget);
        expect(find.text('关注').hitTestable(), findsNothing);
        expect(find.text('删除动态').hitTestable(), findsNothing);
        await tester.tap(find.text('取消').hitTestable());
        await tester.pumpAndSettle();
      }

      await menu();
      await tester.tap(find.text(post.text).hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.text('动态详情'), findsOneWidget);
      await menu();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('video actions update shared state and survive tab switches', (
    tester,
  ) async {
    await _openTabs(tester);
    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('视频').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('喜欢'));
    await tester.tap(find.byTooltip('收藏'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MainTabShell)),
    );
    expect(container.read(squareProvider).videoLiked, isTrue);
    expect(container.read(squareProvider).videoSaved, isTrue);
    await tester.tap(find.byKey(const ValueKey('main-tab-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pumpAndSettle();
    expect(container.read(squareProvider).videoLiked, isTrue);
    expect(container.read(squareProvider).videoSaved, isTrue);
    await tester.tap(find.byTooltip('喜欢'));
    await tester.tap(find.byTooltip('收藏'));
    await tester.pumpAndSettle();
    expect(container.read(squareProvider).videoLiked, isFalse);
    expect(container.read(squareProvider).videoSaved, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat action sheet can cancel, report, and confirm blocking', (
    tester,
  ) async {
    await _openTabs(tester);
    await tester.tap(find.byKey(const ValueKey('main-tab-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('晴天队长').hitTestable());
    await tester.pumpAndSettle();

    Future<void> openActions() async {
      await tester.tap(find.byTooltip('更多操作').hitTestable());
      await tester.pumpAndSettle();
    }

    await openActions();
    await tester.tap(find.text('取消').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('晴天队长').hitTestable(), findsOneWidget);

    await openActions();
    await tester.tap(find.text('举报').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('广告引流 / 垃圾信息').hitTestable());
    await tester.scrollUntilVisible(
      find.text('提交举报'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('提交举报'));
    await tester.pumpAndSettle();
    expect(find.text('举报').hitTestable(), findsNothing);

    await openActions();
    await tester.tap(find.text('拉黑').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认加入黑名单').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('晴天队长').hitTestable(), findsNothing);
    expect(find.text('系统消息').hitTestable(), findsOneWidget);
  });

  testWidgets('chat renders the design history and sends a selected image', (
    tester,
  ) async {
    await _openTabs(tester);
    await tester.tap(find.byKey(const ValueKey('main-tab-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('薄荷同学').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('2026年12月11日 18:30'), findsOneWidget);
    expect(find.text('周末羽毛球局'), findsOneWidget);
    expect(find.text('已送达'), findsOneWidget);

    final activityLink = find.text('查看活动详情');
    await tester.ensureVisible(activityLink);
    await tester.tap(activityLink);
    await tester.pumpAndSettle();
    expect(find.text('周末羽毛球局').hitTestable(), findsOneWidget);
    expect(find.text('报名'), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    AppMediaPicker.pickOverride = () async => 'assets/mock/media/IMG025.jpg';
    addTearDown(() => AppMediaPicker.pickOverride = null);
    await tester.tap(find.byTooltip('添加图片'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('[图片]').hitTestable(), findsOneWidget);
  });

  testWidgets('messages shows its own title and notice shortcuts', (
    tester,
  ) async {
    await _openTabs(tester);
    await tester.tap(find.byKey(const ValueKey('main-tab-2')));
    await tester.pumpAndSettle();

    expect(find.text('消息').hitTestable(), findsNWidgets(2));
    expect(find.text('发现').hitTestable(), findsNothing);
    expect(find.byTooltip('搜索消息').hitTestable(), findsNothing);
    for (final label in ['系统消息', '互动消息', '谁看过我']) {
      expect(find.text(label).hitTestable(), findsOneWidget);
    }
    await tester.tap(find.text('系统消息').hitTestable());
    await tester.pumpAndSettle();
    expect(find.textContaining('欢迎加入友伴').hitTestable(), findsOneWidget);
  });

  testWidgets('the four root tabs can be reached at phone width', (
    tester,
  ) async {
    await _openTabs(tester);
    for (final (index, content) in [
      (1, '发现'),
      (2, '系统消息'),
      (3, '我的组队'),
      (0, '海盐芝士'),
    ]) {
      await tester.tap(find.byKey(ValueKey('main-tab-$index')));
      await tester.pumpAndSettle();
      expect(find.text(content).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'greetings reach the inbox and sent messages update the preview',
    (tester) async {
      await _openTabs(tester);
      await tester.tap(find.text('广场'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('打招呼').hitTestable().first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '周末见');
      await tester.tap(find.text('发送'));
      await tester.pumpAndSettle();
      expect(find.text('周末见'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('main-tab-2')));
      await tester.pumpAndSettle();
      expect(find.text('周末见').hitTestable(), findsOneWidget);
    },
  );

  testWidgets('profile edits use dedicated pages and update the account', (
    tester,
  ) async {
    await _openTabs(tester);
    await tester.tap(find.byKey(const ValueKey('main-tab-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑资料').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('昵称').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('修改昵称'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '更新后的昵称');
    await tester.tap(find.text('保存').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('更新后的昵称'), findsOneWidget);
    await tester.tap(find.text('出生日期').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('选择生日'), findsOneWidget);
    await tester.tap(find.text('完成').hitTestable());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('post text opens detail and sends a persistent comment', (
    tester,
  ) async {
    await _openTabs(tester);
    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pumpAndSettle();
    final text = find.textContaining('周末想去试试这家海鲜小店').first;
    await tester.tap(text);
    await tester.pumpAndSettle();
    expect(find.text('动态详情'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('还没有评论'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('还没有评论'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '一起去');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.text('一起去'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new posts are visible under my posts', (tester) async {
    await _openTabs(tester);
    await tester.tap(find.text('广场'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('发布动态'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '周末一起运动');
    await tester.pump();
    await tester.ensureVisible(find.text('发布'));
    await tester.tap(find.text('发布'));
    await tester.pumpAndSettle();
    expect(find.text('周末一起运动').hitTestable(), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('main-tab-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的动态').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('周末一起运动').hitTestable(), findsOneWidget);
  });
}

Future<void> _openTabs(WidgetTester tester) async {
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
}
