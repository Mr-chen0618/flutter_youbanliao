import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/features/user/data/model/growth_state.dart';
import 'package:flutter_app_framework/features/user/presentation/providers/growth_provider.dart';
import 'package:flutter_app_framework/features/user/presentation/pages/sign_in_dialog.dart';
import 'dart:ui' as ui;

void main() {
  test('sign in decoration is a packaged decodable bitmap', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final data = await rootBundle.load('assets/profile/sign_in_decoration.png');
    expect(data.lengthInBytes, greaterThan(0));
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 351);
    expect(frame.image.height, 463);
    frame.image.dispose();
    codec.dispose();
  });
  for (final width in [320.0, 375.0]) {
    for (final checked in [false, true]) {
      testWidgets('sign in two states width=$width checked=$checked', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 812);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final today = DateTime.now().toIso8601String().substring(0, 10);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              growthProvider.overrideWith(
                (ref) async => GrowthState(checks: checked ? [today] : []),
              ),
            ],
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, _) =>
                  const MaterialApp(home: Scaffold(body: SignInDialog())),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(checked ? '签到成功！！' : '做任务 领奖励'), findsOneWidget);
        expect(find.text(checked ? '每天登录，奖励领不停' : '连续签到领福利！！'), findsOneWidget);
        expect(find.text(checked ? '明日再来' : '签到'), findsOneWidget);
        expect(find.text(checked ? '恭喜获得' : '已连续签到0天'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
