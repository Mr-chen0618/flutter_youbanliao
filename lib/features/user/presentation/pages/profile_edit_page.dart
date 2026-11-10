import '../../../../core/media/app_media_picker.dart';
import 'profile_interests_page.dart';
import 'profile_field_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';
import '../bloc/user_event.dart';
import '../providers/profile_provider.dart';

class ProfileEditPage extends ConsumerWidget {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        (ref.watch(profileProvider).value ?? ref.read(userBlocProvider).state)
            .profile;
    final notifier = ref.read(userBlocProvider);
    final labelOptions = ref.watch(profileInterestsProvider);
    final date = profile.birthday;
    final birthday = date == null
        ? '请选择'
        : MaterialLocalizations.of(context).formatCompactDate(date);
    return CompanionPageSurface(
      title: '编辑资料',
      child: ListView(
        padding: EdgeInsets.all(12.w),
        children: [
          CompanionCardSurfaceWidget(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: AppImage(
                src: profile.avatar,
                width: 52.r,
                height: 52.r,
                radius: 26.r,
              ),
              title: const Text('我的头像'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '编辑头像',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF999999),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () async {
                final avatar = await AppMediaPicker.pickImage();
                if (context.mounted && avatar != null) {
                  notifier.add(
                    UserProfileEdited((p) => p.copyWith(avatar: avatar)),
                  );
                }
              },
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2AA),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '我想约玩',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final result = await _pick(context, '选择约玩', [
                      '户外搭子',
                      '运动搭子',
                      '美食搭子',
                      '摄影搭子',
                    ]);
                    if (context.mounted && result != null) {
                      notifier.add(
                        UserProfileEdited((p) => p.copyWith(companion: result)),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        AppImage(
                          src:
                              'assets/home/home_category_${switch (profile.companion) {
                                '运动搭子' => 'sports',
                                '美食搭子' => 'food',
                                '摄影搭子' => 'photo',
                                _ => 'outdoors',
                              }}_icon.png',
                          width: 44.r,
                          height: 44.r,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.companion.isEmpty
                                    ? '选择约玩'
                                    : profile.companion,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                profile.companion == '户外搭子'
                                    ? '登山、徒步、骑行、露营'
                                    : '选择约玩，更快找到你的搭子',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          CompanionCardSurfaceWidget(
            child: Column(
              children: [
                _field('昵称', profile.name, () async {
                  final value = await _edit(context, '修改昵称', profile.name, 20);
                  if (context.mounted && value != null && value.isNotEmpty) {
                    notifier.add(
                      UserProfileEdited((p) => p.copyWith(name: value)),
                    );
                  }
                }),
                _field(
                  '个性签名',
                  profile.signature.isEmpty ? '介绍一下自己' : profile.signature,
                  () async {
                    final value = await _edit(
                      context,
                      '编辑个性签名',
                      profile.signature,
                      100,
                    );
                    if (context.mounted && value != null) {
                      notifier.add(
                        UserProfileEdited((p) => p.copyWith(signature: value)),
                      );
                    }
                  },
                ),
                _field('性别', '${profile.gender}（注册后不可修改）', null),
                _field('出生日期', birthday, () async {
                  final value = await Navigator.of(context).push<DateTime>(
                    MaterialPageRoute(
                      builder: (_) => ProfileBirthdayPage(
                        initial: profile.birthday ?? DateTime(2000),
                      ),
                    ),
                  );
                  if (context.mounted && value != null) {
                    notifier.add(
                      UserProfileEdited((p) => p.copyWith(birthday: value)),
                    );
                  }
                }),
                _field('常驻城市', profile.city, () async {
                  final value = await _pick(context, '选择常驻城市', [
                    '广东 | 深圳',
                    '广东 | 广州',
                    '上海',
                    '北京',
                    '浙江 | 杭州',
                  ]);
                  if (context.mounted && value != null) {
                    notifier.add(
                      UserProfileEdited((p) => p.copyWith(city: value)),
                    );
                  }
                }),
              ],
            ),
          ),
          _tags(
            context,
            '兴趣爱好',
            profile.interests,
            labelOptions.value?['兴趣'] ?? const [],
            (value) => notifier.add(
              UserProfileEdited((p) => p.copyWith(interests: value)),
            ),
          ),
          _tags(
            context,
            'Ta的标签',
            profile.tags,
            labelOptions.value?['用户标签'] ?? const [],
            (value) =>
                notifier.add(UserProfileEdited((p) => p.copyWith(tags: value))),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value, VoidCallback? onTap) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    onTap: onTap,
    title: Row(
      children: [
        SizedBox(width: 78.w, child: Text(label)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF999999)),
          ),
        ),
      ],
    ),
    trailing: onTap == null
        ? const Icon(Icons.lock_outline, size: 18)
        : const Icon(Icons.chevron_right),
  );

  Widget _tags(
    BuildContext context,
    String title,
    List<String> tags,
    List<String> options,
    ValueChanged<List<String>> save,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('已选 ${tags.length} / 6'),
          ],
        ),
      ),
      CompanionCardSurfaceWidget(
        child: InkWell(
          onTap: () async {
            final value = await Navigator.of(context).push<List<String>>(
              MaterialPageRoute(
                builder: (_) => ProfileInterestsPage(
                  title: title == '兴趣爱好' ? '编辑兴趣偏好' : title,
                  initial: tags,
                  options: options,
                ),
              ),
            );
            if (context.mounted && value != null) {
              save(List.unmodifiable(value));
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 7.w,
                children: [
                  for (final tag in tags)
                    Chip(
                      label: Text(tag),
                      backgroundColor: const Color(0xFFFFF4CA),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const Text(
                '让友伴为你推荐更合拍的组队',
                style: TextStyle(color: Color(0xFF999999)),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Future<String?> _pick(
    BuildContext context,
    String title,
    List<String> values,
  ) => Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => ProfileFieldPage(
        title: title,
        initial: values.first,
        options: values,
      ),
    ),
  );

  Future<String?> _edit(
    BuildContext context,
    String title,
    String initial,
    int limit,
  ) => Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) =>
          ProfileFieldPage(title: title, initial: initial, limit: limit),
    ),
  );
}
