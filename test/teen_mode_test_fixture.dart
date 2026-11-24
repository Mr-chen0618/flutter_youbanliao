import 'package:flutter_app_framework/features/teen/presentation/teen_mode_provider.dart';

/// 普通页面回归使用确定的关闭状态；监护守卫另有专门磁盘和Widget测试。
final disabledTeenModeOverride = teenModeProvider.overrideWith(
  _DisabledTeenMode.new,
);

class _DisabledTeenMode extends TeenModeController {
  @override
  Future<bool> build() async => false;
}
