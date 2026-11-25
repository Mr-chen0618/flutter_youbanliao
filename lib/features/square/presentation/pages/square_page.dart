import '../../../messages/presentation/pages/dynamic_notifications_page.dart';
import '../../../../shared/widgets/layout/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../../../shared/widgets/layout/discovery_header.dart';
import '../widgets/square_video_feed.dart';
import '../providers/square_provider.dart';
import '../../../activity/presentation/providers/activity_detail_provider.dart';
import '../widgets/square_post_actions_widget.dart';
import 'square_publish_page.dart';

class SquarePage extends ConsumerStatefulWidget {
  const SquarePage({super.key, this.isActive = true});
  final bool isActive;

  @override
  ConsumerState<SquarePage> createState() => _SquarePageState();
}

class _SquarePageState extends ConsumerState<SquarePage> {
  DiscoverySection _section = DiscoverySection.discover;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(squareProvider);
    final followedState = ref.watch(followedActivityPublisherIdsProvider);
    final followedIds = followedState.value;
    final section = _section;
    final isVideo = section == DiscoverySection.video;
    final posts = state.posts
        .where(
          (post) =>
              post.isPublic &&
              (section == DiscoverySection.discover ||
                  (post.authorId == null
                      ? state.following.contains(post.author)
                      : followedIds?.contains(post.authorId) ?? false)),
        )
        .toList();
    final content = Column(
      children: [
        DiscoveryHeader(
          section: section,
          onSelected: (section) => setState(() => _section = section),
          isDark: isVideo,
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: '发布动态',
                color: isVideo ? Colors.white : const Color(0xFF333333),
                onPressed: () =>
                    AppNavigator.push(context, page: const SquarePublishPage()),
                icon: const Icon(Icons.add_circle_outline),
              ),
              IconButton(
                tooltip: '动态通知',
                onPressed: () => AppNavigator.push(
                  context,
                  page: const DynamicNotificationsPage(),
                ),
                icon: Transform.rotate(
                  angle: 0.5235987756,
                  child: AppImage(
                    src: 'assets/messages/messages_square_notification.svg',
                    width: 20.w,
                    height: 22.h,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isVideo
              ? SquareVideoFeed(isActive: widget.isActive)
              : RefreshIndicator(
                  onRefresh: ref.read(squareProvider.notifier).refresh,
                  child:
                      section == DiscoverySection.following &&
                          posts.isEmpty &&
                          followedState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : section == DiscoverySection.following &&
                            posts.isEmpty &&
                            followedState.hasError
                      ? Center(
                          child: TextButton(
                            onPressed: () => ref.invalidate(
                              followedActivityPublisherIdsProvider,
                            ),
                            child: const Text('加载失败，点击重试'),
                          ),
                        )
                      : posts.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 48.h),
                            AppEmptyState(
                              message: section == DiscoverySection.discover
                                  ? '暂无动态'
                                  : '关注的人发布动态后会显示在这里',
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          key: PageStorageKey(section),
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                          itemCount: posts.length,
                          separatorBuilder: (_, _) => SizedBox(height: 16.h),
                          itemBuilder: (_, index) => buildSquarePostCard(
                            context,
                            ref,
                            state,
                            posts[index],
                          ),
                        ),
                ),
        ),
      ],
    );
    if (isVideo) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: ColoredBox(
          color: Colors.black,
          child: SafeArea(bottom: false, child: content),
        ),
      );
    }
    return CompanionPageSurface(child: content);
  }
}
