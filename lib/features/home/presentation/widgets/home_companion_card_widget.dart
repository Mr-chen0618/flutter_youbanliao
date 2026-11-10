import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/gestures/app_tap_area.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../data/model/home_model.dart';
import '../constant/home_assets_constant.dart';
import '../constant/home_style_constant.dart';
import 'home_card_surface_widget.dart';

class HomeCompanionCardWidget extends StatefulWidget {
  const HomeCompanionCardWidget({
    super.key,
    required this.person,
    required this.onInvite,
    required this.inviteLabel,
    this.onProfile,
  });

  final HomeCompanionModel person;
  final VoidCallback? onInvite;
  final String inviteLabel;
  final VoidCallback? onProfile;

  @override
  State<HomeCompanionCardWidget> createState() =>
      _HomeCompanionCardWidgetState();
}

class _HomeCompanionCardWidgetState extends State<HomeCompanionCardWidget> {
  @override
  Widget build(BuildContext context) => HomeCardSurfaceWidget(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: widget.onProfile,
              child: AppImage(
                src: widget.person.avatar,
                width: 48.r,
                height: 48.r,
                radius: 24.r,
              ),
            ),
            if (widget.person.isOnline)
              Positioned(
                bottom: -4.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D29E),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    child: homeText('● 在线', 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: widget.onProfile,
                      child: homeText(
                        widget.person.name,
                        15,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.person.isVerified) ...[
                    SizedBox(width: 4.w),
                    homeAsset(HomeAssets.companionVerifiedIcon, 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F0FF),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: homeText(
                          '已认证',
                          9,
                          color: const Color(0xFF3798FF),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 5.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.person.gender case '男' || '女')
                      Icon(
                        widget.person.gender == '男' ? Icons.male : Icons.female,
                        size: 12.r,
                        color: widget.person.gender == '男'
                            ? const Color(0xFF506BFF)
                            : const Color(0xFFFF4288),
                      ),
                    homeText(
                      '${widget.person.age}岁',
                      11,
                      color: const Color(0xFFFF4288),
                    ),
                    Flexible(
                      child: homeText(
                        '｜${widget.person.heightCm}cm｜${widget.person.weightKg}kg｜${widget.person.city}',
                        11,
                        color: homeMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5.h),
              Row(
                children: [
                  for (final (index, photo) in widget.person.photos.indexed)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 4.w),
                        child: AppTapArea(
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (_) => Dialog(
                              child: AppImage(src: photo, fit: BoxFit.contain),
                            ),
                          ),
                          child: AppImage(
                            src: photo,
                            aspectRatio: 1,
                            radius: 12.r,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10.h),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAEC),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: homeText(
                          '可搭:${widget.person.interests.join('｜')}',
                          12,
                        ),
                      ),
                    ),
                    AppTapArea(
                      onTap: widget.onInvite,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFDF87), Color(0xFFFFCE45)],
                          ),
                          border: Border.all(color: Colors.white, width: 2.w),
                          borderRadius: BorderRadius.circular(40.r),
                        ),
                        child: homeText(
                          widget.inviteLabel,
                          14,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
