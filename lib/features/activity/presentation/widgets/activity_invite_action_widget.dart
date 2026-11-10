import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/feedback/app_toast.dart';
import 'activity_form_widget.dart';
import '../providers/activity_invite_provider.dart';

/// 复用首页与用户详情的邀约流程及提交状态。
class ActivityInviteActionWidget extends ConsumerStatefulWidget {
  const ActivityInviteActionWidget({
    super.key,
    required this.personId,
    required this.isInvited,
    required this.builder,
  });

  final String personId;
  final bool isInvited;
  final Widget Function(VoidCallback? onInvite, String label) builder;

  @override
  ConsumerState<ActivityInviteActionWidget> createState() =>
      _ActivityInviteActionWidgetState();
}

class _ActivityInviteActionWidgetState
    extends ConsumerState<ActivityInviteActionWidget> {
  bool _isConfirming = false;

  Future<void> _invite() async {
    if (_isConfirming) return;
    _isConfirming = true;
    final id = widget.personId;
    try {
      final sent = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        barrierColor: const Color(0xB3000000),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (sheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheet).bottom,
          ),
          child: SafeArea(
            top: false,
            child: FractionallySizedBox(
              heightFactor: MediaQuery.viewInsetsOf(sheet).bottom == 0
                  ? 0.63
                  : 0.92,
              child: Column(
                children: [
                  SizedBox(
                    height: 44.h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Center(child: Text('发起邀约')),
                        Positioned(
                          right: 8.w,
                          child: IconButton(
                            tooltip: '关闭',
                            onPressed: () => Navigator.pop(sheet),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ActivityFormWidget(
                      isInvitation: true,
                      onSubmit: (draft) async {
                        final result = await ref
                            .read(activityInviteProvider.notifier)
                            .submitInvite(id, draft: draft);
                        if (result != true) throw StateError('Invite failed');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (!mounted || sent != true) return;
      AppToast.show('邀约已发送');
    } finally {
      _isConfirming = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(
      activityInviteProvider.select(
        (state) => state.submissions[widget.personId],
      ),
    );
    final isInvited = widget.isInvited || status?.hasValue == true;
    final isSending = status?.isLoading == true;
    return widget.builder(
      isInvited || isSending ? null : _invite,
      isInvited
          ? '已邀约'
          : isSending
          ? '发送中'
          : '邀约Ta',
    );
  }
}
