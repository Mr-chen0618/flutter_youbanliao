import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/messages/data/messages_repository.dart';
import 'package:flutter_app_framework/features/messages/presentation/providers/messages_provider.dart';
import 'package:flutter_app_framework/features/messages/presentation/pages/chat_page.dart';
import 'package:flutter_app_framework/features/messages/presentation/pages/dynamic_notifications_page.dart';
import 'package:flutter_app_framework/shared/widgets/layout/app_empty_state.dart';
import 'mock_json_test_store.dart';
import 'package:flutter_app_framework/features/user/presentation/providers/profile_provider.dart';

void main() {
  for (final scenario in [
    (375.0, 1.0),
    (320.0, 1.0),
    (375.0, 1.5),
    (320.0, 1.5),
  ]) {
    testWidgets(
      'chat heat header fits width ${scenario.$1} scale ${scenario.$2}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(scenario.$1, 812);
        tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = (await tester.runAsync(WidgetMockJsonStore.load))!;
        final state = (await tester.runAsync(
          () => MessagesMockRepository(store).load(),
        ))!;
        final container = ProviderContainer(
          overrides: [
            mockJsonStoreProvider.overrideWithValue(store),
            messagesInitialProvider.overrideWith((ref) async => state),
          ],
        );
        addTearDown(container.dispose);
        await tester.runAsync(
          () => container.read(messagesInitialProvider.future),
        );
        await tester.runAsync(
          () => container.read(profileInitialProvider.future),
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const Application(startPage: ChatPage(threadId: 'sunny')),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('热聊值'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('热聊值'));
        await tester.pumpAndSettle();
        expect(find.text('热聊值'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('知道了'));
        await tester.pumpAndSettle();
      },
    );
  }
  testWidgets('dynamic notices reuse shared empty state', (tester) async {
    final store = (await tester.runAsync(WidgetMockJsonStore.load))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mockJsonStoreProvider.overrideWithValue(store)],
        child: const Application(startPage: DynamicNotificationsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('暂无新通知'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
