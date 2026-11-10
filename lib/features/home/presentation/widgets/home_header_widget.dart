import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/gestures/app_tap_area.dart';
import '../constant/home_assets_constant.dart';
import '../constant/home_style_constant.dart';

class HomeHeaderWidget extends StatefulWidget {
  const HomeHeaderWidget({
    super.key,
    required this.city,
    required this.query,
    required this.onCity,
    required this.onSearch,
  });
  final String city;
  final String query;
  final VoidCallback onCity;
  final VoidCallback onSearch;

  @override
  State<HomeHeaderWidget> createState() => _HomeHeaderWidgetState();
}

class _HomeHeaderWidgetState extends State<HomeHeaderWidget> {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    child: SizedBox(
      height: 44.h,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              homeText(
                '真实搭子',
                20,
                weight: FontWeight.w800,
                color: Colors.black,
              ),
              Positioned(
                left: 24.w,
                top: 8.h,
                child: homeAsset(HomeAssets.brandBackgroundIcon, 7),
              ),
              Positioned(
                left: 24.w,
                top: 8.h,
                child: homeAsset(HomeAssets.brandForegroundIcon, 8),
              ),
            ],
          ),
          SizedBox(width: 6.w),
          AppTapArea(
            onTap: widget.onCity,
            child: Row(
              children: [
                homeText(widget.city, 14),
                SizedBox(width: 3.w),
                homeAsset(HomeAssets.cityDropdownIcon, 16),
              ],
            ),
          ),
          SizedBox(width: 22.w),
          Expanded(
            child: AppTapArea(
              onTap: widget.onSearch,
              child: Container(
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: const Color(0xCCFFFFFF),
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(40.r),
                ),
                child: Row(
                  children: [
                    homeAsset(HomeAssets.searchIcon, 20),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: homeText(
                        widget.query.isEmpty ? '搜索活动、用户' : widget.query,
                        15,
                        color: widget.query.isEmpty
                            ? const Color(0xFFCCCCCC)
                            : homeInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
