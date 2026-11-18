import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/media/app_media_picker.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../data/request-model/report_request_model.dart';
import '../providers/report_provider.dart';

/// 选择举报类型、填写说明并提交，所有业务入口共用。
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
  static const _background = Color(0xFFF6F6F6);
  static const _accent = Color(0xFFFFD152);
  static const _reasons = [
    '资料作假/冒用他人身份',
    '发送色情低俗/不雅内容',
    '散布政治谣言/违法内容',
    '承诺见面未赴约',
    '欺骗/欺诈行为',
    '频繁诱导消费',
    '发布广告',
    '引导到其他平台',
    '对方疑似未成年人',
    '对方疑似机器人',
    '侮辱谩骂/恶意骚扰',
  ];
  final _description = TextEditingController();
  final _photos = <String>[];
  String? _reason;
  bool _saving = false;
  bool _submitted = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (_saving || reason == null) return;
    final description = _description.text.trim();
    if (description.characters.length < 5) {
      AppToast.show('输入的内容太少啦');
      return;
    }
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
              reason: reason,
              description: description,
              photos: List.unmodifiable(_photos),
            ),
          );
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) AppToast.show('提交失败，请重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPhoto() async {
    final photo = await AppMediaPicker.pickImage();
    if (mounted && photo != null && _photos.length < 6 && !_saving) {
      setState(() => _photos.add(photo));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving && (_reason == null || _submitted),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_saving && !_submitted && _reason != null) {
        setState(() => _reason = null);
      }
    },
    child: AppScaffold(
      navigatorTitle: _submitted
          ? ''
          : _reason == null
          ? '选择举报类型'
          : '举报',
      navigatorColor: _background,
      navigatorBackWidget: BackButton(
        onPressed: () {
          if (_saving) return;
          if (!_submitted && _reason != null) {
            setState(() => _reason = null);
          } else {
            Navigator.maybePop(context);
          }
        },
      ),
      backgroundColor: _background,
      body: SafeArea(
        top: false,
        child: _submitted
            ? _success()
            : _reason == null
            ? _categories()
            : _form(),
      ),
    ),
  );
  Widget _label(String text) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      text,
      style: TextStyle(fontSize: 13.sp, color: const Color(0xFF999999)),
    ),
  );

  Widget _categories() => ListView(
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    children: [
      _label('请选择举报类型：'),
      Material(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < _reasons.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 16.w,
                  endIndent: 16.w,
                  color: _background,
                ),
              ListTile(
                title: Text(_reasons[i], style: TextStyle(fontSize: 14.sp)),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF999999),
                ),
                onTap: () => setState(() => _reason = _reasons[i]),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  Widget _form() => Column(
    children: [
      Expanded(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          children: [
            _label('举报类型：'),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(_reason!, style: TextStyle(fontSize: 14.sp)),
            ),
            SizedBox(height: 12.h),
            _label('举报原因（必填）：'),
            TextField(
              controller: _description,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              enabled: !_saving,
              maxLength: 100,
              minLines: 8,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: '请输入举报原因…',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            _label('上传图片（${_photos.length}/6）：'),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 108 / 138,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                if (_photos.length < 6)
                  Material(
                    borderRadius: BorderRadius.circular(16.r),
                    color: Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.r),
                      onTap: _saving ? null : _pickPhoto,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppImage(
                            src: 'assets/messages/report_upload_photo.svg',
                            width: 24.r,
                            height: 24.r,
                          ),
                          SizedBox(height: 6.h),
                          const Text(
                            '上传照片',
                            style: TextStyle(color: Color(0xFF999999)),
                          ),
                        ],
                      ),
                    ),
                  ),
                for (final photo in _photos)
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(src: photo, radius: 16.r, fit: BoxFit.cover),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          tooltip: '删除照片',
                          color: Colors.white,
                          onPressed: _saving
                              ? null
                              : () => setState(() => _photos.remove(photo)),
                          icon: const Icon(Icons.cancel),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
        child: SizedBox(
          width: double.infinity,
          height: 52.h,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: const Color(0xFF333333),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            onPressed: _saving ? null : _submit,
            child: Text(_saving ? '提交中…' : '提交'),
          ),
        ),
      ),
    ],
  );

  Widget _success() => ListView(
    padding: EdgeInsets.fromLTRB(16.w, 104.h, 16.w, 24.h),
    children: [
      Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AppImage(
              src: 'assets/messages/report_success_circle.svg',
              width: 98.r,
              height: 98.r,
            ),
            AppImage(
              src: 'assets/messages/report_success_check.svg',
              width: 44.r,
              height: 44.r,
            ),
          ],
        ),
      ),
      SizedBox(height: 20.h),
      Text(
        '举报提交成功',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
      SizedBox(height: 8.h),
      const Text(
        '举报已保存',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF999999)),
      ),
      SizedBox(height: 32.h),
      Center(
        child: SizedBox(
          width: 151.w,
          height: 40.h,
          child: FilledButton(
            onPressed: () => Navigator.maybePop(context),
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: const Color(0xFF333333),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text('我知道了'),
          ),
        ),
      ),
    ],
  );
}
