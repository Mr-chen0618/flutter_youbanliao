import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/teen/data/teen_mode_repository.dart';
import 'package:flutter_app_framework/features/teen/presentation/teen_mode_provider.dart';
import 'package:flutter_app_framework/features/teen/presentation/teen_mode_page.dart';

class _LockedRepository extends TeenModeRepository {
  _LockedRepository() : super(MockJsonStore());
  bool locked = true;
  @override
  Future<bool> enabled() async => locked;
  @override
  Future<bool> disable(String pin) async {
    if (pin != '5826') return false;
    locked = false;
    return true;
  }
}

void main() {
  testWidgets(
    'root gate blocks content until correct PIN and explicit return',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _LockedRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [teenModeRepositoryProvider.overrideWithValue(repository)],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              builder: (_, child) => TeenModeGate(child: child!),
              home: const Scaffold(body: Text('受保护内容')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('受保护内容'), findsNothing);
      await tester.tap(find.text('关闭青少年模式').last);
      await tester.pumpAndSettle();
      Future<void> enter(String pin) async {
        for (final digit in pin.split('')) {
          await tester.ensureVisible(find.widgetWithText(FilledButton, digit));
          await tester.tap(find.widgetWithText(FilledButton, digit));
          await tester.pumpAndSettle();
        }
      }

      await enter('0000');
      expect(find.text('密码错误，请重新输入'), findsOneWidget);
      expect(repository.locked, true);
      expect(find.text('受保护内容'), findsNothing);
      await enter('5826');
      expect(find.text('青少年模式已关闭'), findsOneWidget);
      expect(find.text('受保护内容'), findsNothing);
      await tester.ensureVisible(find.text('返回首页'));
      await tester.tap(find.text('返回首页'));
      await tester.pumpAndSettle();
      expect(find.text('受保护内容'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
