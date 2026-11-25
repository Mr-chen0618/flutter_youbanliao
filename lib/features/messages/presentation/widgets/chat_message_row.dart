import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../data/messages_repository.dart';

class ChatMessageRow extends StatelessWidget {
  const ChatMessageRow({
    super.key,
    required this.entry,
    required this.avatar,
    this.onPlayVoice,
  });

  final ChatEntry entry;
  final String avatar;
  final VoidCallback? onPlayVoice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: entry.continuesGroup ? 8.h : 14.h),
      child: Row(
        textDirection: entry.isMine ? TextDirection.rtl : TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40.r,
            child: entry.continuesGroup
                ? null
                : AppImage(
                    src: avatar,
                    width: 40.r,
                    height: 40.r,
                    radius: 20.r,
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
    if (entry.kind == ChatEntryKind.gift && entry.gift != null) {
      return Container(
        width: 229.w,
        height: 72.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12.w,
              bottom: -10.h,
              child: Opacity(
                opacity: .2,
                child: AppImage(
                  src: 'assets/messages/messages_gift_card_decoration.png',
                  width: 70.w,
                  height: 63.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.r),
              child: Row(
                children: [
                  AppImage(
                    src: entry.gift!.asset,
                    width: 48.r,
                    height: 48.r,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          entry.isMine ? '送出礼物' : '收到礼物',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFFCCCCCC),
                          ),
                        ),
                        Text(
                          '${entry.gift!.name}x${entry.giftQuantity}',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: const Color(0xFF333333),
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
    }
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
    final color = entry.isMine ? const Color(0xFF333333) : Colors.white;
    final bubble = switch (entry.kind) {
      ChatEntryKind.voice => _mediaLabel(
        'voice_bubble',
        '${entry.durationSeconds ?? 0}″',
        color,
        reverse: entry.isMine,
      ),
      ChatEntryKind.voiceCall => _mediaLabel(
        'voice_call',
        entry.content,
        color,
      ),
      ChatEntryKind.videoCall => _mediaLabel(
        'video_bubble',
        entry.content,
        color,
      ),
      _ => Text(
        entry.content,
        style: TextStyle(color: color, fontSize: 14.sp, height: 21 / 14),
      ),
    };
    return Semantics(
      label: onPlayVoice == null ? null : '播放语音',
      button: onPlayVoice != null,
      child: Material(
        color: entry.isMine ? const Color(0xFFFFD152) : const Color(0xFF333333),
        borderRadius: BorderRadius.circular(13.r),
        child: InkWell(
          onTap: onPlayVoice,
          borderRadius: BorderRadius.circular(13.r),
          child: Container(
            constraints: BoxConstraints(maxWidth: 245.w),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            child: bubble,
          ),
        ),
      ),
    );
  }

  Widget _mediaLabel(
    String icon,
    String text,
    Color color, {
    bool reverse = false,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    textDirection: reverse ? TextDirection.rtl : TextDirection.ltr,
    children: [
      AppImage(
        src: 'assets/messages/messages_chat_$icon.svg',
        width: 22.r,
        height: 22.r,
        fit: BoxFit.contain,
        iconColor: color,
      ),
      SizedBox(width: 6.w),
      Flexible(
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 14.sp),
        ),
      ),
    ],
  );
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
