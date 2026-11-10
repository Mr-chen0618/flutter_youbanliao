import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/text/app_text.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';
import '../../data/square_repository.dart';
import 'square_category_badge_widget.dart';

class SquarePostCardWidget extends StatelessWidget {
  const SquarePostCardWidget({
    super.key,
    required this.post,
    required this.isLiked,
    required this.commentCount,
    required this.onLike,
    required this.onComment,
    required this.onMore,
    required this.onGreet,
    this.onDetail,
    this.onActivity,
    this.onProfile,
    this.showMore = true,
  });

  final SquarePost post;
  final bool showMore;
  final bool isLiked;
  final int commentCount;
  final VoidCallback onLike;
  final VoidCallback? onComment;
  final VoidCallback onMore;
  final VoidCallback? onGreet;
  final VoidCallback? onActivity;
  final VoidCallback? onDetail;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) => CompanionCardSurfaceWidget(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onProfile,
              child: AppImage(
                src: post.avatar,
                width: 40.r,
                height: 40.r,
                radius: 20.r,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(post.author, fontSize: 14.sp),
                  if (post.location.isNotEmpty)
                    AppText(
                      post.location,
                      fontSize: 10.sp,
                      color: const Color(0xFF999999),
                    ),
                ],
              ),
            ),
            if (onGreet != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26.r),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFDF87), Color(0xFFFFCE45)],
                  ),
                ),
                child: TextButton(
                  onPressed: onGreet,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    textStyle: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    minimumSize: Size(0, 30.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('打招呼'),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        if (!post.isMine) SquareCategoryBadgeWidget(category: post.category),
        SizedBox(height: 7.h),
        InkWell(
          onTap: onDetail,
          child: AppText(post.text, fontSize: 15.sp),
        ),
        if (onActivity != null)
          TextButton(onPressed: onActivity, child: const Text('查看关联活动')),
        if (post.photos.isNotEmpty) ...[
          SizedBox(height: 8.h),
          _photos(context),
        ],
        SizedBox(height: 8.h),
        AppText(
          post.isMine ? '刚刚发布' : '12小时前发布',
          fontSize: 11.sp,
          color: const Color(0xFFCCCCCC),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showMore)
              IconButton(
                tooltip: '更多操作',
                onPressed: onMore,
                icon: RotatedBox(
                  quarterTurns: 1,
                  child: _assetIcon('more_icon'),
                ),
              ),
            TextButton.icon(
              onPressed: onLike,
              icon: isLiked
                  ? Icon(Icons.favorite, size: 24.r, color: Colors.pinkAccent)
                  : _assetIcon('like_icon'),
              label: Text(
                post.likeCount + (isLiked ? 1 : 0) > 0
                    ? '${post.likeCount + (isLiked ? 1 : 0)}'
                    : '点赞',
              ),
              style: TextButton.styleFrom(
                foregroundColor: isLiked
                    ? Colors.pinkAccent
                    : const Color(0xFF999999),
              ),
            ),
            TextButton.icon(
              onPressed: onComment,
              icon: _assetIcon('comment_icon'),
              label: Text(commentCount > 0 ? '$commentCount' : '评论'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _assetIcon(String name) =>
      AppImage(src: squareAsset(name), width: 24.r, height: 24.r);

  Widget _photos(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final columns = post.photos.length <= 4 && post.photos.length != 3
          ? 2
          : 3;
      final gap = 4.w;
      final width = post.photos.length == 1
          ? constraints.maxWidth * 0.56
          : (constraints.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final photo in post.photos)
            GestureDetector(
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  child: InteractiveViewer(
                    child: AppImage(src: photo, fit: BoxFit.contain),
                  ),
                ),
              ),
              child: AppImage(
                src: photo,
                width: width,
                height: post.photos.length == 1 ? width * 198 / 178 : width,
                radius: 12.r,
              ),
            ),
        ],
      );
    },
  );
}
