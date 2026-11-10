// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/config_env.dart';
import '../../core/network/client/dio_holder.dart';
import '../app.dart';

/// 运行应用
void runAppHandle(Widget startPage, ProviderContainer container) {
  Widget app = Application(startPage: startPage, showNetworkStatus: true);

  if (EnvConfig.enableUme) {
    PluginManager.instance
      ..register(const ShowCode())
      ..register(const DeviceInfoPanel())
      ..register(const MemoryInfoPage())
      ..register(CpuInfoPage())
      ..register(Console())
      ..register(Performance())
      ..register(DioInspector(dio: DioClientHolder.instance.dio));
    app = UMEWidget(icon: const FlutterLogo(), enable: true, child: app);
  }
  runApp(UncontrolledProviderScope(container: container, child: app));
}
