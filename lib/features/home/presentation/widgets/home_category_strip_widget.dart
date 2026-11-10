import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/gestures/app_tap_area.dart';
import '../../data/model/home_model.dart';
import '../constant/home_style_constant.dart';

class HomeCategoryStripWidget extends StatefulWidget {
  const HomeCategoryStripWidget({
    super.key,
    required this.categories,
    required this.onTap,
  });
  final List<HomeCategoryModel> categories;
  final ValueChanged<String> onTap;

  @override
  State<HomeCategoryStripWidget> createState() =>
      _HomeCategoryStripWidgetState();
}

class _HomeCategoryStripWidgetState extends State<HomeCategoryStripWidget> {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 10.h),
    child: SizedBox(
      height: 44.r + 6.h + 26.sp,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: widget.categories.length,
        separatorBuilder: (_, _) => SizedBox(width: 22.w),
        itemBuilder: (context, index) {
          final item = widget.categories[index];
          return Semantics(
            button: true,
            child: AppTapArea(
              onTap: () => widget.onTap(item.id),
              child: Column(
                children: [
                  homeCategoryIcon(item.id, 44),
                  SizedBox(height: 6.h),
                  homeText(
                    item.label,
                    11,
                    color: const Color(0xFF666666),

                    lineHeight: 24 / 11,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
