import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/text/app_text.dart';

/// 动态类型标签，图标和配色对应Figma 3163:24161的八种分类。
class SquareCategoryBadgeWidget extends StatelessWidget {
  const SquareCategoryBadgeWidget({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final (icon, label, background, foreground) = switch (category
        .trim()
        .replaceAll('搭子', '')) {
      '美食' || 'food' => ('food', '美食', 0xFFFFF4F4, 0xFFF9544A),
      '探店' || 'shops' => ('shops', '探店', 0xFFFFF4F4, 0xFFFE5D45),
      '户外' || 'outdoors' => ('outdoors', '户外', 0xFFE5FFFC, 0xFF17CAB7),
      '运动' || 'sports' => ('sports', '运动', 0xFFE8F4FF, 0xFF2198FD),
      '旅游' || 'travel' => ('travel', '旅游', 0xFFFFFAE7, 0xFFE0A800),
      '摄影' || 'photo' => ('photo', '摄影', 0xFFE9FBFF, 0xFF00C3FF),
      '研学' || 'study' => ('study', '研学', 0x1A476CFF, 0xFFBB62F5),
      '桌游' || 'games' => ('games', '桌游', 0xFFFFF8E3, 0xFFDAA500),
      _ => (null, category, 0xFFF4F4F4, 0xFF666666),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Color(background),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppImage(
              src: 'assets/square/square_category_${icon}_icon.png',
              width: 18.r,
              height: 18.r,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 4.w),
          ],
          AppText(label, fontSize: 12.sp, color: Color(foreground)),
        ],
      ),
    );
  }
}
