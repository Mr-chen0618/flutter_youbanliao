import '../../../../shared/widgets/layout/app_empty_state.dart';
import '../../../../app/widgets/business_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../widgets/messages_page_surface.dart';
import '../../data/messages_repository.dart';
import '../providers/messages_provider.dart';

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messagesProvider);
    final notifier = ref.read(messagesProvider.notifier);
    int unread(MessageNotice notice) => state.readNotices.contains(notice)
        ? 0
        : state.noticeUnread[notice.name] ?? 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppImage(
            src: 'assets/messages/messages_v2_backdrop.svg',
            height: 255.h,
            fit: BoxFit.fill,
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16.w, right: 10.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '聊天',
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            AppImage(
                              src:
                                  'assets/messages/messages_v2_title_accent.svg',
                              width: 24.w,
                              height: 8.h,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<MessageNotice>(
                      tooltip: '消息通知',
                      icon: _UnreadBadge(
                        count: MessageNotice.values.fold<int>(
                          0,
                          (sum, notice) => sum + unread(notice),
                        ),
                        child: const Icon(Icons.notifications_none_rounded),
                      ),
                      itemBuilder: (_) => [
                        for (final notice in MessageNotice.values)
                          PopupMenuItem(
                            value: notice,
                            child: Row(
                              children: [
                                _UnreadBadge(
                                  count: unread(notice),
                                  child: AppImage(
                                    src: messagesAsset('${notice.icon}_icon'),
                                    width: 26.r,
                                    height: 26.r,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Text(notice.label),
                              ],
                            ),
                          ),
                      ],
                      onSelected: (notice) {
                        notifier.readNotice(notice);
                        AppNavigator.push(
                          context,
                          page: _NoticePage(notice: notice),
                          name: 'message-notice-${notice.name}',
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: _ThreadList(threads: state.threads)),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoticePage extends ConsumerWidget {
  const _NoticePage({required this.notice});
  final MessageNotice notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(messagesProvider).notices[notice.name];
    return MessagesPageSurface(
      title: notice.label,
      child: BusinessRefresh(
        scope: 'messages',
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (message == null || message.isEmpty)
              const AppEmptyState(message: '暂无消息')
            else
              ListTile(title: Text(message)),
          ],
        ),
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
              child: AppEmptyState(message: '暂无会话'),
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
                                  color:
                                      thread.unread > 0 &&
                                          thread.preview.startsWith('[')
                                      ? const Color(0xFFFF416D)
                                      : const Color(0xFF666666),
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
