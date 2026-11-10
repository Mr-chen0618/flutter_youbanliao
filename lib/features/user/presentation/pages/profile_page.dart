import '../../../../app/widgets/business_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../../activity/presentation/pages/activity_reputation_page.dart';
import '../../../activity/presentation/pages/my_activities_page.dart';
import '../providers/profile_provider.dart';
import 'about_page.dart';
import 'my_posts_page.dart';
import 'profile_edit_page.dart';
import 'profile_settings_page.dart';
import 'user_feedback_page.dart';
import 'user_verification_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        (ref.watch(profileProvider).value ?? ref.read(userBlocProvider).state);
    final profile = state.profile;
    return CompanionPageSurface(
      child: BusinessRefresh(
        scope: 'profile',
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 16.h),
          children: [
            Row(
              children: [
                if (state.isSignedIn)
                  AppImage(
                    src: profile.avatar,
                    width: 78.r,
                    height: 78.r,
                    radius: 39.r,
                  )
                else
                  CircleAvatar(
                    radius: 39.r,
                    child: const Icon(Icons.person_outline),
                  ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.isSignedIn ? profile.name : '未登录',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (state.isSignedIn) ...[
                        SizedBox(height: 4.h),
                        Text(
                          'ID: ${profile.displayId}',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Wrap(
                          spacing: 12.w,
                          runSpacing: 4.h,
                          children: [
                            _stat('关注', profile.following),
                            _stat('粉丝', profile.followers),
                            _stat('好友', profile.friends),
                          ],
                        ),
                      ] else
                        const Text('请重新登录'),
                    ],
                  ),
                ),
              ],
            ),
            if (state.isSignedIn) ...[SizedBox(height: 16.h), _teams(context)],
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFF1F1F1), width: 2.w),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                children: [
                  if (state.isSignedIn) ...[
                    _entry(
                      context,
                      'edit_icon',
                      '编辑资料',
                      const ProfileEditPage(),
                    ),
                    _entry(
                      context,
                      'verification_icon',
                      '我的认证',
                      const UserVerificationPage(),
                    ),
                    _entry(context, 'posts_icon', '我的动态', const MyPostsPage()),
                  ],
                  _entry(context, 'support_icon', '联系客服', const FeedbackPage()),
                  _entry(context, 'about_icon', '关于我们', const AboutPage()),
                  if (state.isSignedIn)
                    _entry(
                      context,
                      'reputation_icon',
                      '活动信誉分',
                      const ActivityReputationPage(),
                    ),
                  _entry(
                    context,
                    'settings_icon',
                    '设置',
                    const ProfileSettingsPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int count) => Text.rich(
    TextSpan(
      style: TextStyle(fontSize: 14.sp, color: const Color(0xFF333333)),
      children: [
        TextSpan(
          text: '$label ',
          style: const TextStyle(color: Color(0xFF999999)),
        ),
        TextSpan(
          text: '$count',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );

  Widget _teams(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF098), Color(0xFFFFF5BF)],
            ),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: AppImage(
          src: 'assets/profile/profile_teams_background.png',
          width: 220.w,
          height: 53.h,
          fit: BoxFit.fill,
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 6.h),
            child: Text(
              '我的组队',
              style: TextStyle(
                color: const Color(0xFF783C14),
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          CompanionCardSurfaceWidget(
            child: Row(
              children: [
                Expanded(
                  child: _teamAction(
                    context,
                    'published_icon',
                    '我发布的',
                    const MyActivitiesPage(),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _teamAction(
                    context,
                    'joined_icon',
                    '我参加的',
                    const MyActivitiesPage(joined: true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );

  Widget _teamAction(
    BuildContext context,
    String icon,
    String title,
    Widget page,
  ) => Material(
    color: const Color(0xFFF5F5F5),
    borderRadius: BorderRadius.circular(12.r),
    child: InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => AppNavigator.push(context, page: page, name: title),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: Row(
          children: [
            _icon(icon, 24),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                title,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _entry(BuildContext context, String icon, String title, Widget page) =>
      InkWell(
        onTap: () => AppNavigator.push(context, page: page),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 60.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              children: [
                _icon(icon, 28),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 15.sp,
                    ),
                  ),
                ),
                RotatedBox(quarterTurns: 3, child: _icon('chevron_icon', 20)),
              ],
            ),
          ),
        ),
      );

  Widget _icon(String name, double size) => AppImage(
    src: 'assets/profile/profile_$name.png',
    width: size.r,
    height: size.r,
    fit: BoxFit.contain,
  );
}
