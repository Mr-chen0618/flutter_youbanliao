import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_app_framework/features/auth/data/model/auth_session.dart';
import 'package:flutter_app_framework/features/auth/data/repository/auth_repository.dart';
import 'package:flutter_app_framework/features/auth/data/request-model/phone_login_request.dart';
import 'package:flutter_app_framework/features/auth/presentation/pages/phone_login_page.dart';
import 'package:flutter_app_framework/features/auth/presentation/pages/registration_profile_page.dart';

class _Auth extends Fake implements AuthRepository {
  bool sent = false;
  @override
  Future<void> sendCode(String phone) async {
    sent = true;
  }

  @override
  Future<AuthSession> login(PhoneLoginRequest request) async {
    if (!sent) throw StateError('请先获取验证码');
    if (request.code != '8888') throw StateError('验证码不正确');
    return const AuthSession('quality', profileCompleted: true);
  }
}

Future<void> open(WidgetTester tester, Widget page) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(375, 812);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(ProviderScope(child: Application(startPage: page)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'four digit login uses overlay feedback without shifting the form',
    (tester) async {
      final auth = _Auth();
      var entered = false;
      await open(
        tester,
        PhoneLoginPage(auth: auth, onSignedIn: () => entered = true),
      );
      expect(find.textContaining('本地演示'), findsNothing);
      expect(find.textContaining('模拟'), findsNothing);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '14444000001');
      await tester.enterText(fields.at(1), '8888');
      await tester.pump();
      final button = find.widgetWithText(FilledButton, '登录/注册');
      final before = tester.getRect(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(entered, isFalse);
      expect(find.text('请先获取验证码'), findsOneWidget);
      expect(find.textContaining('Bad state:'), findsNothing);
      expect(tester.getRect(button), before);
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.text('请先获取验证码'),
        ),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('获取验证码'));
      await tester.pumpAndSettle();
      expect(find.text('发送成功'), findsOneWidget);
      expect(tester.getRect(button), before);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(entered, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    },
  );
  testWidgets(
    'missing registration fields show Toast without moving enter action',
    (tester) async {
      await open(
        tester,
        RegistrationProfilePage(
          session: const AuthSession('quality'),
          auth: _Auth(),
          onChanged: () {},
        ),
      );
      final enter = find.widgetWithText(FilledButton, '立即进入');
      final before = tester.getRect(enter);
      await tester.tap(enter);
      await tester.pumpAndSettle();
      expect(find.textContaining('请添加头像'), findsOneWidget);
      expect(tester.getRect(enter), before);
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.textContaining('请添加头像'),
        ),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
