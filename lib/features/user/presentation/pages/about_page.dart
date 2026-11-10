import '../../../../app/config/legal_links.dart';
import '../../../../shared/pages/app_web_page.dart';
import '../../../../app/navigation/app_navigator.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';

/// 展示友伴品牌、社区主张及应用版本。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _principles = [
    ('planet', '同频，比热闹更重要', '从共同热爱出发，自然找到话题。'),
    ('shield', '真实，是相遇的起点', '认真认证、真诚表达，放心做自己。'),
    ('headset', '友善，让连接更长久', '尊重不同，守时赴约，彼此照顾。'),
  ];

  @override
  Widget build(BuildContext context) => CompanionPageSurface(
    title: '关于我们',
    child: ListView(
      padding: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 16.h),
      children: [
        // 品牌介绍
        Column(
          children: [
            Container(
              width: 76.r,
              height: 76.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE486),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: _icon('planet', 36),
            ),
            SizedBox(height: 12.h),
            Text(
              '友伴',
              style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.h),
            const Text('有趣的生活，不必一个人'),
            SizedBox(height: 12.h),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Text(
                  '版本 1.0.0',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF999999),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 34.h),
        CompanionCardSurfaceWidget(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '从共同的喜欢，到真实的相遇',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.h),
              Text(
                '友伴是一个从兴趣出发的社交组队社区。无论是山野徒步、城市探店，还是一场轻松的桌游局，我们希望帮你遇见合拍的搭子，让每个「想去」都变成「一起去」。',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        // 社区主张
        const Text('我们相信', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 10.h),
        CompanionCardSurfaceWidget(
          padding: EdgeInsets.all(14.w),
          child: Column(
            children: [
              for (final (index, (icon, title, note))
                  in _principles.indexed) ...[
                if (index > 0) SizedBox(height: 16.h),
                Row(
                  children: [
                    _icon(icon, 26),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            note,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16.h),
        // 协议入口与版本检查
        CompanionCardSurfaceWidget(
          padding: EdgeInsets.all(14.w),
          child: Column(
            children: [
              _row(
                '用户协议',
                const Icon(Icons.chevron_right),
                () => AppNavigator.push(
                  context,
                  page: const AppWebPage(
                    title: '用户协议',
                    url: LegalLinks.userAgreementUrl,
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF4F4F4)),
              _row(
                '隐私政策',
                const Icon(Icons.chevron_right),
                () => AppNavigator.push(
                  context,
                  page: const AppWebPage(
                    title: '隐私政策',
                    url: LegalLinks.privacyPolicyUrl,
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF4F4F4)),
              _row(
                '检查更新',
                Text(
                  '已是最新版本',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF999999),
                  ),
                ),
                () => _notice(context, '已是最新版本'),
              ),
            ],
          ),
        ),
        SizedBox(height: 22.h),
        Text(
          '友伴 · 让每个热爱都有同行的人\nCopyright © 2026 友伴 All Rights Reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.sp,
            height: 1.8,
            color: const Color(0xFF999999),
          ),
        ),
      ],
    ),
  );

  /// 应用信息列表项。
  Widget _row(String title, Widget trailing, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 52.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(title), trailing],
      ),
    ),
  );

  void _notice(BuildContext context, String text) => AppToast.show(text);

  Widget _icon(String name, double size) => SvgPicture.asset(
    'assets/profile/profile_about_$name.svg',
    width: size.r,
    height: size.r,
  );
}
