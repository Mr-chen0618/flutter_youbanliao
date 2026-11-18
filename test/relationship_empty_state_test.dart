import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app_framework/app/navigation/main_tab_shell.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/activity/presentation/providers/activity_detail_provider.dart';
import 'package:flutter_app_framework/features/home/presentation/pages/companion_list_page.dart';
import 'package:flutter_app_framework/features/user/presentation/pages/profile_relationships_page.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_app_framework/shared/widgets/layout/app_empty_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_json_test_store.dart';

void main() {
  Future<void> showRelationships(
    WidgetTester tester,
    Future<Set<String>> Function() followedIds,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final store = (await tester.runAsync(WidgetMockJsonStore.load))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mockJsonStoreProvider.overrideWithValue(store),
          followedActivityPublisherIdsProvider.overrideWith(
            (ref) => followedIds(),
          ),
        ],
        child: const Application(startPage: MainTabShell()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('main-tab-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('关注').hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ProfileRelationshipsPage), findsOneWidget);
  }

  testWidgets(
    'relationships distinguish loading, empty tabs and discovery action',
    (tester) async {
      final pending = Completer<Set<String>>();
      await showRelationships(tester, () => pending.future);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('找人聊聊'), findsNothing);
      expect(find.byType(AppEmptyState), findsNothing);
      pending.complete({});
      await tester.pumpAndSettle();
      expect(find.text('你还没有关注的人哦'), findsOneWidget);
      expect(find.text('关注 (0)'), findsNothing);
      final illustration = tester.widget<Image>(
        find.descendant(
          of: find.byType(AppEmptyState),
          matching: find.byType(Image),
        ),
      );
      final provider = illustration.image;
      final asset = provider is ResizeImage ? provider.imageProvider : provider;
      expect((asset as AssetImage).assetName, 'assets/shared/no_data.png');
      await tester.tap(find.text('粉丝').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('你还没有粉丝哦'), findsOneWidget);
      await tester.tap(find.text('好友').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('你还没有好友哦'), findsOneWidget);
      await tester.tap(find.text('找人聊聊').hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(CompanionListPage), findsOneWidget);
      final navigator = Navigator.of(tester.element(find.byType(CompanionListPage)));
      navigator.pop();
      await tester.pumpAndSettle();
      navigator.pop();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'nonempty relationships show live count and open matching profile',
    (tester) async {
      await showRelationships(tester, () async => {'U002'});
      await tester.pumpAndSettle();
      expect(find.text('关注 (1)'), findsOneWidget);
      expect(find.textContaining('｜找搭子'), findsOneWidget);
      expect(find.byType(AppEmptyState), findsNothing);
      expect(find.text('找人聊聊'), findsNothing);
      await tester.tap(find.text('海盐芝士').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('私信').hitTestable(), findsOneWidget);
    },
  );
}
