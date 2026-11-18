import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/media/app_media_picker.dart';
import '../../../../shared/widgets/images/app_image.dart';

/// 男女头像规则使用同一张引导表单，确认后再唤起相册。
Future<String?> showProfileAvatarGuide(
  BuildContext context, {
  required bool female,
}) async {
  final variant = female ? 'female' : 'male';
  final labels = female
      ? ['不露脸', '风景照', '遮挡面部', '诱惑写真']
      : ['模糊图片', '涉黄诱惑', '暴力血腥', '政治敏感'];
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: .7),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheet) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 112.h,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: AppImage(
                        src:
                            'assets/profile/profile_avatar_guide_${variant}_0.png',
                        width: 88.r,
                        height: 96.r,
                        radius: 16.r,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        tooltip: '关闭',
                        onPressed: () => Navigator.pop(sheet),
                        icon: CircleAvatar(
                          radius: 14.r,
                          backgroundColor: const Color(0xFFEFE7D6),
                          child: Icon(
                            Icons.close,
                            size: 18.r,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                female ? '请上传本人高清美照' : '请上传本人高清帅照',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8.h),
              const Text(
                '清晰无遮挡的照片，会更受欢迎哦～',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 16.h),
              const Text(
                '不能通过的头像',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              SizedBox(height: 14.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final (index, label) in labels.indexed)
                    SizedBox(
                      width: 58.r,
                      height: 62.r,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppImage(
                            src:
                                'assets/profile/profile_avatar_guide_${variant}_${index + 1}.png',
                            radius: 12.r,
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              color: Colors.pinkAccent,
                              child: const Text(
                                '不通过',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 3,
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                shadows: [Shadow(blurRadius: 3)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheet, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD152),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('选择照片'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return null;
  return AppMediaPicker.pickImage();
}
