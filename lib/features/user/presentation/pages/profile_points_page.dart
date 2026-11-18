import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/app_empty_state.dart';

/// 个人积分余额与记录，当前使用既有本地零余额状态。
class ProfilePointsPage extends StatelessWidget {
  const ProfilePointsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppImage(
            src: 'assets/profile/profile_shop_backdrop.png',
            height: 255.h,
            fit: BoxFit.fill,
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48.h,
                child: NavigationToolbar(
                  centerMiddle: true,
                  leading: IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => Navigator.maybePop(context),
                    icon: AppImage(
                      src: 'assets/profile/profile_shop_back.svg',
                      width: 24.r,
                      height: 24.r,
                    ),
                  ),
                  middle: Text(
                    '我的积分',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                      sliver: SliverToBoxAdapter(child: _balanceCard()),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          '积分记录',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: const Color(0xFF999999),
                          ),
                        ),
                      ),
                    ),
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Align(
                        alignment: Alignment(0, -.38),
                        child: AppEmptyState(message: '暂无积分记录'),
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

  /// 同款余额卡保留设计的钱包与底部投影。
  Widget _balanceCard() => SizedBox(
    height: 102.h,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(
          child: AppImage(
            src: 'assets/profile/profile_shop_hero.svg',
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          right: 44.w,
          top: 81.h,
          child: AppImage(
            src: 'assets/profile/profile_shop_coin_shadow.png',
            width: 44.w,
            height: 14.h,
          ),
        ),
        Positioned(
          right: 19.w,
          top: -14.h,
          child: SizedBox.square(
            dimension: 95.r,
            child: ClipRect(
              child: OverflowBox(
                maxWidth: 117.8.r,
                maxHeight: 117.8.r,
                child: AppImage(
                  src: 'assets/profile/profile_points_wallet.png',
                  width: 117.8.r,
                  height: 117.8.r,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 18.w, top: 18.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我的积分',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFFC2971C),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                '0',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF342600),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
