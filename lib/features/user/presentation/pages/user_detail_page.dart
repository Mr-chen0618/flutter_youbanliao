import '../../../../shared/widgets/layout/app_empty_state.dart';
import '../../../report/presentation/pages/report_page.dart';
import '../../../../shared/widgets/feedback/app_action_sheet.dart';
import '../../../messages/data/model/message_thread.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../app/widgets/business_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../activity/presentation/providers/activity_detail_provider.dart';
import '../../../home/presentation/constant/home_assets_constant.dart';
import '../../../home/data/model/home_category_model.dart';
import '../../../activity/data/model/home_activity_model.dart';
import '../../../activity/presentation/widgets/activity_invite_action_widget.dart';
import '../../../messages/presentation/providers/messages_provider.dart';
import '../../../messages/presentation/pages/call_page.dart';
import 'profile_album_page.dart';
import 'profile_edit_page.dart';
import 'profile_field_page.dart';
import 'profile_interests_page.dart';
import '../../../square/presentation/pages/square_publish_page.dart';
import '../../../square/data/square_repository.dart';
import '../../../square/presentation/providers/square_provider.dart';
import '../../../square/presentation/widgets/square_post_actions_widget.dart';
import '../../data/model/user_detail.dart';
import '../bloc/user_event.dart';
import '../providers/profile_provider.dart';
import '../providers/user_detail_provider.dart';

/// 按用户 ID 展示相册、资料、发布活动和动态。
class UserDetailPage extends ConsumerStatefulWidget {
  const UserDetailPage({super.key, required this.userId});
  final String userId;

