import '../../../activity/presentation/pages/my_activities_page.dart';
import '../../../../shared/widgets/layout/companion_backdrop_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import '../../../../app/widgets/business_refresh.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../activity/presentation/providers/activity_detail_provider.dart';
import '../../../activity/presentation/pages/activity_reputation_page.dart';
import '../providers/profile_provider.dart';
import 'about_page.dart';
import 'my_posts_page.dart';
import 'profile_album_page.dart';
import 'profile_edit_page.dart';
import 'profile_points_page.dart';
import 'profile_relationships_page.dart';
import 'profile_settings_page.dart';
import 'profile_shop_page.dart';
import 'user_feedback_page.dart';
import 'growth_pages.dart';

/// 个人中心展示账号、关系和本人功能入口。
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const _coinBalance = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account =
        ref.watch(profileProvider).value ?? ref.read(userBlocProvider).state;
    final profile = account.profile;
    final following =
        ref.watch(followedActivityPublisherIdsProvider).value?.length ?? 0;
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CompanionBackdropWidget(),
          ),
          SafeArea(
            bottom: false,
            child: BusinessRefresh(
              scope: 'profile',
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 34.h, 16.w, 16.h),
                children: [
                  Center(
                    child: InkWell(
                      onTap: account.isSignedIn
                          ? () => AppNavigator.pushNamed<void>(
                              context,
                              RouteNames.userDetail(profile.id),
                              arguments: profile.id,
                            )
                          : null,
                      child: AppImage(
                        src: profile.avatar,
                        width: 86.r,
                        height: 86.r,
                        radius: 43.r,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  InkWell(
                    onTap: account.isSignedIn
                        ? () => AppNavigator.pushNamed<void>(
                            context,
                            RouteNames.userDetail(profile.id),
                            arguments: profile.id,
                          )
                        : null,
                    child: Text(
                      account.isSignedIn ? profile.name : '未登录',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (account.isSignedIn) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'ID: ${profile.displayId}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        for (final (index, entry) in [
                          ('关注', following),
                          ('粉丝', profile.followerIds.length),
                          ('好友', profile.friendIds.length),
                        ].indexed)
                          Expanded(
                            child: InkWell(
                              onTap: () => AppNavigator.push<void>(
                                context,
                                page: ProfileRelationshipsPage(initial: index),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${entry.$2}',
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    entry.$1,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _vip(context),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: _balance(context, '积分', '点击查看', 'points'),
                        ),
                        SizedBox(width: 9.w),
                        Expanded(
                          child: _balance(context, '金币', '点击充值', 'coins'),
                        ),
                      ],
                    ),
                    _activityEntry(context, joined: true),
                    _activityEntry(context, joined: false),
                    _entry(context, '编辑资料', 'edit', const ProfileEditPage()),
                    _entry(context, '我的视频秀', 'album', const VideoShowPage()),
                    _entry(
                      context,
                      '任务中心',
                      'reputation',
                      const TaskCenterPage(),
                    ),
                    _entry(context, '我的相册', 'album', const ProfileAlbumPage()),
                    _entry(context, '我的动态', 'posts', const MyPostsPage()),
                    _entry(
                      context,
                      '真人认证',
                      'verification',
                      const VerificationCenterPage(),
                    ),
                  ],
                  _entry(
                    context,
                    '活动信誉分',
                    'reputation',
                    const ActivityReputationPage(),
                  ),
                  _entry(context, '联系客服', 'support', const FeedbackPage()),
                  _entry(context, '关于我们', 'about', const AboutPage()),
                  _entry(
                    context,
                    '设置',
                    'settings',
                    const ProfileSettingsPage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vip(BuildContext context) => SizedBox(
    height: 69.h,
    child: Stack(
      fit: StackFit.expand,
      children: [
        _asset('vip_card', fit: BoxFit.fill),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VIP会员',
                      style: TextStyle(
                        color: const Color(0xFF004867),
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text('开通会员，享专属权益', style: TextStyle(fontSize: 13.sp)),
                  ],
                ),
              ),
              InkWell(
                onTap: () => AppNavigator.push<void>(
                  context,
                  page: const MembershipCenterPage(),
                ),
                child: SizedBox(
                  width: 76.w,
                  height: 30.h,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _asset('vip_button', fit: BoxFit.fill),
                      Center(
                        child: Text(
                          '前往开通',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _balance(
    BuildContext context,
    String title,
    String subtitle,
    String icon,
  ) => InkWell(
    onTap: () {
      if (icon == 'coins') {
        AppNavigator.push<void>(
          context,
          page: const CoinRechargePage(balance: _coinBalance),
        );
      } else {
        AppNavigator.push<void>(context, page: const ProfilePointsPage());
      }
    },
    child: SizedBox(
      height: 67.h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _asset('balance_card', fit: BoxFit.fill),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _asset(icon, width: 24.r, height: 24.r),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '我的$title',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          _asset('balance_chevron', width: 16.r, height: 16.r),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _activityEntry(BuildContext context, {required bool joined}) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _asset(
          joined ? 'joined' : 'published',
          width: 24.r,
          height: 24.r,
        ),
        title: Text(joined ? '我参与的活动' : '我发布的活动'),
        trailing: _asset('chevron', width: 16.r, height: 16.r),
        onTap: () => AppNavigator.push<void>(
          context,
          page: MyActivitiesPage(joined: joined),
        ),
      ),
      const Divider(height: 1, color: Color(0xFFF5F5F5)),
    ],
  );

  Widget _entry(BuildContext context, String title, String icon, Widget page) =>
      Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _asset(icon, width: 24.r, height: 24.r),
            title: Text(title),
            trailing: _asset('chevron', width: 16.r, height: 16.r),
            onTap: () => AppNavigator.push<void>(context, page: page),
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
        ],
      );

  Widget _asset(
    String name, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) => SvgPicture.asset(
    'assets/profile/profile_v2_$name.svg',
    width: width,
    height: height,
    fit: fit,
  );
}
