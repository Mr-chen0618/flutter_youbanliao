import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/images/mock_photo_attachments.dart';
import '../../../square/presentation/providers/square_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/report_provider.dart';
import '../../data/request-model/report_request_model.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';

/// 用户、活动、动态和聊天共用的举报表单，按对象类型和 ID 隔离记录。
class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
    this.targetAvatar,
    this.targetSummary,
  });
  final String targetId, targetType, targetName;
  final String? targetAvatar, targetSummary;
  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  static const _reasons = [
    '广告引流 / 垃圾信息',
    '色情低俗',
    '辱骂骚扰 / 人身攻击',
    '虚假信息 / 欺诈',
    '侵犯隐私',
    '其他问题',
  ];
  String _reason = _reasons.first;
  final _description = TextEditingController();
  bool _saving = false;
  List<String> _photos = [];
  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(reportRepositoryProvider)
          .submit(
            ReportRequestModel(
              targetId: widget.targetId,
              targetType: widget.targetType,
              targetName: widget.targetName,
              targetAvatar: widget.targetAvatar,
              targetSummary: widget.targetSummary,
              reason: _reason,
              description: _description.text.trim(),
              photos: List.unmodifiable(_photos),
            ),
          );
      if (!mounted) return;
      Navigator.pop(context);
      AppToast.show('举报已提交');
    } catch (_) {
      AppToast.show('提交失败，请重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => CompanionPageSurface(
    title: '举报',
    child: ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        CompanionCardSurfaceWidget(
          padding: EdgeInsets.all(16.w),
          child: ListTile(
            leading: widget.targetAvatar == null || widget.targetAvatar!.isEmpty
                ? null
                : AppImage(
                    src: widget.targetAvatar!,
                    width: 44.r,
                    height: 44.r,
                    radius: 8.r,
                  ),
            title: Text(widget.targetName),
            subtitle: Text(
              widget.targetSummary?.isNotEmpty == true
                  ? widget.targetSummary!
                  : '举报对象',
            ),
          ),
        ),
        SizedBox(height: 16.h),
        CompanionCardSurfaceWidget(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '请选择举报原因',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('必选，选择最符合的一项', style: TextStyle(color: Colors.grey)),
              for (final reason in _reasons)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(reason),
                  trailing: Icon(
                    _reason == reason
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: _reason == reason
                        ? const Color(0xFFFFCE43)
                        : Colors.grey,
                    size: 18.r,
                  ),
                  onTap: _saving
                      ? null
                      : () => setState(() => _reason = reason),
                ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        CompanionCardSurfaceWidget(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('补充说明'),
              TextField(
                controller: _description,
                maxLength: 200,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(hintText: '请描述具体问题'),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        CompanionCardSurfaceWidget(
          padding: EdgeInsets.all(14.w),
          child: MockPhotoAttachments(
            options: ref
                .watch(squareProvider)
                .posts
                .expand((post) => post.photos)
                .toSet()
                .toList(),
            selected: _photos,
            onChanged: (photos) => setState(() => _photos = photos),
          ),
        ),
        SizedBox(height: 16.h),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFD04F),
            foregroundColor: Colors.black,
            minimumSize: Size.fromHeight(48.h),
          ),
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? '提交中' : '提交举报'),
        ),
        SizedBox(height: 14.h),
        const Text(
          '举报信息将严格保密，不会向对方公开。处理结果将通过友伴消息通知你。',
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    ),
  );
}
