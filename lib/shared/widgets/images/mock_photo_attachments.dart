import '../../../core/media/app_media_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_image.dart';

/// 表单复用的本地样本附件选择器，附件路径由业务层提供和保存。
class MockPhotoAttachments extends StatelessWidget {
  const MockPhotoAttachments({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  final List<String> options, selected;
  final ValueChanged<List<String>> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('图片佐证'),
          Text(
            '${selected.length} / 3',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
      SizedBox(height: 10.h),
      Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8.w,
          children: [
            for (final image in selected)
              InkWell(
                onTap: () => onChanged([...selected]..remove(image)),
                child: AppImage(
                  src: image,
                  width: 84.r,
                  height: 84.r,
                  radius: 12.r,
                ),
              ),
            if (selected.length < 3)
              SizedBox(
                width: 84.r,
                height: 84.r,
                child: OutlinedButton(
                  onPressed: () async {
                    final photo = await AppMediaPicker.pickImage();
                    if (photo != null && context.mounted)
                      onChanged([...selected, photo]);
                  },
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
