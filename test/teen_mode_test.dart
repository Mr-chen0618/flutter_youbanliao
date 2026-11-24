import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app_framework/features/teen/presentation/teen_mode_provider.dart';
import 'package:flutter_app_framework/features/teen/presentation/teen_mode_page.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/core/storage/mock_json_store.dart';
import 'package:flutter_app_framework/features/teen/data/teen_mode_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('根守卫读取中与读取失败均不泄漏平台内容', (tester) async {
    final repository = _ControlledTeenRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [teenModeRepositoryProvider.overrideWithValue(repository)],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            builder: (_, child) =>
                Stack(children: [TeenModeGate(child: child!)]),
            home: const Scaffold(body: Text('平台首页内容')),
          ),
        ),
      ),
    );
    expect(find.text('平台首页内容'), findsNothing);
    repository.initial.completeError(StateError('disk unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('平台首页内容'), findsNothing);
    expect(find.text('监护设置读取失败，点击重试'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('监护状态跨实例持久化，错误密码不能关闭，磁盘无明文密码', () async {
    final directory = await Directory.systemTemp.createTemp('teen-mode-test');
    addTearDown(() => directory.delete(recursive: true));
    TeenModeRepository repository() =>
        TeenModeRepository(MockJsonStore(directory: () async => directory));
    expect(await repository().enabled(), false);
    await repository().enable('5826');
    expect(await repository().enabled(), true);
    await expectLater(repository().enable('1111'), throwsStateError);
    final disk = await File(
      '${directory.path}/mock/device/teen_mode.json',
    ).readAsString();
    expect(disk.contains('5826'), false);
    expect(await repository().disable('0000'), false);
    expect(await repository().enabled(), true);
    expect(await repository().disable('5826'), true);
    expect(await repository().enabled(), false);
  });
  test('拒绝非四位数字密码', () async {
    final directory = await Directory.systemTemp.createTemp(
      'teen-mode-invalid',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = TeenModeRepository(
      MockJsonStore(directory: () async => directory),
    );
    await expectLater(repository.enable('abc1'), throwsArgumentError);
    await expectLater(repository.enable('123'), throwsArgumentError);
    expect(await repository.enabled(), false);
  });
}

class _ControlledTeenRepository extends TeenModeRepository {
  _ControlledTeenRepository() : super(MockJsonStore());
  final initial = Completer<bool>();
  @override
  Future<bool> enabled() => initial.future;
  @override
  Future<bool> disable(String pin) async => pin == '5826';
}
