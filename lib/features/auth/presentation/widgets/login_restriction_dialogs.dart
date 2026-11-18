import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../data/model/auth_login_restriction.dart';

/// 正确验证码通过后由用户明确选择是否撤销注销。
Future<void> showPendingDeletionDialog(
  BuildContext context, {
  required Future<void> Function() onRecover,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _PendingDeletionDialog(onRecover: onRecover),
);

class _PendingDeletionDialog extends StatefulWidget {
  const _PendingDeletionDialog({required this.onRecover});
  final Future<void> Function() onRecover;

  @override
  State<_PendingDeletionDialog> createState() => _PendingDeletionDialogState();
}

class _PendingDeletionDialogState extends State<_PendingDeletionDialog> {
  bool _recovering = false;

  Future<void> _recover() async {
    if (_recovering) return;
    setState(() => _recovering = true);
    try {
      await widget.onRecover();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) AppToast.showError(error);
    } finally {
      if (mounted) setState(() => _recovering = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_recovering,
    child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '恢复账号',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            Text(
              '你的账号目前处于注销冷静期内。若本次登录成功，账号将恢复正常并取消注销流程。如需继续使用友伴聊，请点击“恢复账号”',
              style: TextStyle(
                fontSize: 15.sp,
                color: const Color(0xFF666666),
                height: 1.6,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF8F8F8),
                      foregroundColor: const Color(0xFF333333),
                      minimumSize: Size(0, 52.h),
                    ),
                    onPressed: _recovering
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('继续注销'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('auth-recover-account'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD152),
                      foregroundColor: const Color(0xFF333333),
                      minimumSize: Size(0, 52.h),
                    ),
                    onPressed: _recovering ? null : _recover,
                    child: Text(_recovering ? '恢复中…' : '恢复账号'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// 封禁说明读取认证服务提供的原因和解除时间。
Future<void> showSuspendedDialog(
  BuildContext context,
  AuthAccountSuspended restriction,
) => showDialog<void>(
  context: context,
  builder: (dialog) {
    final remaining = restriction.unblocksAt?.difference(DateTime.now());
    final duration = remaining == null
        ? '暂未确定'
        : remaining.isNegative
        ? '请重试登录'
        : '${remaining.inDays}天${remaining.inHours % 24}小时${remaining.inMinutes % 60}分后';
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppImage(
              src: 'assets/auth/auth_login_suspended.svg',
              width: 72.r,
              height: 72.r,
            ),
            SizedBox(height: 20.h),
            Text(
              '账号被封禁',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            Text(
              '你的账号因涉嫌${restriction.reason}，当前账号已被封禁，暂无法登录和使用友伴聊相关服务。',
              style: TextStyle(
                fontSize: 15.sp,
                color: const Color(0xFF666666),
                height: 1.6,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text('解封时间：$duration', textAlign: TextAlign.center),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD152),
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(dialog),
                child: const Text('我知道了'),
              ),
            ),
          ],
        ),
      ),
    );
  },
);
