import 'package:flutter_app_framework/features/square/data/model/square_video_catalog.dart';
import 'package:flutter_app_framework/features/activity/presentation/pages/my_activities_page.dart';
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
import 'package:flutter_app_framework/features/activity/presentation/pages/activity_reputation_page.dart';
import 'package:flutter_app_framework/shared/widgets/images/photo_upload_tile.dart';
import 'package:flutter_app_framework/shared/widgets/images/mock_photo_attachments.dart';

void main() {
  testWidgets(
    'square notifications return to feed and preserve publish entry',
    (tester) async {
      await _openTabs(tester);
      await tester.tap(find.text('广场'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('发布动态'), findsOneWidget);
      await tester.tap(find.byTooltip('动态通知'));
      await tester.pumpAndSettle();
      expect(find.text('暂无新通知'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('发布动态'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('profile activity shortcuts open joined and published lists', (
    tester,
  ) async {
    await _openTabs(tester);
    await tester.tap(find.byKey(const ValueKey('main-tab-3')));
    await tester.pumpAndSettle();
    for (final item in [('我参与的活动', true), ('我发布的活动', false)]) {
      await tester.scrollUntilVisible(
        find.text(item.$1),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text(item.$1).hitTestable());
      await tester.pumpAndSettle();
      expect(
        tester.widget<MyActivitiesPage>(find.byType(MyActivitiesPage)).joined,
        item.$2,
      );
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('profile reputation entry and feedback photo selection work', (
    tester,
  ) async {
    await _openTabs(tester);
    await tester.tap(find.byKey(const ValueKey('main-tab-3')));
    await tester.pumpAndSettle();
    Future<void> openEntry(String title) async {
      await tester.scrollUntilVisible(
        find.text(title),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(title).hitTestable());
      await tester.pumpAndSettle();
    }

    await openEntry('活动信誉分');
    expect(find.byType(ActivityReputationPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await openEntry('联系客服');
    await tester.scrollUntilVisible(
      find.text('添加图片'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.byType(PhotoUploadTile), findsOneWidget);
    addTearDown(() => AppMediaPicker.pickOverride = null);
    AppMediaPicker.pickOverride = () async => null;
    await tester.tap(find.text('添加图片'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MockPhotoAttachments>(find.byType(MockPhotoAttachments))
          .selected,
      isEmpty,
    );
    AppMediaPicker.pickOverride = () async => 'assets/mock/media/IMG025.jpg';
    await tester.tap(find.text('添加图片'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MockPhotoAttachments>(find.byType(MockPhotoAttachments))
          .selected,
      ['assets/mock/media/IMG025.jpg'],
    );
    expect(tester.takeException(), isNull);
  });

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
    expect(
      container.read(squareProvider).videoLikes.contains(squareVideoIds.first),
      isTrue,
    );
    expect(
      container.read(squareProvider).videoSaves.contains(squareVideoIds.first),
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('main-tab-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pumpAndSettle();
    expect(
      container.read(squareProvider).videoLikes.contains(squareVideoIds.first),
      isTrue,
    );
    expect(
      container.read(squareProvider).videoSaves.contains(squareVideoIds.first),
      isTrue,
    );
    await tester.tap(find.byTooltip('喜欢'));
    await tester.tap(find.byTooltip('收藏'));
    await tester.pumpAndSettle();
    expect(
      container.read(squareProvider).videoLikes.contains(squareVideoIds.first),
      isFalse,
    );
    expect(
      container.read(squareProvider).videoSaves.contains(squareVideoIds.first),
      isFalse,
    );
    await tester.drag(find.byType(PageView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey(squareVideoIds[1])), findsOneWidget);
    await tester.tap(find.byTooltip('喜欢').hitTestable());
    await tester.tap(find.byTooltip('收藏').hitTestable());
    await tester.pumpAndSettle();
    final snapshot = SquareState.fromJson(
      container.read(squareProvider).toJson(),
    );
    expect(snapshot.videoLikes, contains(squareVideoIds[1]));
    expect(snapshot.videoSaves, contains(squareVideoIds[1]));
    expect(snapshot.videoLiked, isFalse);
    expect(snapshot.videoSaved, isFalse);
    await tester.drag(find.byType(PageView), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey(squareVideoIds.first)), findsOneWidget);
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
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('晴天队长').hitTestable(), findsOneWidget);

    await openActions();
    await tester.tap(find.text('举报').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('选择举报类型'), findsOneWidget);
    await tester.tap(find.text('资料作假/冒用他人身份').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('上传图片（0/6）：'), findsOneWidget);
    final description = find.byType(TextField).hitTestable();
    await tester.enterText(description, '举报');
    await tester.tap(find.widgetWithText(FilledButton, '提交').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('输入的内容太少啦'), findsOneWidget);
    expect(find.text('举报提交成功'), findsNothing);
    await tester.enterText(description, '用户资料与本人身份不一致');
    await tester.tap(find.widgetWithText(FilledButton, '提交').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('举报提交成功'), findsOneWidget);
    await tester.tap(find.text('我知道了').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('聊天设置'), findsOneWidget);
    await tester.tap(find.text('拉黑').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认加入黑名单').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('晴天队长').hitTestable(), findsNothing);
    expect(find.text('消息').hitTestable(), findsWidgets);
  });

  testWidgets('chat renders the design history and sends a selected image', (
    tester,
  ) async {
    await _openTabs(tester);
    await tester.tap(find.byKey(const ValueKey('main-tab-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('薄荷同学').hitTestable());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(ListView).hitTestable().first,
      const Offset(0, 1500),
    );
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

    expect(find.text('消息').hitTestable(), findsWidgets);
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
      (2, '消息'),
      (3, '编辑资料'),
      (0, '海盐芝士'),
    ]) {
      await tester.tap(find.byKey(ValueKey('main-tab-$index')));
      await tester.pumpAndSettle();
      expect(find.text(content).hitTestable(), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('profile opens the membership and coin recharge pages', (
    tester,
  ) async {
    bool? selected(Finder label) => tester
        .widgetList<Semantics>(
          find.ancestor(of: label, matching: find.byType(Semantics)),
        )
        .firstWhere((widget) => widget.properties.selected != null)
        .properties
        .selected;

    await _openTabs(tester);
    await tester.tap(find.byKey(const ValueKey('main-tab-3')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('前往开通').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('会员中心').hitTestable(), findsOneWidget);
    expect(selected(find.text('12个月会员')), isTrue);
    await tester.tap(find.text('3个月会员').hitTestable());
    await tester.pumpAndSettle();
    expect(selected(find.text('3个月会员')), isTrue);
    expect(selected(find.text('12个月会员')), isFalse);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('点击充值').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('金币充值').hitTestable(), findsOneWidget);
    expect(selected(find.text('¥6')), isTrue);
    await tester.tap(find.text('¥30').hitTestable());
    await tester.pumpAndSettle();
    expect(selected(find.text('¥30')), isTrue);
    expect(selected(find.text('¥6')), isFalse);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的积分').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('积分记录').hitTestable(), findsOneWidget);
    expect(find.text('暂无积分记录').hitTestable(), findsOneWidget);
    expect(find.text('0').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('编辑资料').hitTestable(), findsOneWidget);
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
      await tester.pump();
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
    expect(find.text('昵称').hitTestable(), findsOneWidget);
    await tester.enterText(find.byType(TextField), '更新后的昵称');
    await tester.tap(find.text('保存').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('更新后的昵称'), findsOneWidget);
    await tester.tap(find.text('出生日期').hitTestable());
    await tester.pumpAndSettle();
    expect(find.textContaining('设置你的出生日期'), findsOneWidget);
    await tester.tap(find.text('保存').hitTestable());
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
    await tester.scrollUntilVisible(
      find.text('我的动态'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
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
