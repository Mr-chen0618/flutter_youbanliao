import '../../../../app/widgets/business_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../providers/messages_provider.dart';

/// 查看和解除已拉黑的用户。
class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(messagesProvider).blocked.values;
    return CompanionPageSurface(
      title: '黑名单',
      child: BusinessRefresh(
        scope: 'messages',
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          children: [
            if (blocked.isEmpty) const Center(child: Text('暂无拉黑用户')),
            for (final thread in blocked)
              ListTile(
                leading: AppImage(
                  src: thread.avatar,
                  width: 42.r,
                  height: 42.r,
                  radius: 21.r,
                ),
                title: Text(thread.name),
                trailing: OutlinedButton(
                  onPressed: () =>
                      ref.read(messagesProvider.notifier).unblock(thread.id),
                  child: const Text('解除拉黑'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
