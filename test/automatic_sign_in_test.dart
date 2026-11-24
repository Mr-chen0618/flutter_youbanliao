import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/auth/data/model/auth_session.dart';
import 'package:flutter_app_framework/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_app_framework/features/teen/presentation/teen_mode_provider.dart';
import 'package:flutter_app_framework/features/purchases/data/local/purchase_ledger_store.dart';
import 'package:flutter_app_framework/features/user/data/model/growth_state.dart';
import 'package:flutter_app_framework/features/user/data/repository/growth_repository.dart';
import 'package:flutter_app_framework/features/user/presentation/providers/growth_provider.dart';
import 'package:flutter_app_framework/features/user/presentation/widgets/daily_sign_in_gate.dart';
import 'package:flutter_app_framework/features/user/presentation/pages/sign_in_dialog.dart';

class _Teen extends TeenModeController {
  _Teen(this.enabled);
  final bool enabled;
  @override
  Future<bool> build() async => enabled;
}

class _Growth extends GrowthRepository {
  _Growth() : super(MockJsonStore(), PurchaseLedgerStore(), 'a');
  int claims = 0;
  @override
  Future<bool> reserveAutomaticSignIn(DateTime now, String token) async =>
      claims++ == 0;
  @override
  Future<bool> confirmAutomaticSignIn(DateTime now, String token) async => true;
  @override
  Future<void> releaseAutomaticSignIn(String token) async {}
}

/// 可控的两阶段仓库，记录确认/释放，验证切账号时不会消费资格。
class _DeferredGrowth extends GrowthRepository {
  _DeferredGrowth(this.stage)
    : super(MockJsonStore(), PurchaseLedgerStore(), 'a');
  final String stage;
  final entered = Completer<void>(), resume = Completer<void>();
  String? owner;
  bool consumed = false;
  int releases = 0;
  @override
  Future<bool> reserveAutomaticSignIn(DateTime now, String token) async {
    owner = token;
    if (stage == 'reserve') {
      entered.complete();
      await resume.future;
    }
    return true;
  }

  @override
  Future<bool> confirmAutomaticSignIn(DateTime now, String token) async {
    if (stage == 'confirm') {
      entered.complete();
      await resume.future;
    }
    consumed = true;
    return true;
  }

  @override
  Future<void> releaseAutomaticSignIn(String token) async {
    if (owner == token) {
      owner = null;
      consumed = false;
      releases++;
    }
  }
}

void main() {
  test(
    'automatic claim survives restart, isolates accounts and skips checked days',
    () async {
      final dir = await Directory.systemTemp.createTemp('automatic-sign-in');
      addTearDown(() => dir.delete(recursive: true));
      GrowthRepository repo(String id) => GrowthRepository(
        MockJsonStore(directory: () async => dir),
        PurchaseLedgerStore(directory: () async => dir),
        id,
      );
      final a = repo('a');
      final today = DateTime(2026, 11, 23);
      expect(await a.claimAutomaticSignIn(today), isTrue);
      expect(await repo('a').claimAutomaticSignIn(today), isFalse);
      expect(await repo('b').claimAutomaticSignIn(today), isTrue);
      final cancelled = repo('cancelled');
      expect(await cancelled.reserveAutomaticSignIn(today, 'old'), isTrue);
      await cancelled.releaseAutomaticSignIn('old');
      expect(await cancelled.claimAutomaticSignIn(today), isTrue);
      final concurrent = repo('concurrent');
      await concurrent.reserveAutomaticSignIn(today, 'first');
      await concurrent.reserveAutomaticSignIn(today, 'second');
      await concurrent.releaseAutomaticSignIn('first');
      expect(await concurrent.confirmAutomaticSignIn(today, 'second'), isTrue);
      expect(
        await a.claimAutomaticSignIn(today.add(const Duration(days: 1))),
        isTrue,
      );
      await a.set('checks', ['2026-11-25']);
      expect(await a.claimAutomaticSignIn(DateTime(2026, 11, 25)), isFalse);
    },
  );
  for (final locked in [false, true]) {
    testWidgets('automatic dialog respects teen lock=$locked', (tester) async {
      final growth = _Growth();
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) async => const AuthSession('a', profileCompleted: true),
            ),
            teenModeProvider.overrideWith(() => _Teen(locked)),
            growthRepositoryProvider.overrideWithValue(growth),
            growthProvider.overrideWith((ref) async => const GrowthState()),
            signInNowProvider.overrideWithValue(() => DateTime(2026, 11, 23)),
          ],
          child: MaterialApp(
            navigatorKey: key,
            builder: (_, child) =>
                DailySignInGate(navigatorKey: key, child: child!),
            home: const Scaffold(body: Text('home')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SignInDialog), locked ? findsNothing : findsOneWidget);
      expect(growth.claims, locked ? 0 : 1);
    });
  }
  for (final authCase in ['loading', 'error', 'incomplete']) {
    testWidgets('automatic dialog skips auth $authCase', (tester) async {
      final growth = _Growth();
      final key = GlobalKey<NavigatorState>();
      final pending = Completer<AuthSession?>();
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith((ref) {
            if (authCase == 'loading') return pending.future;
            if (authCase == 'error') throw StateError('unavailable session');
            return Future.value(
              const AuthSession('a', profileCompleted: false),
            );
          }),
          teenModeProvider.overrideWith(() => _Teen(false)),
          growthRepositoryProvider.overrideWithValue(growth),
          growthProvider.overrideWith((ref) async => const GrowthState()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: key,
            builder: (_, child) =>
                DailySignInGate(navigatorKey: key, child: child!),
            home: const Scaffold(body: Text('home')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SignInDialog), findsNothing);
      expect(growth.claims, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      if (!pending.isCompleted) pending.complete(null);
    });
  }
  for (final stage in ['reserve', 'confirm']) {
    testWidgets(
      'account switch while $stage pending releases old qualification',
      (tester) async {
        final old = _DeferredGrowth(stage);
        final next = _Growth();
        final key = GlobalKey<NavigatorState>();
        AuthSession? current = const AuthSession('a', profileCompleted: true);
        final container = ProviderContainer(
          overrides: [
            authSessionProvider.overrideWith((ref) async => current),
            teenModeProvider.overrideWith(() => _Teen(false)),
            growthRepositoryProvider.overrideWith(
              (ref) => ref.watch(authSessionProvider).value?.accountId == 'a'
                  ? old
                  : next,
            ),
            growthProvider.overrideWith((ref) async => const GrowthState()),
            signInNowProvider.overrideWithValue(() => DateTime(2026, 11, 23)),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              navigatorKey: key,
              builder: (_, child) =>
                  DailySignInGate(navigatorKey: key, child: child!),
              home: const Scaffold(body: Text('home')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(old.entered.isCompleted, isTrue);
        expect(find.byType(SignInDialog), findsNothing);
        // 切换为未完成资料的B，避免B自己的弹窗干扰旧A结果断言。
        current = const AuthSession('b', profileCompleted: false);
        container.invalidate(authSessionProvider);
        await tester.pumpAndSettle();
        old.resume.complete();
        await tester.pumpAndSettle();
        expect(find.byType(SignInDialog), findsNothing);
        expect(old.releases, 1);
        expect(old.consumed, isFalse);
        expect(old.owner, isNull);
        expect(next.claims, 0);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
