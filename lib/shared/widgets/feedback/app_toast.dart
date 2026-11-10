import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';

import '../../../app/config/app_globals.dart';
import '../../../core/device/device_info_service.dart';
import '../text/app_text.dart';

class AppToast {
  ///toast overlay entry
  static OverlayEntry? _entry;

  ///toast timer
  static Timer? _timer;

  /// 从异常/错误对象取出适合展示给用户的文案（去掉 Dart 默认的 `Exception: ` 前缀等）。
  static String messageOf(Object? error) {
    if (error == null) return '操作失败，请重试';
    if (error is PlatformException) return '操作失败，请检查权限后重试';
    if (error is FileSystemException) return '数据保存失败，请稍后重试';

    if (error is FormatException) {
      return error.message;
    }
    if (error is TimeoutException) {
      return error.message ?? '请求超时';
    }

    // 去掉一层或多层 `Exception: `（例如 catch 里又包了一层 Exception）
    var s = error.toString().trim();
    if (error is StateError) return error.message;
    if (error is ArgumentError) return error.message?.toString() ?? '输入内容有误';
    const prefix = 'Exception: ';
    while (s.startsWith(prefix)) {
      s = s.substring(prefix.length).trimLeft();
    }
    return s.isEmpty ? '未知错误' : s;
  }

  /// 使用 [messageOf] 解析后弹出 Toast
  static void showError(
    Object error, {
    Duration duration = const Duration(seconds: 2),
  }) {
    show(messageOf(error), duration: duration);
  }

  ///显示toast
  static void show(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _dismiss();

    final context = maybeGlobalContext;
    if (context == null) return;

    final overlay = Overlay.of(context, rootOverlay: true);

    _entry = OverlayEntry(builder: (_) => _ToastWidget(message: message));

    overlay.insert(_entry!);

    _timer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;

    try {
      _entry?.remove();
    } catch (_) {
      // 忽略重复 remove（兜底）
    }

    _entry = null;
  }
}

class _ToastWidget extends StatelessWidget {
  final String message;

  const _ToastWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: DeviceInfoService.screenWidth(context) * 0.8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppText(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
