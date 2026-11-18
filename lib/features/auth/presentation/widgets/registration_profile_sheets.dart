import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/input_validator.dart';
import '../../../../shared/form/widgets/app_text_field.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';

/// 完善资料的性别说明和退出挽留共用单按钮确认。
Future<void> showRegistrationNotice(
  BuildContext context,
  String message,
) => showDialog<void>(
  context: context,
  builder: (dialog) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
    child: Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.sp, color: const Color(0xFF333333)),
          ),
          SizedBox(height: 20.h),
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
  ),
);

/// 昵称编辑保存后才返回值，取消不修改注册表单。
Future<String?> showRegistrationNickname(
  BuildContext context, {
  required String initial,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  barrierColor: Colors.black.withValues(alpha: .7),
  backgroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
  ),
  builder: (_) => _NicknameSheet(initial: initial),
);

class _NicknameSheet extends StatefulWidget {
  const _NicknameSheet({required this.initial});
  final String initial;

  @override
  State<_NicknameSheet> createState() => _NicknameSheetState();
}

class _NicknameSheetState extends State<_NicknameSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    if (!InputValidator.validateNickname(value) ||
        value.characters.length > 7) {
      AppToast.show(value.isEmpty ? '请设置昵称' : '请输入7字以内的有效昵称');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '设置你的昵称✒️',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              '设置一个独特的昵称，让对方更容易记住你哦～',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF999999)),
            ),
            SizedBox(height: 20.h),
            Container(
              constraints: BoxConstraints(minHeight: 48.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFD4D9DD)),
              ),
              child: AppTextField(
                key: const ValueKey('registration-name-input'),
                controller: _controller,
                autofocus: true,
                hint: '请输入您的昵称',
                border: InputBorder.none,
                maxLength: 7,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _save(),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '${_controller.text.characters.length}/7',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFFD4D9DD)),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 52.h,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD152),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: _save,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