  static Future<void> open(BuildContext context, String id) async {
    await AppNavigator.push<void>(
      context,
      name: '/users/$id',
      arguments: id,
      page: UserDetailPage(userId: id),
    );
  }

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage> {
  int _photo = 0;
  int _play = 0;
  bool _saving = false;

  Future<void> _follow(bool current) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(activityDetailRepositoryProvider)
          .follow(widget.userId, !current);
      if (mounted) {
        ref.invalidate(followedActivityPublisherIdsProvider);
        ref.invalidate(activityDetailProvider);
      }
    } catch (_) {
      if (mounted) {
        AppToast.show('操作失败，请重试');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = userDetailProvider(widget.userId);
    return ref
        .watch(provider)
        .when(
          skipError: true,
          loading: () => _placeholder(const CircularProgressIndicator()),
          error: (_, _) => _placeholder(
            TextButton(
              onPressed: () => ref.invalidate(provider),
              child: const Text('加载失败，点击重试'),
            ),
          ),
          data: (detail) => detail == null
              ? _placeholder(const Text('用户资料不可用'))
              : _content(detail),
        );
  }

  Widget _placeholder(Widget child) => Scaffold(
    appBar: AppBar(title: const Text('用户详情')),
    body: Center(child: child),
  );

  /// 组合照片、资料和用户发布的内容。
  Widget _content(UserDetail detail) {
    final person = detail.person;
    if (detail.isSelf) {
      ref.listen(profileProvider, (previous, next) {
        if (previous?.hasValue == true &&
            previous?.value?.profile != next.value?.profile) {
          ref.invalidate(userDetailProvider(widget.userId));
        }
      });
    }
    final isFemale = person.gender == '女' || person.gender == '女性';
    final isMale = person.gender == '男' || person.gender == '男性';
    final blocked = ref
        .watch(messagesProvider)
        .blocked
        .values
        .where(
          (thread) =>
              thread.peerId == person.id ||
              thread.id == person.id ||
              (thread.peerId == null &&
                  thread.name == person.name &&
                  thread.avatar == person.avatar),
        )
        .firstOrNull;
    if (!detail.isSelf && (blocked != null || detail.blockedByPeer)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(person.name),
          actions: [
            if (blocked != null)
              IconButton(
                tooltip: '更多',
                onPressed: () => _more(detail, false, blocked: blocked),
                icon: const Icon(Icons.more_horiz),
              ),
          ],
        ),
        body: Center(
          child: Text(blocked != null ? '你已将对方拉黑，无法查看主页' : '对方已将你屏蔽'),
        ),
      );
    }
    final followedIds = ref.watch(followedActivityPublisherIdsProvider).value;
    final followed = followedIds?.contains(person.id) ?? false;
    final square = ref.watch(squareProvider);
    final posts = square.posts.where(
      (post) =>
          (detail.isSelf || post.isPublic) &&
          (post.authorId == person.id ||
              (post.authorId == null &&
                  (detail.isSelf
                      ? post.isMine
                      : post.author == person.name &&
                            post.avatar == person.avatar))),
    );
    final categories = detail.categories
        .where((category) => person.categoryIds.contains(category.id))
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: 48.h,
        leadingWidth: 64.w,
        actionsPadding: EdgeInsets.only(right: 8.w),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => Navigator.maybePop(context),
          icon: _navigationIcon('back'),
        ),
        actions: [
          IconButton(
            tooltip: '更多',
            icon: _navigationIcon('more'),
            onPressed: detail.isSelf
                ? () => _edit(const ProfileEditPage())
                : () => _more(detail, followed),
          ),
        ],
      ),
      body: BusinessRefresh(
        scope: 'user',
        id: widget.userId,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // 相册封面与缩略图
            _gallery(
              person.photos.isEmpty ? [person.avatar] : person.photos,
              avatar: person.avatar,
              editable: detail.isSelf,
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 用户资料和关注
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          person.name,
                          style: _style(18, weight: FontWeight.w600),
                        ),
                      ),
                      if (!detail.isSelf)
                        _pill(
                          followed ? '已关注' : '关注Ta',
                          colors: _yellow,
                          foreground: Colors.black,
                          onTap: followedIds == null || _saving
                              ? null
                              : () => _follow(followed),
                        ),
                    ],
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.w,
                    runSpacing: 4.h,
                    children: [
                      if (person.isOnline)
                        _chip(
                          '● 在线',
                          background: const Color(0xFF00C98A),
                          foreground: Colors.white,
                        ),
                      if (person.age > 0 || isFemale || isMale)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: isFemale
                                ? const Color(0xFFE96AA3)
                                : const Color(0xFF40C8FF),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isFemale)
                                Icon(
                                  Icons.female,
                                  size: 14.r,
                                  color: Colors.white,
                                ),
                              if (isMale) _assetIcon('gender', 14),
                              if (person.age > 0) ...[
                                if (isFemale || isMale) SizedBox(width: 4.w),
                                Text(
                                  '${person.age}',
                                  style: _style(12, color: Colors.white),
                                ),
                              ],
                            ],
                          ),
                        ),
                      Text(
                        'ID: ${person.displayId}${person.city.isEmpty ? '' : '｜${person.city}'}',
                        style: _style(13, color: _muted),
                      ),
                    ],
                  ),
                  if (detail.signature.isNotEmpty || detail.isSelf)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: detail.isSelf ? _editSignature : null,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 9.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF1C7), Color(0xFFFFE6D2)],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            detail.signature.isEmpty
                                ? '点击编辑个性签名，让Ta更了解你～'
                                : '个性签名：${detail.signature}',
                            style: _style(13),
                          ),
                        ),
                      ),
                    ),
                  _basicProfile(detail),
                  _profileSection(
                    '个性标签',
                    detail.tags,
                    edit: detail.isSelf ? () => _editLabels(tags: true) : null,
                  ),
                  _interests(detail),
                  // 我想约玩
                  if (categories.isNotEmpty)
                    _playCard(categories, person.interests),
                  if (!detail.isSelf)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ActivityInviteActionWidget(
                        personId: person.id,
                        isInvited: detail.isInvited,
                        builder: (onInvite, label) => TextButton(
                          onPressed: onInvite,
                          child: Text(label == '邀约Ta' ? '直接邀约' : label),
                        ),
                      ),
                    ),
                  // 发布的活动
                  _heading('发布的活动'),
                  if (detail.activities.isEmpty)
                    const AppEmptyState(message: '暂无发布的活动', compact: true),
                  for (final activity in detail.activities)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: _activityCard(activity),
                    ),
                  Divider(
                    height: 24.h,
                    thickness: 0.5,
                    color: const Color(0xFFE7E7E7),
                  ),
                  // Ta 的公开动态
                  _sectionHeading(
                    detail.isSelf ? '我的动态' : 'Ta的动态',
                    detail.isSelf ? '发布动态' : null,
                    detail.isSelf
                        ? () => _edit(const SquarePublishPage())
                        : null,
                  ),
                  if (posts.isEmpty)
                    const AppEmptyState(message: '暂无动态', compact: true),
                  for (final post in posts)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: _post(post, square),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: detail.isSelf
          ? null
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 216,
                      child: _contactButton(
                        '视频通话',
                        'video',
                        onPressed: () => CallPage.open(
                          context,
                          peerId: person.id,
                          name: person.name,
                          avatar: person.avatar,
                          video: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 115,
                      child: _contactButton(
                        '私信',
                        'message',
                        outlined: true,
                        onPressed: () {
                          final id = ref
                              .read(messagesProvider.notifier)
                              .openConversation(
                                person.id,
                                person.name,
                                person.avatar,
                              );
                          if (id == null) {
                            AppToast.show('请先解除黑名单');
                            return;
                          }
                          AppNavigator.pushNamed<void>(
                            context,
                            RouteNames.chat(id),
                            arguments: id,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 封面与可切换的相册缩略图。
  Widget _gallery(
    List<String> photos, {
    required String avatar,
    required bool editable,
  }) => SizedBox(
    height: 440.w,
    child: Stack(
      fit: StackFit.expand,
      children: [
        AppImage(
          src: photos[_photo.clamp(0, photos.length - 1)],
          fit: BoxFit.cover,
        ),
        const Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 100,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SizedBox(
            height: 78.w,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00F8F8F8), Color(0xFFF8F8F8)],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16.w,
          right: 16.w,
          bottom: 4.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(2.r),
                  child: AppImage(
                    src: avatar,
                    width: 64.r,
                    height: 64.r,
                    radius: 32.r,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SizedBox(
                  height: 44.r,
                  child: ListView.separated(
                    reverse: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length + (editable ? 1 : 0),
                    separatorBuilder: (_, _) => SizedBox(width: 4.w),
                    itemBuilder: (context, position) {
                      if (editable && position == 0) {
                        return IconButton.filled(
                          tooltip: '编辑相册',
                          onPressed: () => _edit(const ProfileAlbumPage()),
                          icon: const Icon(Icons.add),
                        );
                      }
                      final index =
                          photos.length - 1 - position + (editable ? 1 : 0);
                      return GestureDetector(
                        onTap: () => setState(() => _photo = index),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 2.r,
                              color: _photo == index
                                  ? Colors.white
                                  : Colors.transparent,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: AppImage(
                            src: photos[index],
                            width: 40.r,
                            height: 40.r,
                            radius: 10.r,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _navigationIcon(String name) => Container(
    width: 32.r,
    height: 32.r,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Colors.black54,
      shape: BoxShape.circle,
    ),
    child: SvgPicture.asset(
      'assets/activity/activity_detail_${name}_icon.svg',
      width: 24.r,
      height: 24.r,
    ),
  );

  Widget _heading(String title) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8.h),
    child: Text(
      title,
      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
    ),
  );

  Future<void> _more(
    UserDetail detail,
    bool followed, {
    MessageThread? blocked,
  }) async {
    final person = detail.person;
    final action = await showAppActionSheet<String>(
      context,
      actions: [
        if (blocked == null)
          AppSheetAction(value: 'follow', label: followed ? '取消关注' : '关注'),
        AppSheetAction(
          value: 'block',
          label: blocked == null ? '加入黑名单' : '移除黑名单',
          isDestructive: blocked == null,
        ),
        const AppSheetAction(value: 'report', label: '举报', isDestructive: true),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case 'follow':
        await _follow(followed);
      case 'block':
        final messages = ref.read(messagesProvider.notifier);
        if (blocked != null) {
          messages.unblock(blocked.id);
          return;
        }
        final accepted = await _confirm(
          '确定要拉黑吗？',
          '拉黑后，你们将不能进行聊天，同时也看不到Ta的近况。',
          '确定拉黑',
        );
        if (mounted && accepted) {
          messages.blockAuthor(person.id, person.name, person.avatar);
        }
      case 'report':
        await AppNavigator.push<void>(
          context,
          page: ReportPage(
            targetId: person.id,
            targetType: 'user',
            targetName: person.name,
            targetAvatar: person.avatar,
            targetSummary: detail.signature,
          ),
        );
    }
  }

  Future<bool> _confirm(
    String title,
    String description,
    String action,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _removePost(SquarePost post) async {
    final action = await showAppActionSheet<String>(
      context,
      actions: const [
        AppSheetAction(value: 'delete', label: '删除', isDestructive: true),
      ],
    );
    if (!mounted || action != 'delete') return;
    final accepted = await _confirm('删除动态', '删除后将不可恢复，你确认要删除吗？', '删除');
    if (mounted && accepted) ref.read(squareProvider.notifier).delete(post.id);
  }

  Future<void> _edit(Widget page) async {
    await AppNavigator.push<void>(context, page: page);
    if (mounted) ref.invalidate(userDetailProvider(widget.userId));
  }

  Future<void> _editSignature() async {
    final bloc = ref.read(userBlocProvider);
    final value = await AppNavigator.push<String>(
      context,
      page: ProfileFieldPage(
        title: '编辑个性签名',
        initial: bloc.state.profile.signature,
        limit: 100,
      ),
    );
    if (mounted && value != null) {
      bloc.add(
        UserProfileEdited((profile) => profile.copyWith(signature: value)),
      );
    }
  }

  Future<void> _editLabels({bool tags = false}) async {
    final bloc = ref.read(userBlocProvider);
    final profile = bloc.state.profile;
    final Map<String, List<String>> options;
    try {
      options = await ref.read(profileInterestsProvider.future);
    } catch (_) {
      if (mounted) AppToast.show('加载失败，请重试');
      return;
    }
    if (!mounted) return;
    final values = await AppNavigator.push<List<String>>(
      context,
      page: ProfileInterestsPage(
        title: tags ? '我的标签' : '编辑兴趣偏好',
        initial: tags ? profile.tags : profile.interests,
        options: options[tags ? '用户标签' : '兴趣'] ?? const [],
      ),
    );
    if (mounted && values != null) {
      bloc.add(
        UserProfileEdited(
          (profile) => tags
              ? profile.copyWith(tags: values)
              : profile.copyWith(interests: values),
        ),
      );
    }
  }

  Widget _contactButton(
    String label,
    String icon, {
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    final style = FilledButton.styleFrom(
      backgroundColor: outlined ? Colors.white : const Color(0xFFFFD152),
      foregroundColor: const Color(0xFF333333),
      minimumSize: Size(0, 52.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      side: outlined
          ? const BorderSide(color: Color(0xFF333333), width: 2)
          : null,
    );
    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: _versionIcon(icon, 24),
      label: Text(label, style: _style(16, weight: FontWeight.w500)),
    );
  }

  Widget _versionIcon(String icon, double size) => SvgPicture.asset(
    'assets/profile/profile_detail_v2_${icon}_icon.svg',
    width: size.r,
    height: size.r,
  );

  Widget _sectionHeading(String title, String? action, VoidCallback? onTap) =>
      Row(
        children: [
          Expanded(child: _heading(title)),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              child: Text(action!, style: _style(12, color: _muted)),
            ),
        ],
      );

  Widget _profileSection(
    String title,
    List<String> labels, {
    VoidCallback? edit,
  }) {
    if (labels.isEmpty && edit == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeading(title, '编辑$title', edit),
        _infoCard(
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (final label in labels) _chip(label),
              if (labels.isEmpty)
                TextButton(onPressed: edit, child: Text('添加$title')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _basicProfile(UserDetail detail) {
    final person = detail.person;
    final fields = [
      if (person.age > 0) '年龄：${person.age}岁',
      if (person.heightCm > 0) '身高：${person.heightCm}cm',
      if (person.weightKg > 0) '体重：${person.weightKg}kg',
      if (detail.occupation.isNotEmpty) '职业：${detail.occupation}',
      if (detail.education.isNotEmpty) '学历：${detail.education}',
      if (detail.relationshipStatus.isNotEmpty)
        '感情状况：${detail.relationshipStatus}',
      if (detail.incomeRange.isNotEmpty) '年收入：${detail.incomeRange}',
      if (detail.hometown.isNotEmpty) '家乡：${detail.hometown}',
      if (person.city.isNotEmpty) '城市：${person.city}',
    ];
    return _profileSection(
      '基本资料',
      fields,
      edit: detail.isSelf ? () => _edit(const ProfileEditPage()) : null,
    );
  }

  Widget _interests(UserDetail detail) {
    if (detail.person.interests.isEmpty && !detail.isSelf) {
      return const SizedBox.shrink();
    }
    const groups = [
      ('travel', '旅游足迹', '去过的地方', 0xFF1BAFA2, 0xFFF3FFFE),
      ('sports', '运动', '喜欢的运动', 0xFF3775E2, 0xFFF5F8FF),
      ('food', '美食', '喜欢的美食', 0xFFD67A50, 0xFFFFFAF8),
      ('films', '影视', '喜欢的影视作品', 0xFF9E50FF, 0xFFF9F4FF),
      ('music', '音乐', '喜欢的音乐', 0xFFDE579E, 0xFFFFF6FB),
    ];
    final tags = <String, List<String>>{};
    for (final interest in detail.person.interests) {
      final parts = interest.split('：');
      final title = parts.length > 1 ? parts.first : '其他兴趣';
      tags
          .putIfAbsent(title, () => [])
          .add(parts.length > 1 ? parts.skip(1).join('：') : interest);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeading('兴趣爱好', '编辑兴趣爱好', detail.isSelf ? _editLabels : null),
        _infoCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (icon, key, label, color, background) in groups)
                if (tags.remove(key) case final values?)
                  _interestGroup(
                    label,
                    values,
                    icon: icon,
                    color: Color(color),
                    background: Color(background),
                  ),
              for (final entry in tags.entries)
                _interestGroup(entry.key, entry.value),
              if (detail.person.interests.isEmpty)
                TextButton(onPressed: _editLabels, child: const Text('添加兴趣爱好')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _interestGroup(
    String label,
    List<String> values, {
    String? icon,
    Color? color,
    Color? background,
  }) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[_versionIcon(icon, 16), SizedBox(width: 4.w)],
            Text('$label：', style: _style(11)),
          ],
        ),
        SizedBox(height: 4.h),
        Wrap(
          spacing: 6.w,
          runSpacing: 4.h,
          children: [
            for (final value in values)
              _chip(
                value,
                foreground: color,
                background: background,
                border: color,
              ),
          ],
        ),
      ],
    ),
  );

  Widget _infoCard(Widget child) => Container(
    padding: EdgeInsets.all(12.r),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: child,
  );

  Widget _chip(
    String label, {
    Color? background,
    Color? foreground,
    Color? border,
  }) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: background ?? Colors.white,
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: border ?? const Color(0xFFF1F1F1)),
    ),
    child: Text(
      label,
      style: _style(12, color: foreground ?? const Color(0xFF666666)),
    ),
  );

  static const _yellow = [Color(0xFFFFDF87), Color(0xFFFFCE45)];
  static const _muted = Color(0xFF999999);

  TextStyle _style(
    double size, {
    Color color = const Color(0xFF333333),
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(fontSize: size.sp, color: color, fontWeight: weight);

  Widget _assetIcon(String name, double size) => SvgPicture.asset(
    'assets/profile/profile_detail_${name}_icon.svg',
    width: size.r,
    height: size.r,
  );

  /// 约玩分类以单卡轮播展示，圆点随当前分类切换。
  Widget _playCard(
    List<HomeCategoryModel> categories,
    List<String> interests,
  ) => Container(
    margin: EdgeInsets.only(top: 8.h, bottom: 8.h),
    padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3B6),
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('我想约玩', style: _style(16, weight: FontWeight.w600)),
        SizedBox(height: 8.h),
        SizedBox(
          height: 82.h,
          child: PageView.builder(
            itemCount: categories.length,
            onPageChanged: (index) => setState(() => _play = index),
            itemBuilder: (_, index) {
              final category = categories[index];
              final icon = HomeAssets.categoryIcons[category.id];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      AppImage(src: icon, width: 52.r, height: 52.r),
                      SizedBox(width: 10.w),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.label,
                            style: _style(16, weight: FontWeight.w600),
                          ),
                          if (interests.isNotEmpty)
                            Text(
                              interests.join('、'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _style(13, color: _muted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < categories.length; index++)
              Container(
                width: 14.w,
                height: 6.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: index == _play
                      ? const Color(0xFFFF9900)
                      : const Color(0xFFE4D78C),
                  borderRadius: BorderRadius.circular(15.r),
                ),
              ),
          ],
        ),
      ],
    ),
  );

  /// 用户详情中的发布卡片按设计排列分类、简介、时间和封面。
  Widget _activityCard(HomeActivityModel activity) {
    final categoryIcon = HomeAssets.categoryIcons[activity.categoryId];
    final published = DateTime.tryParse(activity.time);
    final locale = MaterialLocalizations.of(context);
    final timeLabel = published == null
        ? activity.time
        : '${locale.formatCompactDate(published)} ${TimeOfDay.fromDateTime(published).format(context)}';
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFECECEC)),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => AppNavigator.pushNamed<void>(
          context,
          RouteNames.activityDetail(activity.id),
          arguments: activity.id,
        ),
        child: Container(
          constraints: BoxConstraints(minHeight: 141.h),
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (activity.category.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1A476CFF),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (categoryIcon != null) ...[
                              AppImage(
                                src: categoryIcon,
                                width: 18.r,
                                height: 18.r,
                              ),
                              SizedBox(width: 4.w),
                            ],
                            Text(
                              activity.category,
                              style: _style(12, color: const Color(0xFF476CFF)),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 6.h),
                    Text(
                      activity.title,
                      style: _style(16, weight: FontWeight.w500),
                    ),
                    if (activity.description.isNotEmpty)
                      Text(
                        activity.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _style(11, color: _muted),
                      ),
                    SizedBox(height: 6.h),
                    _activityLine('time', '发布时间：$timeLabel'),
                    SizedBox(height: 4.h),
                    _activityLine('location', '地址：${activity.location}'),
                  ],
                ),
              ),
              if (activity.image.isNotEmpty) ...[
                SizedBox(width: 8.w),
                AppImage(
                  src: activity.image,
                  width: 82.r,
                  height: 82.r,
                  radius: 8.r,
                  fit: BoxFit.cover,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityLine(String icon, String label) => Row(
    children: [
      _assetIcon(icon, 16),
      SizedBox(width: 8.w),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _style(11, color: _muted),
        ),
      ),
    ],
  );

  /// 用户动态沿用广场操作，采用详情页的无卡片时间线布局。
  Widget _post(SquarePost post, SquareState state) {
    final actions = buildSquarePostCard(context, ref, state, post);
    return _infoCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (post.publishedAt case final date?)
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Text(
                MaterialLocalizations.of(context).formatShortDate(date),
                style: _style(14, color: _muted),
              ),
            ),
          InkWell(
            onTap: actions.onDetail,
            child: Text(post.text, style: _style(14)),
          ),
          if (post.photos.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Wrap(
                spacing: 4.w,
                runSpacing: 4.h,
                children: [
                  for (final photo in post.photos)
                    AppImage(
                      src: photo,
                      width: post.photos.length == 1 ? 290.w : 145.w,
                      height: 145.w,
                      radius: 12.r,
                      fit: BoxFit.cover,
                    ),
                ],
              ),
            ),
          if (post.reviewStatus case final status? when post.isMine)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                status == SquarePostReviewStatus.pending
                    ? '审核中…'
                    : '审核未通过，请删除重新编辑',
                style: _style(
                  12,
                  color: status == SquarePostReviewStatus.pending
                      ? const Color(0xFFD49334)
                      : const Color(0xFFDB6464),
                ),
              ),
            ),
          if (actions.onActivity case final open?)
            TextButton(onPressed: open, child: const Text('查看关联活动')),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: '更多操作',
                onPressed: post.isMine
                    ? () => _removePost(post)
                    : actions.onMore,
                icon: _assetIcon('post_more', 24),
              ),
              TextButton.icon(
                onPressed: actions.onComment,
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: Text(
                  actions.commentCount > 0 ? '${actions.commentCount}' : '评论',
                ),
              ),
              TextButton.icon(
                onPressed: actions.onLike,
                icon: _assetIcon('post_like', 24),
                label: Text(
                  post.likeCount + (actions.isLiked ? 1 : 0) > 0
                      ? '${post.likeCount + (actions.isLiked ? 1 : 0)}'
                      : '点赞',
                  style: _style(
                    13,
                    color: actions.isLiked
                        ? const Color(0xFFFF54F4)
                        : const Color(0xFFCCCCCC),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFF1F1F1)),
        ],
      ),
    );
  }

  /// 关注按钮使用原稿渐变。
  Widget _pill(
    String label, {
    required List<Color> colors,
    required Color foreground,
    required VoidCallback? onTap,
  }) {
    final radius = BorderRadius.circular(26.r);
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: onTap == null
                  ? [Colors.grey.shade300, Colors.grey.shade300]
                  : colors,
            ),
            borderRadius: radius,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Text(
                label,
                style: _style(13, color: foreground, weight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
