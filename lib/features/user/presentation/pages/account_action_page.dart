import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';
import '../providers/profile_provider.dart';
import '../bloc/user_event.dart';

/// 账号退出和注销确认，注销需要主动勾选后果声明。
class AccountActionPage extends ConsumerStatefulWidget {
  const AccountActionPage({super.key, required this.delete});
  final bool delete;
  @override
  ConsumerState<AccountActionPage> createState() => _AccountActionPageState();
}

class _AccountActionPageState extends ConsumerState<AccountActionPage> {
  bool _agreed = false;
  @override
  Widget build(BuildContext context) {
    final account =
        ref.watch(profileProvider).value ?? ref.read(userBlocProvider).state;
    return CompanionPageSurface(
      title: widget.delete ? '注销账号' : '退出登录',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                CompanionCardSurfaceWidget(
                  child: ListTile(
                    leading: AppImage(
                      src: account.profile.avatar,
                      width: 42.r,
                      height: 42.r,
                      radius: 21.r,
                    ),
                    title: Text(account.profile.name),
                    subtitle: Text('ID: ${account.profile.displayId}'),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  widget.delete ? '注销不是退出，请认真考虑' : '确定要退出当前账号吗？',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: widget.delete ? Colors.redAccent : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  widget.delete
                      ? '如果只是暂时离开，建议返回设置选择「退出登录」，保留你的账号与回忆。'
                      : '退出后可重新登录，已保存的个人资料和记录会保留。',
                ),
                SizedBox(height: 24.h),
                CompanionCardSurfaceWidget(
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    widget.delete
                        ? '注销完成后，你将无法恢复\n\n• 账号资料将重置。\n\n• 认证和反馈记录将清除。\n\n请保存需要保留的资料，妥善处理未完成的组队与沟通。'
                        : '退出后将返回登录页。重新登录后可继续使用已保存的资料并参与活动。',
                  ),
                ),
                if (widget.delete)
                  CheckboxListTile(
                    value: _agreed,
                    onChanged: (value) => setState(() => _agreed = value!),
                    title: const Text('我已阅读并理解注销后果，自愿申请注销'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD04F),
                foregroundColor: Colors.black,
                minimumSize: Size.fromHeight(52.h),
              ),
              onPressed: widget.delete && !_agreed
                  ? null
                  : () async {
                      if (!widget.delete) {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialog) => AlertDialog(
                            title: const Text('确认退出登录？'),
                            content: const Text('退出后可重新登录，已保存的资料和记录会保留。'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialog, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dialog, true),
                                child: const Text('确认退出'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !context.mounted) return;
                      }
                      ref
                          .read(userBlocProvider)
                          .add(
                            widget.delete
                                ? const UserAccountDeleted()
                                : const UserSignedOut(),
                          );
                      Navigator.pop(context, true);
                    },
              child: Text(widget.delete ? '申请注销' : '退出登录'),
            ),
          ),
        ],
      ),
    );
  }
}
