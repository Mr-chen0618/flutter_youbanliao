import '../../../../app/widgets/business_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../data/messages_repository.dart';
import '../providers/messages_provider.dart';

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messagesProvider);
    final notifier = ref.read(messagesProvider.notifier);
    return CompanionPageSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48.h,
            child: Padding(
              padding: EdgeInsets.only(left: 16.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 13.w),
                      child: Text(
                        '消息',
                        style: TextStyle(
                          color: const Color(0xFF333333),
                          fontSize: 17.sp,
                          height: 24 / 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.95.sp,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2.h,
                      right: 0,
                      child: AppImage(
                        src: messagesAsset('title_decoration_icon'),
                        width: 17.25.w,
                        height: 23.25.h,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
            child: Row(
              children: [
                for (final notice in MessageNotice.values)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        notifier.readNotice(notice);
                        AppNavigator.push(
                          context,
                          page: CompanionPageSurface(
                            title: notice.label,
                            child: BusinessRefresh(
                              scope: 'messages',
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  ListTile(
                                    title: Text(
                                      state.notices[notice.name] ?? '暂无消息',
                                    ),
                                    subtitle: const Text('12:12'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          name: 'message-notice-${notice.name}',
                        );
                      },
                      child: Column(
                        children: [
                          _UnreadBadge(
                            count: state.readNotices.contains(notice)
                                ? 0
                                : (state.noticeUnread[notice.name] ?? 0),
                            child: AppImage(
                              src: messagesAsset('${notice.icon}_icon'),
                              width: 52.r,
                              height: 52.r,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(notice.label, style: TextStyle(fontSize: 12.sp)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _ThreadList(threads: state.threads)),
        ],
      ),
    );
  }
}

class _ThreadList extends ConsumerWidget {
  const _ThreadList({required this.threads});
  final List<MessageThread> threads;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (threads.isEmpty) {
      return BusinessRefresh(
        scope: 'messages',
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('暂无会话')),
            ),
          ],
        ),
      );
    }
    return BusinessRefresh(
      scope: 'messages',
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: threads.length,
        itemBuilder: (_, index) {
          final thread = threads[index];
          return InkWell(
            key: ValueKey(thread.id),
            onTap: () {
              ref.read(messagesProvider.notifier).readThread(thread.id);
              AppNavigator.pushNamed<void>(
                context,
                RouteNames.chat(thread.id),
                arguments: thread.id,
              );
            },
            child: Row(
              children: [
                _UnreadBadge(
                  count: thread.unread,
                  child: AppImage(
                    src: thread.avatar,
                    width: 52.r,
                    height: 52.r,
                    radius: 26.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(minHeight: 76.h),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFFEFE7D6),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                thread.name,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                thread.preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          thread.time,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFFD4D9DD),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count, required this.child});
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      child,
      if (count > 0)
        Positioned(
          top: -4.h,
          right: -8.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFF416D),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: TextStyle(color: Colors.white, fontSize: 11.sp),
            ),
          ),
        ),
    ],
  );
}
