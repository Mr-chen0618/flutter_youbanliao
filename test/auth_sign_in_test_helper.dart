import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/features/user/presentation/pages/sign_in_dialog.dart';

/// 旧认证导航场景在进入首页后处理新增的自动签到层，保留产品Gate和业务断言。
Future<void> dismissAutomaticSignIn(WidgetTester tester) async {
  final dialog = find.byType(SignInDialog);
  if (dialog.evaluate().isEmpty) return;
  final close = find.descendant(
    of: dialog,
    matching: find.byIcon(Icons.cancel_outlined),
  );
  expect(close, findsOneWidget);
  await tester.tap(close);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(SignInDialog), findsNothing);
}
