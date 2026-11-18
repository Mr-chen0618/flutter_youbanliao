import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../bloc/user_event.dart';
import '../providers/profile_provider.dart';
import 'user_feedback_page.dart';

/// 注销流程的阅读、原因和说明状态。
class AccountDeletionPage extends ConsumerStatefulWidget {
  const AccountDeletionPage({super.key});
  @override
  ConsumerState<AccountDeletionPage> createState() =>
      _AccountDeletionPageState();
}

class _AccountDeletionPageState extends ConsumerState<AccountDeletionPage> {
  static const _reasons = [
    '去其他平台',
    '感觉不安全私密',
    '找不到聊得来的人',
    '被欺骗感情/礼物',
    '没啥吸引我的功能',
    '年龄不合适',
  ];
  final _description = TextEditingController();
  final _selected = <String>{};
  Timer? _timer;
  int _seconds = 15;
  bool _showReasons = false, _submitting = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
      if (_seconds == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _description.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _selected.isNotEmpty &&
      _description.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    ref.read(userBlocProvider).add(const UserAccountDeleted());
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    navigatorTitle: '注销账号',
    navigatorBackWidget: BackButton(
      onPressed: () {
        if (_submitting) return;
        if (_showReasons) {
          setState(() => _showReasons = false);
        } else {
          Navigator.maybePop(context);
        }
      },
    ),
    backgroundColor: const Color(0xFFF6F6F6),
    body: SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: _showReasons ? _reasonsBody() : _noticeBody(),
      ),
    ),
  );

  Widget _noticeBody() => Column(
    children: [
      Expanded(
        child: ListView(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 98.r,
              color: const Color(0xFFD28A00),
            ),
            SizedBox(height: 12.h),
            const Text(
              '申请注销前请认真阅读',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            const Text(
              '提交后进入7天注销冷静期，期间登录可选择恢复账号。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 14.h),
            Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '请在提交注销前阅读并确认',
                      style: TextStyle(
                        color: Color(0xFFF31A50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text('1. 提交后进入7天冷静期，账号将退出登录。'),
                    SizedBox(height: 10),
                    Text('2. 冷静期内登录可恢复账号；到期后资料、私有消息和互动记录将被清除。'),
                    SizedBox(height: 10),
                    Text('3. 请先保存需要保留的信息，并处理尚未完成的活动。'),
                  ],
                ),
              ),
            ),
            TextButton(onPressed: _readTerms, child: const Text('查看注销说明')),
          ],
        ),
      ),
      Row(
        children: [
          Expanded(
            child: _button(
              '反馈问题',
              () =>
                  AppNavigator.push<void>(context, page: const FeedbackPage()),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _button(
              _seconds > 0 ? '申请注销 ${_seconds}s' : '申请注销',
              _seconds > 0 ? null : () => setState(() => _showReasons = true),
            ),
          ),
        ],
      ),
    ],
  );

  void _readTerms() => AppNavigator.push<void>(
    context,
    page: AppScaffold(
      navigatorTitle: '注销说明',
      navigatorBackWidget: const BackButton(),
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: const [
          Text('提交后进入7天冷静期。冷静期内通过手机验证码登录，可选择恢复账号并取消注销。'),
          SizedBox(height: 12),
          Text('冷静期届满后账号及其资料、消息和互动记录将被清除，后续登录会创建新账号。'),
        ],
      ),
    ),
  );

  Widget _reasonsBody() => Column(
    children: [
      Expanded(
        child: ListView(
          children: [
            const Text('请选择注销原因', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8.h),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              child: Column(
                children: [
                  for (final reason in _reasons)
                    CheckboxListTile(
                      title: Text(reason),
                      value: _selected.contains(reason),
                      onChanged: _submitting
                          ? null
                          : (checked) => setState(() {
                              if (checked == true) {
                                _selected.add(reason);
                              } else {
                                _selected.remove(reason);
                              }
                            }),
                    ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            const Text('补充说明（必填）', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8.h),
            TextField(
              controller: _description,
              enabled: !_submitting,
              maxLength: 100,
              minLines: 5,
              maxLines: 8,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: '请输入具体原因',
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(
        width: double.infinity,
        child: _button(
          _submitting ? '正在注销…' : '确认注销',
          _canSubmit ? _submit : null,
        ),
      ),
    ],
  );

  Widget _button(String label, VoidCallback? action) => SizedBox(
    height: 52.h,
    child: FilledButton(
      onPressed: action,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFFFD152),
        foregroundColor: Colors.black,
      ),
      child: Text(label),
    ),
  );
}

/// 仅在账号仓库实际保存注销申请后展示。
class AccountDeletionCompletedPage extends StatelessWidget {
  const AccountDeletionCompletedPage({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) onDone();
    },
    child: AppScaffold(
      navigatorBackWidget: BackButton(onPressed: onDone),
      backgroundColor: const Color(0xFFF6F6F6),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: const Color(0xFF00BB6D),
              size: 98.r,
            ),
            SizedBox(height: 16.h),
            Text(
              '注销申请已提交',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            const Text(
              '账号已退出登录，7天内可通过手机号登录恢复账号。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24.h),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD152),
                foregroundColor: Colors.black,
              ),
              child: const Text('我知道了'),
            ),
          ],
        ),
      ),
    ),
  );
}
