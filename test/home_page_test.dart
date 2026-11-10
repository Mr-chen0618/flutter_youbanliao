import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_framework/app/di/home_dependencies.dart';
import 'package:flutter_app_framework/app/navigation/main_tab_shell.dart';
import 'package:flutter_app_framework/features/home/data/enum/home_mock_scenario_enum.dart';
import 'package:flutter_app_framework/features/home/data/mock/home_mock_server.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_app_framework/features/home/presentation/pages/home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_json_test_store.dart';

Future<void> openHome(
  WidgetTester tester,
  HomeMockScenarioEnum scenario,
) async {
  final store = (await tester.runAsync(WidgetMockJsonStore.load))!;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mockJsonStoreProvider.overrideWithValue(store),
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

  testWidgets('home opens the invite form and publish page', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await openHome(tester, HomeMockScenarioEnum.success);
    await tester.pumpAndSettle();
    await tester.tap(find.text('邀约Ta').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('发起邀约'), findsOneWidget);
    expect(find.text('发出邀约'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
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
    await tester.drag(find.byType(ListView).first, const Offset(0, -330));
    await tester.pumpAndSettle();
    await tester.tap(activity);
    await tester.pumpAndSettle();
    expect(find.text('发布人：海盐芝士'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
