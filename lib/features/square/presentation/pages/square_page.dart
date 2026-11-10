import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../../../shared/widgets/layout/discovery_header.dart';
import '../../data/square_repository.dart';
import '../providers/square_provider.dart';
import '../../../activity/presentation/providers/activity_detail_provider.dart';
import '../widgets/square_post_actions_widget.dart';
import 'square_publish_page.dart';

class SquarePage extends ConsumerStatefulWidget {
  const SquarePage({super.key});

  @override
  ConsumerState<SquarePage> createState() => _SquarePageState();
}

class _SquarePageState extends ConsumerState<SquarePage> {
  DiscoverySection _section = DiscoverySection.discover;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(squareProvider);
    final followedIds = ref.watch(followedActivityPublisherIdsProvider).value;
    final section = _section;
    final isVideo = section == DiscoverySection.video;
    final posts = state.posts
        .where(
          (post) =>
              !post.isPrivate &&
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
          action: IconButton(
            tooltip: '发布动态',
            color: isVideo ? Colors.white : const Color(0xFF333333),
            onPressed: () =>
                AppNavigator.push(context, page: const SquarePublishPage()),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ),
        Expanded(
          child: isVideo
              ? _video()
              : RefreshIndicator(
                  onRefresh: ref.read(squareProvider.notifier).refresh,
                  child: posts.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 150),
                            Center(child: Text('关注的人发布动态后会显示在这里')),
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

  Widget _video() => Stack(
    fit: StackFit.expand,
    children: [
      AppImage(src: squareAsset('video_cover')),
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
          child: Row(
            children: [
              AppImage(
                src: squareAsset('video_avatar'),
                width: 54.r,
                height: 54.r,
                radius: 27.r,
              ),
              SizedBox(width: 8.w),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '用户昵称',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    Text(
                      '真人认证用户，喜欢咖啡和电影',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        right: 16.w,
        bottom: 120.h,
        child: Column(
          children: [
            IconButton(
              tooltip: '喜欢',
              color: ref.watch(squareProvider).videoLiked
                  ? Colors.pinkAccent
                  : Colors.white,
              icon: const Icon(Icons.thumb_up),
              onPressed: () =>
                  ref.read(squareProvider.notifier).toggleVideoLike(),
            ),
            IconButton(
              tooltip: '收藏',
              color: ref.watch(squareProvider).videoSaved
                  ? Colors.amber
                  : Colors.white,
              icon: const Icon(Icons.star),
              onPressed: () =>
                  ref.read(squareProvider.notifier).toggleVideoSave(),
            ),
          ],
        ),
      ),
    ],
  );
}
