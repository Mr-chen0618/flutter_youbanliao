import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/auth/data/mock/auth_mock_repository.dart';
import 'package:flutter_app_framework/features/auth/data/request-model/phone_login_request.dart';
import 'package:flutter_app_framework/features/auth/presentation/pages/auth_gate.dart';
import 'package:flutter_app_framework/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_app_framework/features/user/data/model/member_profile.dart';
import 'package:flutter_app_framework/features/user/presentation/pages/account_deletion_page.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_test_store.dart';

Future<void> settleIo(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 40));
  }
}

void main() {
  testWidgets(
    'deletion normal entry permits cancel, requires reason, clears navigation and offers recovery',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final seeds = (await tester.runAsync(() async {
        final result = <String, String>{};
        await for (final f in Directory('assets/mock').list(recursive: true)) {
          if (f is File && f.path.endsWith('.json')) {
            result[f.path.substring(12, f.path.length - 5)] = await f
                .readAsString();
          }
        }
        return result;
      }))!;
      final store = AuthTestStore(seeds);
      final auth = AuthMockRepository(store, delay: Duration.zero);
      final session = (await tester.runAsync(() async {
        await auth.sendCode('14444000015');
        return auth.login(const PhoneLoginRequest('14444000015', '8888'));
      }))!;
      await auth.completeProfile(
        session.accountId,
        MemberProfile(
          id: session.accountId,
          name: '注销流程用户',
          avatar: 'assets/mock/media/IMG025.jpg',
          gender: '女',
          birthday: DateTime(2000),
          signature: '',
          city: '',
          interests: [],
          tags: [],
          following: 0,
          followers: 0,
          friends: 0,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mockJsonStoreProvider.overrideWithValue(store),
            authRepositoryProvider.overrideWithValue(auth),
          ],
          child: const Application(startPage: AuthGate()),
        ),
      );
      await settleIo(tester);
      await tester.tap(find.byKey(const ValueKey('main-tab-3')));
      await settleIo(tester);
      await tester.scrollUntilVisible(
        find.text('设置'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await settleIo(tester);
      await tester.tap(find.text('设置').hitTestable());
      await settleIo(tester);
      await tester.tap(find.text('注销账号 (慎用)').hitTestable());
      await settleIo(tester);
      expect(find.byType(AccountDeletionPage), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '申请注销 15s'))
            .onPressed,
        isNull,
      );
      // 在申请前从公开返回按钮离开，不应改变会话或账号。
      await tester.tap(find.byType(BackButton).hitTestable());
      await settleIo(tester);
      expect(
        (await tester.runAsync(auth.restore))!.accountId,
        session.accountId,
      );
      await tester.tap(find.text('注销账号 (慎用)').hitTestable());
      await settleIo(tester);
      await tester.pump(const Duration(seconds: 16));
      await tester.tap(find.widgetWithText(FilledButton, '申请注销'));
      await settleIo(tester);
      final confirm = find.widgetWithText(FilledButton, '确认注销');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.tap(find.text('去其他平台'));
      await tester.enterText(find.byType(TextField), '本地合成账号注销回归');
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
      await tester.tap(confirm);
      await settleIo(tester);
      expect(find.byType(AccountDeletionCompletedPage), findsOneWidget);
      expect(await tester.runAsync(auth.restore), isNull);
      await tester.tap(find.text('我知道了'));
      await settleIo(tester);
      expect(find.text('手机号登录'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('welcome-agreement')));
      await tester.tap(find.byKey(const ValueKey('welcome-phone-login')));
      await settleIo(tester);
      expect(find.byType(AccountDeletionPage), findsNothing);
      await tester.enterText(find.byType(TextField).at(0), '14444000015');
      await tester.pump();
      await tester.tap(find.text('获取验证码'));
      await settleIo(tester);
      await tester.enterText(find.byType(TextField).at(1), '8888');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '登录/注册'));
      await settleIo(tester);
      expect(find.text('恢复账号'), findsWidgets);
      expect(find.text('继续注销'), findsOneWidget);
      await tester.tap(find.text('继续注销'));
      await settleIo(tester);
      expect(await tester.runAsync(auth.restore), isNull);
      expect(find.byKey(const ValueKey('main-tab-3')), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, '登录/注册'));
      await settleIo(tester);
      expect(find.text('继续注销'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '恢复账号'));
      await settleIo(tester);
      await tester.tap(find.byKey(const ValueKey('main-tab-3')));
      await settleIo(tester);
      expect(find.text('注销流程用户'), findsOneWidget);
      expect(
        (await tester.runAsync(auth.restore))!.accountId,
        session.accountId,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
