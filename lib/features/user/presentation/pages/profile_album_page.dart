import '../../../../shared/widgets/images/photo_upload_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/media/app_media_picker.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../bloc/user_event.dart';
import '../providers/profile_provider.dart';

/// 编辑账号相册，新增和移除均更新同一份资料。
class ProfileAlbumPage extends ConsumerStatefulWidget {
  const ProfileAlbumPage({super.key});
  @override
  ConsumerState<ProfileAlbumPage> createState() => _ProfileAlbumPageState();
}

class _ProfileAlbumPageState extends ConsumerState<ProfileAlbumPage> {
  static const _limit = 9;
  bool _picking = false;

  Future<void> _add() async {
    if (_picking) return;
    setState(() => _picking = true);
    final image = await AppMediaPicker.pickImage();
    if (!mounted) return;
    setState(() => _picking = false);
    if (image == null) return;
    ref
        .read(userBlocProvider)
        .add(
          UserProfileEdited((profile) {
            if (profile.photos.length >= _limit ||
                profile.photos.contains(image)) {
              return profile;
            }
            return profile.copyWith(
              photos: List.unmodifiable([...profile.photos, image]),
            );
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        (ref.watch(profileProvider).value ?? ref.read(userBlocProvider).state)
            .profile;
    final canAdd = profile.photos.length < _limit;
    return AppScaffold(
      navigatorTitle: '编辑相册',
      navigatorBackWidget: const BackButton(),
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF8EB),
            padding: EdgeInsets.symmetric(vertical: 9.h),
            child: const Text(
              '上传清晰照片更容易通过审核哦！最多9张',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFC87400)),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: EdgeInsets.all(16.w),
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.w,
              childAspectRatio: 109 / 138,
              children: [
                if (canAdd) PhotoUploadTile(onTap: _picking ? null : _add),
                for (final image in profile.photos)
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(src: image, radius: 12.r),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          tooltip: '移除照片',
                          color: Colors.white,
                          icon: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(0xFFE91E63),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () => ref
                              .read(userBlocProvider)
                              .add(
                                UserProfileEdited(
                                  (profile) => profile.copyWith(
                                    photos: List.unmodifiable(
                                      profile.photos.where(
                                        (photo) => photo != image,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
