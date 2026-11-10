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
import '../../../square/data/square_repository.dart';
import '../../../square/presentation/providers/square_provider.dart';
import '../../../square/presentation/widgets/square_post_actions_widget.dart';
import '../../data/model/user_detail.dart';
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
    final followedIds = ref.watch(followedActivityPublisherIdsProvider).value;
    final followed = followedIds?.contains(person.id) ?? false;
    final square = ref.watch(squareProvider);
    final posts = square.posts.where(
      (post) =>
          !post.isPrivate &&
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
      backgroundColor: Colors.white,
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
          PopupMenuButton<void>(
            tooltip: '更多',
            icon: _navigationIcon('more'),
            itemBuilder: (_) => [
              PopupMenuItem<void>(
                onTap: () =>
                    Clipboard.setData(ClipboardData(text: person.displayId)),
                child: const Text('复制用户 ID'),
              ),
            ],
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
            _gallery(person.photos.isEmpty ? [person.avatar] : person.photos),
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
                          followed ? '已关注' : '关注',
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
                      if (person.age > 0 ||
                          (person.gender?.isNotEmpty ?? false))
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF40C8FF),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _assetIcon('gender', 14),
                              if (person.age > 0) ...[
                                SizedBox(width: 4.w),
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
                  if (detail.signature.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(detail.signature, style: _style(13)),
                    ),
                  // 我想约玩
                  if (categories.isNotEmpty)
                    _playCard(categories, person.interests),
                  // 发布的活动
                  _heading('发布的活动'),
                  if (detail.activities.isEmpty) const Text('暂无发布的活动'),
                  for (final activity in detail.activities)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: _activityCard(activity),
                    ),
                  _tags('Ta的兴趣', person.interests),
                  _tags('Ta的标签', detail.tags),
                  Divider(
                    height: 24.h,
                    thickness: 0.5,
                    color: const Color(0xFFE7E7E7),
                  ),
                  // Ta 的公开动态
                  _heading('Ta的动态'),
                  if (posts.isEmpty) const Text('暂无动态'),
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
                      child: ActivityInviteActionWidget(
                        personId: person.id,
                        isInvited: detail.isInvited,
                        builder: (onInvite, label) => _pill(
                          label == '邀约Ta' ? '直接邀约' : label,
                          colors: const [Color(0xFFFF7BF6), Color(0xFFFF54F4)],
                          foreground: Colors.white,
                          icon: 'invite',
                          onTap: onInvite,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _pill(
                        '先聊聊',
                        colors: _yellow,
                        foreground: const Color(0xFF333333),
                        icon: 'chat',
                        onTap: () {
                          final id = ref
                              .read(messagesProvider.notifier)
                              .greet(person.name, person.avatar);
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
  Widget _gallery(List<String> photos) => SizedBox(
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
        if (photos.length > 1)
          Positioned(
            left: 12.w,
            right: 12.w,
            bottom: 12.h,
            child: SizedBox(
              height: 44.r,
              child: ListView.separated(
                reverse: true,
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) => SizedBox(width: 4.w),
                itemBuilder: (context, position) {
                  final index = photos.length - 1 - position;
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

  Widget _tags(String title, List<String> tags) => tags.isEmpty
      ? const SizedBox.shrink()
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heading(title),
            Wrap(
              spacing: 8.w,
              runSpacing: 4.h,
              children: [
                for (final tag in tags)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6CB),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      tag,
                      style: _style(14, color: const Color(0xFF8C651C)),
                    ),
                  ),
              ],
            ),
          ],
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
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
          for (final photo in post.photos)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: AppImage(
                src: photo,
                width: double.infinity,
                height: 299.w,
                radius: 12.r,
                fit: BoxFit.cover,
              ),
            ),
          if (actions.onActivity case final open?)
            TextButton(onPressed: open, child: const Text('查看关联活动')),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: '更多操作',
                onPressed: actions.onMore,
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

  /// 关注和底部操作使用同一胶囊形状及原稿渐变。
  Widget _pill(
    String label, {
    required List<Color> colors,
    required Color foreground,
    required VoidCallback? onTap,
    String? icon,
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
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: icon == null ? 6.h : 0,
              ),
              child: SizedBox(
                height: icon == null ? null : 52.h,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      _assetIcon(icon, 24),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      label,
                      style: _style(
                        icon == null ? 13 : 16,
                        color: foreground,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
