import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/gestures/app_tap_area.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../data/model/home_model.dart';
import '../constant/home_assets_constant.dart';
import '../constant/home_style_constant.dart';
import 'home_card_surface_widget.dart';

class HomeActivityCardWidget extends StatefulWidget {
  const HomeActivityCardWidget({
    super.key,
    required this.activity,
    required this.onTap,
  });
  final HomeActivityModel activity;
  final VoidCallback onTap;

  @override
  State<HomeActivityCardWidget> createState() => _HomeActivityCardWidgetState();
}

class _HomeActivityCardWidgetState extends State<HomeActivityCardWidget> {
  @override
  Widget build(BuildContext context) {
    final outdoors = widget.activity.categoryId == 'outdoors';
    return AppTapArea(
      onTap: widget.onTap,
      child: HomeCardSurfaceWidget(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: outdoors
                          ? const Color(0xFFE0F5ED)
                          : const Color(0xFFEAEDFF),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        homeCategoryIcon(widget.activity.categoryId, 16),
                        SizedBox(width: 4.w),
                        homeText(
                          widget.activity.category,
                          12,
                          color: outdoors
                              ? const Color(0xFF00B68D)
                              : const Color(0xFF506BFF),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6.h),
                  homeText(widget.activity.title, 16, weight: FontWeight.w500),
                  SizedBox(height: 4.h),
                  homeText(widget.activity.description, 11, color: homeMuted),
                  SizedBox(height: 8.h),
                  _ActivityMeta(
                    icon: HomeAssets.activityTimeIcon,
                    text: '发布时间：${widget.activity.time}',
                  ),
                  SizedBox(height: 6.h),
                  _ActivityMeta(
                    icon: HomeAssets.activityLocationIcon,
                    text: '地址：${widget.activity.location}',
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            AppImage(
              src: widget.activity.image,
              width: 82.r,
              height: 82.r,
              radius: 8.r,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityMeta extends StatelessWidget {
  const _ActivityMeta({required this.icon, required this.text});
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      homeAsset(icon, 16),
      SizedBox(width: 8.w),
      Expanded(child: homeText(text, 11, color: homeMuted)),
    ],
  );
}
