import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app_framework/main.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/auth/data/mock/auth_mock_repository.dart';
import 'package:flutter_app_framework/features/auth/data/request-model/phone_login_request.dart';
import 'package:flutter_app_framework/features/auth/presentation/pages/auth_gate.dart';
import 'package:flutter_app_framework/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_app_framework/features/user/data/model/member_profile.dart';

Future<void> drain(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets(
    'AuthGate restores account scope, detail routes keep scope, signout destroys stack',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('gate_nav_'),
      ))!;
      addTearDown(() => directory.delete(recursive: true));
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
      final store = _GateStore(seeds);
      final auth = AuthMockRepository(store, delay: Duration.zero);
      final session = await tester.runAsync(() async {
        await auth.sendCode('14444000003');
        final s = await auth.login(
          const PhoneLoginRequest('14444000003', '8888'),
        );
        await auth.completeProfile(
          s.accountId,
          MemberProfile(
            id: s.accountId,
            name: '导航测试用户',
            avatar: 'assets/mock/media/IMG025.jpg',
            signature: '',
            gender: '女',
            birthday: DateTime(2000),
            city: '深圳',
            interests: [],
            tags: [],
            following: 0,
            followers: 0,
            friends: 0,
          ),
        );
        return s;
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mockJsonStoreProvider.overrideWithValue(store),
            authRepositoryProvider.overrideWithValue(auth),
          ],
          child: const Application(startPage: AuthGate()),
        ),
      );
      await drain(tester);
      expect(find.text('登录/注册'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('main-tab-3')));
      await drain(tester);
      expect(find.text('导航测试用户'), findsOneWidget);
      expect(find.text('ID: ${session!.accountId}'), findsOneWidget);
      await tester.tap(find.text('编辑资料').hitTestable());
      await drain(tester);
      await tester.tap(find.text('昵称').hitTestable());
      await drain(tester);
      await tester.enterText(find.byType(TextField), '导航改名');
      await tester.tap(find.text('保存').hitTestable());
      await drain(tester);
      expect(find.text('导航改名'), findsOneWidget);
      await tester.pageBack();
      await drain(tester);
      await tester.scrollUntilVisible(
        find.text('设置'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await drain(tester);
      await tester.tap(find.text('设置').hitTestable());
      await drain(tester);
      await tester.tap(find.text('退出登录').hitTestable());
      await drain(tester);
      await tester.tap(find.widgetWithText(FilledButton, '退出登录'));
      await drain(tester);
      expect(find.text('确认退出登录？'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '取消'));
      await drain(tester);
      expect(
        await tester.runAsync(() async => (await auth.restore())!.accountId),
        session.accountId,
      );
      await tester.tap(find.widgetWithText(FilledButton, '退出登录'));
      await drain(tester);
      await tester.tap(find.widgetWithText(TextButton, '确认退出'));
      await drain(tester);
      expect(find.text('登录/注册'), findsOneWidget);
      expect(find.text('导航改名'), findsNothing);
      expect(find.byTooltip('返回').hitTestable(), findsNothing);
      expect(await tester.runAsync(auth.restore), isNull);
      expect(tester.takeException(), isNull);
    },
  );
}

class _GateStore extends MockJsonStore {
  _GateStore(this.seeds);
  final Map<String, String> seeds;
  final data = <String, String>{};
  @override
  Future<void> initialize(String path, Map<String, dynamic> value) async {
    data.putIfAbsent(path, () => jsonEncode(value));
  }

  @override
  Future<bool> exists(String path) async => data.containsKey(path);
  @override
  Future<void> delete(String path) async {
    data.remove(path);
  }

  @override
  Future<T> seed<T>(String path, T Function(Object?) decode) async =>
      decode(jsonDecode(seeds[path]!));
  @override
  Future<T> read<T>(String path, T Function(Object?) decode) async =>
      decode(jsonDecode(data[path] ??= seeds[path]!));
  @override
  Future<void> write(String path, Map<String, dynamic> value) async {
    data[path] = jsonEncode(value);
  }

  @override
  Future<void> update<T>(
    String path,
    T Function(Object?) decode,
    Map<String, dynamic> Function(T) change,
  ) async {
    data[path] = jsonEncode(change(await read(path, decode)));
  }
}
