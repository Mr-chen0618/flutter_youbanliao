import '../../../../shared/widgets/layout/feed_tab_label.dart';
import '../../../activity/presentation/providers/activity_detail_provider.dart';
import '../../../../shared/widgets/layout/companion_backdrop_widget.dart';
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

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this)..addListener(_tabChanged);
  }

  void _tabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabs.removeListener(_tabChanged);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagesProvider);
    final notifier = ref.read(messagesProvider.notifier);
    int unread(MessageNotice notice) => state.readNotices.contains(notice)
        ? 0
        : state.noticeUnread[notice.name] ?? 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CompanionBackdropWidget(),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48.h,
                child: TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: EdgeInsets.only(left: 16.w),
                  labelPadding: EdgeInsets.only(right: 16.w),
                  dividerColor: Colors.transparent,
                  indicator: const BoxDecoration(),
                  overlayColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  tabs: [
                    for (final item in [(0, '消息'), (1, '好友'), (2, '通话记录')])
                      Tab(
                        key: ValueKey('messages-tab-${item.$1}'),
                        height: 48.h,
                        child: FeedTabLabel(
                          label: item.$2,
                          selected: _tabs.index == item.$1,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (final notice in MessageNotice.values)
                                SizedBox(
                                  width: 93.w,
                                  height: 97.h,
                                  child: Stack(
                                    children: [
                                      const Positioned.fill(
                                        child: AppImage(
                                          src:
                                              'assets/messages/messages_notice_surface.svg',
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          key: ValueKey(
                                            'message-notice-${notice.name}',
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          onTap: () {
                                            notifier.readNotice(notice);
                                            AppNavigator.push(
                                              context,
                                              page: _NoticePage(notice: notice),
                                              name:
                                                  'message-notice-${notice.name}',
                                            );
                                          },
                                          child: SizedBox.expand(
                                            child: Column(
                                              children: [
                                                SizedBox(height: 10.h),
                                                _UnreadBadge(
                                                  count: unread(notice),
                                                  child: AppImage(
                                                    src:
                                                        'assets/messages/messages_notice_${notice.icon}.svg',
                                                    width: 52.r,
                                                    height: 52.r,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                                SizedBox(height: 8.h),
                                                Text(
                                                  notice.label,
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: const Color(
                                                      0xFF333333,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(child: _ThreadList(threads: state.threads)),
                      ],
                    ),
                    _ThreadList(
                      threads: state.threads
                          .where(
                            (thread) =>
                                ref
                                    .watch(followedActivityPublisherIdsProvider)
                                    .value
                                    ?.contains(thread.peerId) ??
                                false,
                          )
                          .toList(),
                    ),
                    _ThreadList(
                      threads: state.threads
                          .where(
                            (thread) => thread.entries.any(
                              (entry) =>
                                  entry.kind == ChatEntryKind.voiceCall ||
                                  entry.kind == ChatEntryKind.videoCall,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
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
                                thread.displayName,
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
