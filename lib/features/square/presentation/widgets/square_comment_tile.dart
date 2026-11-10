import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../data/model/square_comment.dart';

/// 评论详情与评论面板共享身份、时间和正文展示。
class SquareCommentTile extends StatelessWidget {
  const SquareCommentTile({super.key, required this.comment});
  final SquareComment comment;
  @override
  Widget build(BuildContext context) {
    final time = comment.createdAt?.toLocal();
    final label = time == null
        ? '历史评论'
        : '${time.year}年${time.month}月${time.day}日 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comment.authorAvatar.isNotEmpty)
            AppImage(
              src: comment.authorAvatar,
              width: 36.r,
              height: 36.r,
              radius: 18.r,
            )
          else
            CircleAvatar(radius: 18.r, child: const Icon(Icons.person_outline)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.authorName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF999999),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  comment.text,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
