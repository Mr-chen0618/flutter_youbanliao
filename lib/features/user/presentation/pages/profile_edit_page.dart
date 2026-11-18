import '../../../../shared/widgets/images/photo_upload_tile.dart';
import '../../../../app/navigation/app_navigator.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../widgets/profile_attribute_sheet.dart';
import 'profile_album_page.dart';
import 'profile_interests_page.dart';
import 'profile_field_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../widgets/profile_avatar_guide.dart';
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
    return AppScaffold(
      navigatorTitle: '编辑资料',
      navigatorBackWidget: const BackButton(),
      backgroundColor: const Color(0xFFF6F6F6),
      body: ListView(
        padding: EdgeInsets.all(12.w),
        children: [
          Center(
            child: Semantics(
              label: '编辑头像',
              button: true,
              child: InkWell(
                onTap: () async {
                  final avatar = await showProfileAvatarGuide(
                    context,
                    female: profile.gender == '女',
                  );
                  if (context.mounted && avatar != null) {
                    notifier.add(
                      UserProfileEdited((p) => p.copyWith(avatar: avatar)),
                    );
                  }
                },
                child: SizedBox(
                  width: 118.r,
                  height: 118.r,
                  child: Stack(
                    children: [
                      AppImage(
                        src: profile.avatar,
                        width: 118.r,
                        height: 118.r,
                        radius: 59.r,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 17.r,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 14.r,
                            backgroundColor: const Color(0xFF333333),
                            child: Icon(
                              Icons.camera_alt,
                              size: 16.r,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          const Text('我的相册'),
          SizedBox(height: 8.h),
          CompanionCardSurfaceWidget(
            child: SizedBox(
              height: 110.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  SizedBox(
                    width: 98.w,
                    child: PhotoUploadTile(
                      onTap: () => AppNavigator.push(
                        context,
                        page: const ProfileAlbumPage(),
                      ),
                    ),
                  ),
                  for (final image in profile.photos)
                    Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: InkWell(
                        onTap: () => AppNavigator.push(
                          context,
                          page: const ProfileAlbumPage(),
                        ),
                        child: AppImage(
                          src: image,
                          width: 98.w,
                          height: 110.h,
                          radius: 12.r,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          const Text('个性签名'),
          SizedBox(height: 8.h),
          CompanionCardSurfaceWidget(
            child: _field(
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
          ),
          SizedBox(height: 12.h),
          const Text('基本资料'),
          SizedBox(height: 8.h),
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
                _field('性别', '${profile.gender}（注册后不可修改）', null),
                _field('出生日期', birthday, () async {
                  final value = await showModalBottomSheet<DateTime>(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24.r),
                      ),
                    ),
                    builder: (_) => ProfileBirthdayPage(
                      initial: profile.birthday ?? DateTime(2000),
                      asSheet: true,
                    ),
                  );
                  if (context.mounted && value != null) {
                    notifier.add(
                      UserProfileEdited((p) => p.copyWith(birthday: value)),
                    );
                  }
                }),
                _attribute(
                  context,
                  '身高',
                  '📏',
                  profile.heightCm == null ? '' : '${profile.heightCm}cm',
                  {'': List.generate(141, (index) => '${110 + index}cm')},
                  (value) => notifier.add(
                    UserProfileEdited(
                      (p) => p.copyWith(
                        heightCm: int.parse(value.replaceAll('cm', '')),
                      ),
                    ),
                  ),
                ),
                _attribute(
                  context,
                  '体重',
                  '⚖️',
                  profile.weightKg == null ? '' : '${profile.weightKg}kg',
                  {'': List.generate(121, (index) => '${30 + index}kg')},
                  (value) => notifier.add(
                    UserProfileEdited(
                      (p) => p.copyWith(
                        weightKg: int.parse(value.replaceAll('kg', '')),
                      ),
                    ),
                  ),
                ),
                _attribute(
                  context,
                  '职业',
                  '💼',
                  profile.occupation,
                  const {
                    '': [
                      '老板',
                      '网红',
                      '白领',
                      '学生',
                      '教师',
                      '工程师',
                      '医生',
                      '护士',
                      '自由职业',
                      '其他',
                    ],
                  },
                  (value) => notifier.add(
                    UserProfileEdited((p) => p.copyWith(occupation: value)),
                  ),
                ),
                _attribute(
                  context,
                  '学历',
                  '🎓',
                  profile.education,
                  const {
                    '': ['初中及以下', '中专', '高中', '大专', '大学', '硕士', '博士'],
                  },
                  (value) => notifier.add(
                    UserProfileEdited((p) => p.copyWith(education: value)),
                  ),
                ),
                _attribute(
                  context,
                  '感情情况',
                  '♡',
                  profile.relationshipStatus,
                  const {
                    '': ['单身', '恋爱中', '已婚', '暂不公开'],
                  },
                  (value) => notifier.add(
                    UserProfileEdited(
                      (p) => p.copyWith(relationshipStatus: value),
                    ),
                  ),
                ),
                _attribute(
                  context,
                  '家乡',
                  '🏠',
                  profile.hometown,
                  const {
                    '北京': ['北京市'],
                    '上海': ['上海市'],
                    '广东省': ['广州市', '深圳市', '佛山市', '东莞市', '珠海市', '惠州市'],
                    '浙江省': ['杭州市', '宁波市', '温州市'],
                    '江苏省': ['南京市', '苏州市', '无锡市'],
                    '四川省': ['成都市', '绵阳市'],
                    '湖北省': ['武汉市', '宜昌市'],
                    '湖南省': ['长沙市', '株洲市'],
                    '重庆': ['重庆市'],
                    '其他地区': ['其他城市'],
                  },
                  (value) => notifier.add(
                    UserProfileEdited((p) => p.copyWith(hometown: value)),
                  ),
                ),
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
            '我的标签',
            profile.tags,
            labelOptions.value?['用户标签'] ?? const [],
            (value) =>
                notifier.add(UserProfileEdited((p) => p.copyWith(tags: value))),
          ),
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
        ],
      ),
    );
  }

  Widget _attribute(
    BuildContext context,
    String label,
    String icon,
    String value,
    Map<String, List<String>> options,
    ValueChanged<String> save,
  ) => _field(label, value.isEmpty ? '填写$label' : value, () async {
    final selected = await showProfileAttributeSheet(
      context,
      label: label,
      icon: icon,
      initial: value,
      options: options,
    );
    if (!context.mounted || selected == null || selected == value) return;
    save(selected);
    AppToast.show('$label已修改');
  });

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
            Text(
              title == '兴趣爱好'
                  ? '已选 ${tags.length} · 每类最多3项'
                  : '已选 ${tags.length} / 10',
            ),
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
