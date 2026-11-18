import '../../../../shared/widgets/layout/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/widgets/business_refresh.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../providers/messages_provider.dart';
import '../../data/model/message_thread.dart';
import '../../../user/presentation/providers/user_detail_provider.dart';

/// 查看和解除已拉黑的用户。
class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(messagesProvider).blocked.values.toList();
    const background = Color(0xFFF6F6F6);
    return AppScaffold(
      navigatorTitle: '黑名单',
      navigatorColor: background,
      backgroundColor: background,
      body: BusinessRefresh(
        scope: 'messages',
        child: blocked.isEmpty
            ? const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Align(
                      alignment: Alignment(0, -.3),
                      child: AppEmptyState(message: '无黑名单'),
                    ),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      children: [
                        for (final thread in blocked)
                          _BlockedUserRow(thread: thread),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BlockedUserRow extends ConsumerWidget {
  const _BlockedUserRow({required this.thread});
  final MessageThread thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peerId = thread.peerId;
    final person = peerId == null
        ? null
        : ref.watch(userDetailProvider(peerId)).value?.person;
    final summary = person == null
        ? null
        : [
            if (person.city.isNotEmpty) person.city,
            if (person.age > 0) '${person.age}岁',
            if (person.interests.isNotEmpty) person.interests.first,
          ].join(' | ');
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      leading: AppImage(
        src: thread.avatar,
        width: 48.r,
        height: 48.r,
        radius: 24.r,
      ),
      title: Text(
        thread.name,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: summary == null || summary.isEmpty
          ? null
          : Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF999999)),
            ),
      trailing: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFF6F6F6),
          foregroundColor: const Color(0xFF999999),
          minimumSize: Size(94.w, 32.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => ref.read(messagesProvider.notifier).unblock(thread.id),
        child: const Text('移除黑名单'),
      ),
    );
  }
}
