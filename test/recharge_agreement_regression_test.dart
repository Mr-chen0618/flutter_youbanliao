import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/features/purchases/presentation/providers/apple_purchase_controller.dart';
import 'package:flutter_app_framework/features/purchases/presentation/providers/apple_purchase_provider.dart';
import 'package:flutter_app_framework/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_app_framework/features/auth/data/model/auth_session.dart';
import 'package:flutter_app_framework/features/user/presentation/pages/profile_shop_page.dart';
import 'package:flutter_app_framework/shared/pages/app_web_page.dart';
import 'package:flutter_app_framework/features/user/presentation/pages/user_feedback_page.dart';
import 'apple_purchase_test.dart' show FakeGateway, FakeFulfillment;
class AuditRoutes extends NavigatorObserver {
  Route<dynamic>? latest;
  @override void didPush(Route<dynamic> route, Route<dynamic>? previous) { latest = route; }
}
void main() {
 testWidgets('recharge agreement pushes exact supplied URL without changing membership', (tester) async {
   late FakeGateway gateway;
   late ApplePurchaseController controller;
   await tester.runAsync(() async {
     gateway = FakeGateway();
     controller = ApplePurchaseController(gateway: gateway, fulfillment: FakeFulfillment(), currentAccountId: () => 'A', supported: true, retryDelay: (_) async {});
     await controller.start();
   });
   addTearDown(() => tester.runAsync(() async { await controller.dispose(); await gateway.stream.close(); }));
   final routes = AuditRoutes();
   await tester.pumpWidget(ProviderScope(overrides: [
     applePurchaseControllerProvider.overrideWithValue(controller),
     authSessionProvider.overrideWith((ref) async => const AuthSession('A', profileCompleted: true)),
   ], child: ScreenUtilInit(designSize: const Size(375, 812), builder: (_, child) => MaterialApp(navigatorObservers: [routes], home: const CoinRechargePage(balance: 0)))));
   await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
   final context = tester.element(find.byType(CoinRechargePage));
   final button = tester.widget<TextButton>(find.widgetWithText(TextButton, '《用户充值协议》'));
   button.onPressed!();
   final route = routes.latest as MaterialPageRoute;
   final page = route.builder(context) as AppWebPage;
   expect(page.url, 'https://docs.qq.com/doc/DYUtKYWJCTkZCZXdL');
   expect(page.title, '用户充值协议');
   // Do not build native WebView in Widget environment.
   await tester.pumpWidget(const SizedBox());
   await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
 });
 for (final membership in [false, true]) {
  testWidgets('feedback shortcut membership=$membership at 320px stays in scoped shop', (tester) async {
    tester.view.physicalSize = const Size(320, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late FakeGateway gateway;
    late ApplePurchaseController controller;
    await tester.runAsync(() async {
      gateway = FakeGateway();
      controller = ApplePurchaseController(gateway: gateway, fulfillment: FakeFulfillment(), currentAccountId: () => 'A', supported: true, retryDelay: (_) async {});
      await controller.start();
    });
    addTearDown(() => tester.runAsync(() async { await controller.dispose(); await gateway.stream.close(); }));
    final routes = AuditRoutes();
    await tester.pumpWidget(ProviderScope(overrides: [
      applePurchaseControllerProvider.overrideWithValue(controller),
      authSessionProvider.overrideWith((ref) async => const AuthSession('A', profileCompleted: true)),
    ], child: ScreenUtilInit(designSize: const Size(375, 812), builder: (_, child) => MaterialApp(navigatorObservers: [routes], home: membership ? const MembershipCenterPage() : const CoinRechargePage(balance: 0)))));
    await tester.pumpAndSettle();
    final shortcut = find.byKey(const ValueKey('recharge-feedback'));
    expect(shortcut, membership ? findsNothing : findsOneWidget);
    expect(tester.takeException(), isNull);
    if (!membership) {
      final button = tester.widget<TextButton>(shortcut);
      final context = tester.element(shortcut);
      expect(button.style!.foregroundColor!.resolve({}), const Color(0xFF1890FF));
      button.onPressed!();
      final route = routes.latest as MaterialPageRoute;
      expect(route.builder(context), isA<FeedbackPage>());
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
 }

}
