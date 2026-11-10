import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../providers/square_provider.dart';
import '../widgets/square_post_actions_widget.dart';

/// 展示当前账号的动态，并保留广场卡片的互动能力。
class MyPostsPage extends ConsumerWidget {
  const MyPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(squareProvider);
    final posts = state.posts.where((post) => post.isMine).toList();
    final activityPosts = posts
        .where((post) => post.activityId != null)
        .toList();
    final privatePosts = posts.where((post) => post.isPrivate).toList();
    final sections = [posts, activityPosts, privatePosts];
    const labels = ['全部动态', '组队足迹', '仅自己可见'];
    return CompanionPageSurface(
      title: '我的动态',
      child: DefaultTabController(
        length: sections.length,
        child: Column(
          children: [
            // 动态总览
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/profile/profile_about_planet.svg',
                    width: 24.r,
                    height: 24.r,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '把喜欢的日子，分享出来',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${posts.length} 条动态 · 记录和友伴的每次相遇',
                          style: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 动态分类
            TabBar(
              dividerColor: Colors.transparent,
              labelPadding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: const Color(0xFFFFCE43),
              labelColor: const Color(0xFF333333),
              unselectedLabelColor: const Color(0xFF999999),
              tabs: [
                for (final (index, label) in labels.indexed)
                  Tab(text: '$label ${sections[index].length}'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final section in sections)
                    RefreshIndicator(
                      onRefresh: ref.read(squareProvider.notifier).refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(16.w),
                        children: [
                          if (section.isEmpty)
                            const Center(child: Text('暂无动态')),
                          for (final post in section)
                            Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: buildSquarePostCard(
                                context,
                                ref,
                                state,
                                post,
                              ),
                            ),
                          Text(
                            '每个平凡日常，都值得被记住',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF999999),
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
      ),
    );
  }
}
