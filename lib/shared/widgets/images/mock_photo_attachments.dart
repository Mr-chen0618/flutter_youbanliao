import '../../../core/media/app_media_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_image.dart';
import 'photo_upload_tile.dart';

/// 表单复用的系统选图附件列表，附件路径由业务层保存。
class MockPhotoAttachments extends StatefulWidget {
  const MockPhotoAttachments({
    super.key,
    this.options = const [],
    this.feedbackStyle = false,
    required this.selected,
    required this.onChanged,
  });
  final bool feedbackStyle;
  final List<String> options, selected;
  final ValueChanged<List<String>> onChanged;
  @override
  State<MockPhotoAttachments> createState() => _MockPhotoAttachmentsState();
}

class _MockPhotoAttachmentsState extends State<MockPhotoAttachments> {
  bool _picking = false;

  /// 选图返回后读取最新条目，取消、重复点击与满额都不增加附件。
  Future<void> _pick() async {
    if (_picking || widget.selected.length >= 3) return;
    setState(() => _picking = true);
    try {
      final photo = await AppMediaPicker.pickImage();
      if (!mounted ||
          photo == null ||
          widget.selected.length >= 3 ||
          widget.selected.contains(photo)) {
        return;
      }
      widget.onChanged([...widget.selected, photo]);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '图片佐证',
            style: widget.feedbackStyle
                ? TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  )
                : null,
          ),
          Text(
            '${widget.selected.length} / 3',
            style: widget.feedbackStyle
                ? TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 12.sp,
                    height: 1.5,
                  )
                : const TextStyle(color: Colors.grey),
          ),
        ],
      ),
      SizedBox(height: widget.feedbackStyle ? 8.h : 10.h),
      Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8.w,
          runSpacing: widget.feedbackStyle ? 12.h : 0,
          children: [
            for (final image in widget.selected)
              InkWell(
                onTap: () =>
                    widget.onChanged([...widget.selected]..remove(image)),
                child: AppImage(
                  src: image,
                  width: 84.r,
                  height: 84.r,
                  radius: 12.r,
                ),
              ),
            if (widget.selected.length < 3)
              SizedBox(
                width: 84.r,
                height: 84.r,
                child: widget.feedbackStyle
                    ? PhotoUploadTile.feedback(onTap: _picking ? null : _pick)
                    : OutlinedButton(
                        onPressed: _picking ? null : _pick,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add),
                            Text('添加图片', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
              ),
          ],
        ),
      ),
    ],
  );
}
