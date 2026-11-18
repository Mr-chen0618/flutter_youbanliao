import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 数据已成功加载但没有可显示条目时使用的统一空态。
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.action,
    this.compact = false,
    this.foregroundColor = const Color(0xFF333333),
  });

  static const imageAsset = 'assets/shared/no_data.png';
  final String message;
  final Widget? action;
  final bool compact;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final dimension = (compact ? 72 : 138).r;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: compact ? 6.h : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imageAsset,
            width: dimension,
            height: dimension,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            cacheWidth: (dimension * MediaQuery.devicePixelRatioOf(context))
                .ceil(),
          ),
          SizedBox(height: compact ? 6.h : 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: foregroundColor, fontSize: 13.sp),
          ),
          if (action != null) ...[SizedBox(height: 16.h), action!],
        ],
      ),
    );
  }
}
