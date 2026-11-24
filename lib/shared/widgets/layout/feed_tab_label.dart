import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../images/app_image.dart';

/// 首页与广场共用的星光弧线选中标签。
class FeedTabLabel extends StatelessWidget {
  const FeedTabLabel({
    super.key,
    required this.label,
    required this.selected,
    this.isDark = false,
  });
  final String label;
  final bool selected, isDark;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: selected ? 17.sp : 15.sp,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: isDark
              ? (selected ? Colors.white : Colors.white70)
              : (selected ? const Color(0xFF333333) : const Color(0xFF999999)),
        ),
      ),
      if (selected)
        Positioned(
          right: -10.w,
          top: 0,
          child: AppImage(
            src: 'assets/home/home_feed_selected_icon.png',
            width: 19.r,
            height: 19.r,
            fit: BoxFit.contain,
          ),
        ),
    ],
  );
}
