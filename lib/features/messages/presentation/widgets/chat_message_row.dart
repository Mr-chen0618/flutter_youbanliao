import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../data/messages_repository.dart';

class ChatMessageRow extends StatelessWidget {
  const ChatMessageRow({super.key, required this.entry, required this.avatar});

  final ChatEntry entry;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: entry.continuesGroup ? 8.h : 14.h),
      child: Row(
        textDirection: entry.isMine ? TextDirection.rtl : TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36.r,
            child: entry.continuesGroup
                ? null
                : AppImage(
                    src: avatar,
                    width: 36.r,
                    height: 36.r,
                    radius: 18.r,
                  ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Column(
              crossAxisAlignment: entry.isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _bubble(context),
                if (entry.showDelivery)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      '已送达',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context) {
    if (entry.kind == ChatEntryKind.photo) {
      return GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            child: InteractiveViewer(
              child: AppImage(src: entry.content, fit: BoxFit.contain),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: SizedBox(
            width: 176.w,
            height: 118.h,
            child: entry.content == chatSamplePhoto
                ? LayoutBuilder(
                    builder: (_, constraints) {
                      // Keep the artwork framed like the cropped Figma image fill.
                      final width = constraints.maxWidth;
                      final height = constraints.maxHeight;
                      return Stack(
                        children: [
                          Positioned(
                            left: -width * .3666,
                            top: -height * .5086,
                            width: width * 1.5,
                            height: height * 2.25,
                            child: AppImage(
                              src: entry.content,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : AppImage(src: entry.content),
          ),
        ),
      );
    }
    if (entry.invitation case final invitation?) {
      return _ChatInvitationCard(invitation: invitation);
    }
    return Container(
      constraints: BoxConstraints(maxWidth: 260.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: entry.isMine ? const Color(0xFFFFF1BB) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(entry.isMine ? 14.r : 4.r),
          topRight: Radius.circular(entry.isMine ? 4.r : 14.r),
          bottomLeft: Radius.circular(14.r),
          bottomRight: Radius.circular(14.r),
        ),
      ),
      child: Text(
        entry.content,
        style: TextStyle(
          color: const Color(0xFF333333),
          fontSize: 14.sp,
          height: 22 / 14,
        ),
      ),
    );
  }
}

class _ChatInvitationCard extends StatelessWidget {
  const _ChatInvitationCard({required this.invitation});
  final ChatInvitation invitation;

  @override
  Widget build(BuildContext context) => Container(
    width: 272.w,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFECEDEF)),
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: const Color(0xFFFFF8E0),
          child: Padding(
            padding: EdgeInsets.all(15.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  invitation.description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF946B16),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '活动类型  ${invitation.category}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF876E45),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(15.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (invitation.activityId case final id?)
                TextButton(
                  onPressed: () => AppNavigator.pushNamed<void>(
                    context,
                    RouteNames.activityDetail(id),
                    arguments: id,
                  ),
                  child: const Text('查看活动详情'),
                ),
              _details('活动时间', '${invitation.date}\n${invitation.time}'),
              SizedBox(height: 12.h),
              _details(
                '活动地址',
                '${invitation.district}\n${invitation.meetingPoint}',
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _details(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(color: const Color(0xFF999999), fontSize: 11.sp),
      ),
      SizedBox(height: 4.h),
      Text(
        value,
        style: TextStyle(fontSize: 13.sp, height: 20 / 13),
      ),
    ],
  );
}
