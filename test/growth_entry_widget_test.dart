import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_app_framework/app/navigation/main_tab_shell.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/user/data/repository/growth_repository.dart';
import 'package:flutter_app_framework/features/user/presentation/providers/growth_provider.dart';
import 'package:flutter_app_framework/features/purchases/data/local/purchase_ledger_store.dart';
import 'package:flutter_app_framework/features/purchases/presentation/providers/apple_purchase_provider.dart';
import 'mock_json_test_store.dart';
import 'apple_purchase_test.dart' show FakeFulfillment;

class _Growth extends GrowthRepository {
  _Growth(MockJsonStore store) : super(store, PurchaseLedgerStore(), 'A');
  final checks = <String>[];
  int awards = 0;
  @override
  Future<Map<String, dynamic>> load() async => {
    'checks': List<String>.of(checks),
  };
  @override
  Future<void> checkIn(DateTime now) async {
    final day = now.toIso8601String().substring(0, 10);
    if (!checks.contains(day)) {
      checks.add(day);
      awards++;
    }
  }
}

void main() {
  testWidgets('my profile sign in grants once and remains checked on reentry', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = (await tester.runAsync(WidgetMockJsonStore.load))!;
    final growth = _Growth(store);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mockJsonStoreProvider.overrideWithValue(store),
          growthRepositoryProvider.overrideWithValue(growth),
          purchaseFulfillmentProvider.overrideWithValue(FakeFulfillment()),
        ],
        child: const Application(startPage: MainTabShell()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('main-tab-3')));
    await tester.pumpAndSettle();
    Future<void> open() async {
      await tester.scrollUntilVisible(
        find.text('签到'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('签到').hitTestable());
      await tester.pumpAndSettle();
    }

    await open();
    await tester.tap(find.widgetWithText(TextButton, '签到'));
    await tester.pumpAndSettle();
    expect(growth.awards, 1);
    expect(find.text('明日再来'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '明日再来'));
    await tester.pumpAndSettle();
    await open();
    expect(find.text('明日再来'), findsOneWidget);
    expect(find.text('签到成功！！'), findsOneWidget);
    expect(growth.awards, 1);
    await tester.tap(find.widgetWithText(TextButton, '明日再来'));
    await tester.pumpAndSettle();
  });
}
