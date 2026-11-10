import '../../../../shared/widgets/feedback/app_toast.dart';
import 'account_action_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../messages/presentation/pages/blocked_users_page.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';
import '../../../messages/presentation/providers/messages_provider.dart';
import '../providers/profile_provider.dart';

class ProfileSettingsPage extends ConsumerWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn =
        (ref.watch(profileProvider).value ?? ref.read(userBlocProvider).state)
            .isSignedIn;
    final blockedCount = ref.watch(messagesProvider).blocked.length;
    return CompanionPageSurface(
      title: '设置',
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          const Text('账号管理', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          CompanionCardSurfaceWidget(
            child: Column(
              children: [
                ListTile(
                  title: const Text('黑名单'),
                  trailing: _value('$blockedCount 人'),
                  onTap: () => AppNavigator.push(
                    context,
                    page: const BlockedUsersPage(),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF4F4F4)),
                ListTile(
                  title: const Text('版本更新'),
                  trailing: _value('v1.0.0'),
                  onTap: () => AppToast.show('当前已是最新版本'),
                ),
              ],
            ),
          ),
          if (signedIn) ...[
            SizedBox(height: 16.h),
            const Text('账号操作', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            CompanionCardSurfaceWidget(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('退出登录'),
                    trailing: _value('确认退出'),
                    onTap: () => _confirm(context, ref, delete: false),
                  ),
                  const Divider(height: 1, color: Color(0xFFF4F4F4)),
                  ListTile(
                    title: const Text(
                      '注销账号',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    trailing: _value('请谨慎操作'),
                    onTap: () => _confirm(context, ref, delete: true),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 24.h),
          Text(
            '友伴 v1.0.0 · 用心守护你的每一次相遇',
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF999999), fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  /// 设置项右侧的说明和导航图标。
  Widget _value(String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: TextStyle(fontSize: 12.sp, color: const Color(0xFF999999)),
      ),
      SizedBox(width: 8.w),
      Icon(Icons.chevron_right, size: 20.r),
    ],
  );

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref, {
    required bool delete,
  }) async {
    final confirmed = await AppNavigator.push<bool>(
      context,
      page: AccountActionPage(delete: delete),
    );
    if (!context.mounted || confirmed != true) return;
    Navigator.pop(context);
  }
}
