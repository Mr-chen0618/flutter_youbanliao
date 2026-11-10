import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/images/mock_photo_attachments.dart';
import '../../../square/presentation/providers/square_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../bloc/user_event.dart';
import '../providers/profile_provider.dart';

/// 收集联系方式、问题描述及佐证。
class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  List<String> _photos = [];
  final _formKey = GlobalKey<FormState>();
  final _contact = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _contact.dispose();
    _description.dispose();
    super.dispose();
  }

  /// 校验并提交反馈表单。
  void _submit() {
    if (!RegExp(
      r'^(?:[0-9]{11}|[^\s@]+@[^\s@]+\.[^\s@]+)$',
    ).hasMatch(_contact.text.trim())) {
      AppToast.show('请输入有效手机号或邮箱');
      return;
    }
    if (_description.text.trim().isEmpty) {
      AppToast.show('请填写问题描述');
      return;
    }
    ref
        .read(userBlocProvider)
        .add(
          UserFeedbackSubmitted(
            _description.text.trim(),
            contact: _contact.text.trim(),
            photos: _photos,
          ),
        );
    Navigator.pop(context);
    AppToast.show('反馈已提交');
  }

  @override
  Widget build(BuildContext context) => CompanionPageSurface(
    title: '问题反馈',
    child: ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // 反馈表单卡片
        CompanionCardSurfaceWidget(
          padding: EdgeInsets.all(14.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '请填写反馈信息',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6.h),
                Text(
                  '我们会在 24 小时内回复，请确保联系方式正确。',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                const Text(
                  '联系方式',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _contact,
                  decoration: InputDecoration(
                    hintText: '请输入手机号或邮箱',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                const Text(
                  '问题描述',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _description,
                  maxLength: 200,
                  minLines: 8,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: '请详细描述你遇到的问题或建议...',
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
                SizedBox(height: 10.h),
                MockPhotoAttachments(
                  options: ref
                      .watch(squareProvider)
                      .posts
                      .expand((post) => post.photos)
                      .toSet()
                      .toList(),
                  selected: _photos,
                  onChanged: (photos) => setState(() => _photos = photos),
                ),
                SizedBox(height: 16.h),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD04F),
                    foregroundColor: const Color(0xFF333333),
                    minimumSize: Size.fromHeight(52.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  onPressed: _submit,
                  child: const Text('提交反馈'),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          '友伴客服将通过友伴消息与你联系',
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF999999)),
        ),
      ],
    ),
  );
}
