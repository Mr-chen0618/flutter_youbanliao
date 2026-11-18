import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_framework/core/media/app_media_picker.dart';
import 'package:flutter_app_framework/features/auth/data/model/auth_session.dart';
import 'package:flutter_app_framework/features/auth/data/repository/auth_repository.dart';
import 'package:flutter_app_framework/features/auth/data/request-model/phone_login_request.dart';
import 'package:flutter_app_framework/features/auth/presentation/pages/auth_gate.dart';
import 'package:flutter_app_framework/features/auth/presentation/pages/registration_profile_page.dart';
import 'package:flutter_app_framework/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_app_framework/features/user/data/model/member_profile.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class RegistrationAuth extends Fake implements AuthRepository {
  AuthSession? session;
  int writes = 0, signouts = 0;
  bool failNext = false;
  MemberProfile? saved;
  final pending = Completer<void>();
  @override
  Future<AuthSession?> restore() async => session;
  @override
  Future<void> sendCode(String phone) async {}
  @override
  Future<AuthSession> login(PhoneLoginRequest request) async =>
      session = const AuthSession('registration-test');
  @override
  Future<void> signOut() async {
    signouts++;
    session = null;
  }

  @override
  Future<void> completeProfile(String id, MemberProfile profile) async {
    writes++;
    saved = profile;
    if (failNext) {
      failNext = false;
      throw StateError('资料保存失败，请重试');
    }
    await pending.future;
  }
}

Future<void> mount(
  WidgetTester tester,
  Widget child,
  RegistrationAuth auth,
) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(375, 812);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(() {
    AppMediaPicker.pickOverride = null;
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: Application(startPage: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'normal phone login opens pending profile and retention keeps draft',
    (tester) async {
      final auth = RegistrationAuth();
      await mount(tester, const AuthGate(), auth);
      await tester.tap(find.byKey(const ValueKey('welcome-agreement')));
      await tester.tap(find.byKey(const ValueKey('welcome-phone-login')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '14444000012');
      await tester.enterText(find.byType(TextField).at(1), '8888');
      await tester.tap(find.text('获取验证码'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '登录/注册'));
      await tester.pumpAndSettle();
      expect(find.byType(RegistrationProfilePage), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('registration-name')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '待完善昵称');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();
      expect(find.text('只差一步就注册成功了！退出也太可惜了'), findsOneWidget);
      await tester.tap(find.text('我知道了'));
      await tester.pumpAndSettle();
      expect(find.text('待完善昵称'), findsOneWidget);
      expect(auth.signouts, 0);
      expect(auth.writes, 0);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'profile sheets cancel safely, validate, pick image and save once',
    (tester) async {
      final auth = RegistrationAuth();
      var completed = 0, picks = 0;
      await mount(
        tester,
        RegistrationProfilePage(
          session: const AuthSession('registration-test'),
          auth: auth,
          onChanged: () => completed++,
        ),
        auth,
      );
      Future<void> tapKey(String key) async {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
      }

      await tapKey('registration-submit');
      expect(find.text('请上传头像'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tapKey('registration-gender-女');
      expect(find.text('注册成功后，性别将无法更换，请谨慎选择'), findsOneWidget);
      await tester.tap(find.text('我知道了'));
      await tester.pumpAndSettle();
      AppMediaPicker.pickOverride = () async {
        picks++;
        return null;
      };
      await tapKey('registration-avatar');
      expect(find.text('请上传本人高清美照'), findsOneWidget);
      await tester.tap(find.text('选择照片'));
      await tester.pumpAndSettle();
      expect(picks, 1);
      await tapKey('registration-submit');
      expect(find.text('请上传头像'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      AppMediaPicker.pickOverride = () async {
        picks++;
        return 'assets/mock/media/IMG025.jpg';
      };
      await tapKey('registration-avatar');
      await tester.tap(find.text('选择照片'));
      await tester.pumpAndSettle();
      await tapKey('registration-name');
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('请输入7字以内的有效昵称'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.enterText(find.byType(TextField), '取消昵称');
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      expect(find.text('取消昵称'), findsNothing);
      await tapKey('registration-name');
      await tester.enterText(find.byType(TextField), '新号搭子');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      await tapKey('registration-birthday');
      final picker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      expect(picker.maximumDate!.isBefore(DateTime.now()), isTrue);
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      expect(find.text('请选择你的生日'), findsOneWidget);
      await tapKey('registration-birthday');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      auth.failNext = true;
      await tester.tap(find.byKey(const ValueKey('registration-submit')));
      await tester.pumpAndSettle();
      expect(find.text('资料保存失败，请重试'), findsOneWidget);
      expect(find.text('新号搭子'), findsOneWidget);
      expect(auth.writes, 1);
      expect(completed, 0);
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byKey(const ValueKey('registration-submit')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('registration-submit')));
      await tester.pump();
      expect(auth.writes, 2);
      expect(completed, 0);
      expect(auth.saved!.gender, '女');
      expect(auth.saved!.name, '新号搭子');
      expect(auth.saved!.avatar, 'assets/mock/media/IMG025.jpg');
      expect(auth.saved!.birthday, DateTime(2000, 1, 1));
      auth.pending.complete();
      await tester.pumpAndSettle();
      expect(completed, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
