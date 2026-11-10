import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../../../core/media/app_media_picker.dart';
import '../../../../shared/widgets/feedback/app_action_sheet.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';
import '../../../user/presentation/providers/profile_provider.dart';
import '../providers/square_provider.dart';

class SquarePublishPage extends ConsumerStatefulWidget {
  const SquarePublishPage({super.key});

  @override
  ConsumerState<SquarePublishPage> createState() => _SquarePublishPageState();
}

class _SquarePublishPageState extends ConsumerState<SquarePublishPage> {
  String _text = '';
  bool _isPrivate = false;
  bool _includeLocation = true;
  final List<String> _photos = [];
  static const _maxPhotos = 9;

  @override
  Widget build(BuildContext context) => CompanionPageSurface(
    title: '发布动态',
    child: ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        CompanionCardSurfaceWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                maxLength: 500,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: '分享你的日常…',
                  fillColor: Color(0xFFF8F8F8),
                  filled: true,
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _text = value.trim()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('添加图片', style: TextStyle(fontSize: 14.sp)),
                  Text(
                    '${_photos.length} / 9',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final (index, photo) in _photos.indexed)
                    Stack(
                      children: [
                        AppImage(
                          src: photo,
                          width: 93.r,
                          height: 93.r,
                          radius: 12.r,
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            tooltip: '移除图片',
                            color: Colors.white,
                            icon: const Icon(Icons.cancel),
                            onPressed: () =>
                                setState(() => _photos.removeAt(index)),
                          ),
                        ),
                      ],
                    ),
                  if (_photos.length < _maxPhotos)
                    SizedBox(
                      width: 93.r,
                      height: 93.r,
                      child: OutlinedButton(
                        onPressed: _choosePhoto,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF1F1F1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppImage(
                              src:
                                  'assets/square/square_publish_add_photo_icon.svg',
                              width: 24.r,
                              height: 24.r,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '添加图片',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                '已添加 ${_photos.length} 张图片，可继续添加或移除',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        CompanionCardSurfaceWidget(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: AppImage(
                  src: 'assets/square/square_publish_location_icon.svg',
                  width: 20.r,
                  height: 20.r,
                ),
                title: const Text('所在位置'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _includeLocation
                          ? ref.read(userBlocProvider).state.profile.city
                          : '隐藏位置',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    AppImage(
                      src: 'assets/square/square_publish_chevron_icon.svg',
                      width: 16.r,
                      height: 16.r,
                    ),
                  ],
                ),
                onTap: () async {
                  final value = await showAppActionSheet<bool>(
                    context,
                    actions: const [
                      AppSheetAction(value: true, label: '显示资料中的城市'),
                      AppSheetAction(value: false, label: '隐藏位置'),
                    ],
                  );
                  if (value != null && mounted) {
                    setState(() => _includeLocation = value);
                  }
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F1F1)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: AppImage(
                  src: 'assets/square/square_publish_visibility_icon.svg',
                  width: 20.r,
                  height: 20.r,
                ),
                title: const Text('谁可以看'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isPrivate ? '仅自己可见' : '公开',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    AppImage(
                      src: 'assets/square/square_publish_chevron_icon.svg',
                      width: 16.r,
                      height: 16.r,
                    ),
                  ],
                ),
                onTap: () async {
                  final value = await showAppActionSheet<bool>(
                    context,
                    actions: const [
                      AppSheetAction(value: false, label: '公开'),
                      AppSheetAction(value: true, label: '仅自己可见'),
                    ],
                  );
                  if (value != null && mounted) {
                    setState(() => _isPrivate = value);
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFCE4D),
            foregroundColor: Colors.black87,
          ),
          onPressed: _text.isEmpty
              ? null
              : () {
                  final profile = ref.read(userBlocProvider).state.profile;
                  ref
                      .read(squareProvider.notifier)
                      .publish(
                        _text,
                        _photos,
                        _isPrivate,
                        authorId: profile.id,
                        author: profile.name,
                        avatar: profile.avatar,
                        location: _includeLocation ? profile.city : '',
                      );
                  Navigator.pop(context);
                },
          child: const Text('发布'),
        ),
        SizedBox(height: 16.h),
        Text(
          '分享真实日常，和友伴一起发现生活的小美好',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
        ),
      ],
    ),
  );

  Future<void> _choosePhoto() async {
    final result = await AppMediaPicker.pickImage();
    if (mounted && result != null && _photos.length < _maxPhotos) {
      setState(() => _photos.add(result));
    }
  }
}
