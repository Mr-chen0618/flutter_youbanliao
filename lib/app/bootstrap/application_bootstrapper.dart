import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/device/device_info_service.dart';
import '../../core/logger/app_logger.dart';
import '../../core/network/headers/request_headers.dart';
import '../../core/network/providers/dio_interceptors_provider.dart';
import '../../core/network/providers/dio_provider.dart';
import '../../core/network/providers/network_providers.dart';
import '../../core/network/providers/offline_queue_provider.dart';
import '../config/app_globals.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'application_runner.dart';
import 'application_startup_page.dart';

/// 应用启动入口：只负责启动顺序，不放业务逻辑。
class ApplicationBootstrapper {
  ApplicationBootstrapper._();

  static final ApplicationBootstrapper instance = ApplicationBootstrapper._();

  late final ProviderContainer _container;
  bool _bootstrapped = false;

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    final binding = WidgetsFlutterBinding.ensureInitialized();
    binding.deferFirstFrame();

    _container = ProviderContainer();
    // 框架先开始布局，初始化完成后释放首帧，期间保留原生启动页。
    _run(
      ApplicationStartupPage(
        onSettled: binding.allowFirstFrame,
        initialize: () async {
          await _initBase();
          _initDependencies();
          await _container
              .read(authSessionProvider.future)
              .timeout(const Duration(seconds: 10));
        },
      ),
    );
  }

  Future<void> _initBase() async {
    globalPackageInfo = PackageInfo(
      appName: '友伴聊',
      packageName: '',
      version: '1.0.0',
      buildNumber: '1',
    );
    await Future.wait([
      _optionalPlatformTask('屏幕方向', () async {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }),
      _optionalPlatformTask('应用信息', () async {
        globalPackageInfo = await PackageInfo.fromPlatform().timeout(
          const Duration(seconds: 4),
        );
      }),
      _optionalPlatformTask('设备信息', () async {
        globalDeviceId =
            await DeviceInfoService.getDeviceId().timeout(
              const Duration(seconds: 4),
            ) ??
            '';
      }),
    ]);
    RequestHeaders.clearCache();
  }

  Future<void> _optionalPlatformTask(
    String name,
    Future<void> Function() task,
  ) async {
    try {
      await task().timeout(const Duration(seconds: 5));
    } catch (error, stack) {
      AppLogger.error('$name初始化失败，使用默认值', error, stack);
    }
  }

  void _initDependencies() {
    final container = _container;

    // 先初始化网络状态，再初始化 Dio 和依赖 Dio 的模块。
    container.read(networkMonitorProvider);
    container.read(dioProvider);
    container.read(dioInterceptorsProvider);
    container.read(offlineQueueManagerProvider);
  }

  void _run(Widget startPage) {
    runAppHandle(startPage, _container);
  }
}
