import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/config/legal_links.dart';
import '../../../../app/navigation/app_navigator.dart';
import '../../../../shared/pages/app_web_page.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../../messages/presentation/pages/blocked_users_page.dart';
import '../providers/profile_provider.dart';
import '../bloc/user_event.dart';
import 'account_action_page.dart';

/// 设置聚合协议、黑名单与账号操作。
class ProfileSettingsPage extends ConsumerWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn =
        (ref.watch(profileProvider).value ?? ref.read(userBlocProvider).state)
            .isSignedIn;
    return AppScaffold(
      navigatorTitle: '设置',
      navigatorBackWidget: const BackButton(),
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _row(
                          context,
                          '隐私政策',
                          const AppWebPage(
                            title: '隐私政策',
                            url: LegalLinks.privacyPolicyUrl,
                          ),
                          name: 'settings-privacy',
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _row(
                          context,
                          '用户协议',
                          const AppWebPage(
                            title: '用户协议',
                            url: LegalLinks.userAgreementUrl,
                          ),
                          name: 'settings-agreement',
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _row(context, '黑名单', const BlockedUsersPage()),
                        if (signedIn) ...[
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _row(
                            context,
                            '注销账号 (慎用)',
                            const AccountActionPage(delete: true),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (signedIn)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE0E8),
                      foregroundColor: const Color(0xFFFA1950),
                    ),
                    onPressed: () => _confirmLogout(context, ref),
                    child: const Text('退出登录'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: const Text(
          '退出登录后，你将无法收到新的信息，确定要退出登录吗？',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFD152),
              foregroundColor: Colors.black,
            ),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(userBlocProvider).add(const UserSignedOut());
    }
  }

  Widget _row(
    BuildContext context,
    String title,
    Widget page, {
    String? name,
  }) => ListTile(
    title: Text(title),
    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    onTap: () => AppNavigator.push<void>(context, page: page, name: name),
  );
}
