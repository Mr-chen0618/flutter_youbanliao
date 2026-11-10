import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/auth_gate.dart';

/// 初始化期间保留系统原生启动页；成功或失败后释放首帧，不播放品牌页。
class ApplicationStartupPage extends StatefulWidget {
  const ApplicationStartupPage({
    super.key,
    required this.initialize,
    this.onSettled,
  });

  final Future<void> Function() initialize;
  final VoidCallback? onSettled;

  @override
  State<ApplicationStartupPage> createState() => _ApplicationStartupPageState();
}

class _ApplicationStartupPageState extends State<ApplicationStartupPage> {
  bool _ready = false;
  bool _failed = false;
  bool _released = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  Future<void> _start() async {
    setState(() {
      _ready = false;
      _failed = false;
    });
    try {
      await widget.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted && !_released) {
        _released = true;
        final onSettled = widget.onSettled;
        // 下一帧已构建实际入口或错误页后，才交给引擎替换原生启动页。
        WidgetsBinding.instance.addPostFrameCallback((_) => onSettled?.call());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('启动失败，请重试'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _start, child: const Text('重新加载')),
              ],
            ),
          ),
        ),
      );
    }
    return _ready
        ? const AuthGate()
        : const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
