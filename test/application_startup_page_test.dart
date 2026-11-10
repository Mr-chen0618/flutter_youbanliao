import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_app_framework/core/network/connectivity/network_state.dart';
import 'package:flutter_app_framework/core/network/offline_queue/offline_queue_state.dart';
import 'package:flutter_app_framework/core/network/providers/network_providers.dart';
import 'package:flutter_app_framework/core/network/providers/offline_queue_state_provider.dart';
import 'package:flutter_app_framework/app/bootstrap/application_startup_page.dart';
import 'package:flutter_app_framework/features/auth/presentation/pages/splash_page.dart';

void main() {
  testWidgets('offline banner has application layout context on startup', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkStateProvider.overrideWith(
            (ref) => Stream.value(const NetworkState(Reachability.offline)),
          ),
          offlineQueueStateProvider.overrideWith(
            (ref) => Stream.value(OfflineQueueState.empty),
          ),
        ],
        child: const Application(
          startPage: SplashPage(),
          showNetworkStatus: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('网络不可用，操作将在恢复后同步'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'startup renders before initialization and offers retry on failure',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ApplicationStartupPage(
            initialize: () {
              calls++;
              return calls == 1
                  ? pending.future
                  : Future<void>.error(StateError('offline'));
            },
          ),
        ),
      );
      await tester.pump();
      expect(calls, 1);
      expect(find.byType(SplashPage), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.completeError(StateError('initialization failed'));
      await tester.pumpAndSettle();
      expect(find.text('启动失败，请重试'), findsOneWidget);
      await tester.tap(find.text('重新加载'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('启动失败，请重试'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
