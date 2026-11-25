import '../../../square/presentation/widgets/square_category_badge_widget.dart';
import '../../../../shared/widgets/layout/app_empty_state.dart';
import '../../../report/presentation/widgets/report_action.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../app/widgets/business_refresh.dart';
import 'activity_join_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../messages/presentation/providers/messages_provider.dart';
import '../../data/activity_detail_repository.dart';
import '../providers/activity_detail_provider.dart';

/// 活动封面、发布人、活动信息和报名入口。
class ActivityDetailPage extends ConsumerStatefulWidget {
  const ActivityDetailPage({super.key, required this.activityId});

  final String activityId;

  static Future<void> open(BuildContext context, String id) async {
    await AppNavigator.push<void>(
      context,
      name: '/activity/$id',
      arguments: id,
      page: ActivityDetailPage(activityId: id),
    );
  }

  @override
  ConsumerState<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends ConsumerState<ActivityDetailPage> {
  bool _saving = false;

  /// 更新本地互动记录并刷新相关页面。
  Future<void> _save(Future<void> Function() update) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await update();
      if (!mounted) return;
      ref.invalidate(activityDetailProvider(widget.activityId));
      ref.invalidate(joinedActivityIdsProvider);
      ref.invalidate(followedActivityPublisherIdsProvider);
    } catch (_) {
      if (mounted) {
        AppToast.show('操作失败，请重试');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _join(ActivityDetail activity) async {
    await AppNavigator.push<bool>(
      context,
      page: ActivityJoinPage(id: widget.activityId, activity: activity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = activityDetailProvider(widget.activityId);
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
          data: (activity) => activity == null
              ? _placeholder(const Text('活动不存在或已下架'))
              : _content(activity),
        );
  }

  Widget _placeholder(Widget child) => Scaffold(
    appBar: AppBar(title: const Text('活动详情')),
    body: Center(child: child),
  );

  /// 封面、活动内容和底部操作栏。
  Widget _content(ActivityDetail activity) {
    final publisher = activity.publisher;
    final canChat = publisher != null && !activity.isOwn;
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: 48.h,
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
            onPressed: () => showReportActions(
              context,
              targetId: widget.activityId,
              targetType: 'activity',
              targetName: activity.title,
              targetAvatar: activity.cover,
              targetSummary: activity.description,
            ),
          ),
        ],
      ),
      body: BusinessRefresh(
        scope: 'activity',
        id: widget.activityId,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // 活动封面
            Stack(
              children: [
                AppImage(
                  src: activity.cover,
                  width: double.infinity,
                  height: 368.w,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 98.h,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xB3000000), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                      height: 25 / 18,
                    ),
                  ),
                  if (activity.category.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    SquareCategoryBadgeWidget(
                      category: activity.category,
                      backgroundColor: const Color(0xFFFFF0E6),
                      foregroundColor: const Color(0xFFFB5749),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  // 发布人及关注，移除 Material 默认按钮留白。
                  _divider(),
                  if (publisher != null) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => AppNavigator.pushNamed<void>(
                                context,
                                RouteNames.userDetail(publisher.id),
                                arguments: publisher.id,
                              ),
                              child: Row(
                                children: [
                                  AppImage(
                                    src: publisher.avatar,
                                    width: 28.r,
                                    height: 28.r,
                                    radius: 14.r,
                                  ),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      '发布人：${publisher.name}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF333333),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!activity.isOwn) _followButton(activity),
                        ],
                      ),
                    ),
                    _divider(),
                  ],
                  SizedBox(height: 8.h),
                  _section(
                    '发布的活动',
                    Column(
                      children: [
                        if (activity.eventTime case final time?)
                          _info(
                            'time',
                            '时间：${MaterialLocalizations.of(context).formatCompactDate(time)} ${TimeOfDay.fromDateTime(time).format(context)}',
                          )
                        else
                          _info('time', '发布时间：${activity.publishedAt}'),
                        _info('location', '地址：${activity.location}'),
                        _info(
                          'restriction',
                          '性别限制：${activity.gender?.isNotEmpty == true ? activity.gender : "不限"}',
                        ),
                      ],
                    ),
                  ),
                  // 描述独立展示，避免误用性别图标，也不丢失业务内容。
                  if (activity.description.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      activity.description,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF666666),
                        height: 1.5,
                      ),
                    ),
                  ],
                  // 仅展示有依据的领队和当前报名者，不虚构容量和成员。
                  _section(
                    '已报名（${activity.joined ? 1 : 0}）',
                    _participants(activity),
                  ),
                  // 活动图片
                  if (activity.photos.isNotEmpty) ...[
                    Text(
                      '发布的活动',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    for (final photo in activity.photos)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: AppImage(
                          src: photo,
                          width: double.infinity,
                          height: 257.w,
                          radius: 16.r,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: activity.isOwn
          ? null
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 155,
                      child: _button(
                        activity.joinBlockedReason ?? '报名',
                        const Color(0xFFFF51ED),
                        _saving || activity.joinBlockedReason != null
                            ? null
                            : () => _join(activity),
                        Colors.white,
                      ),
                    ),
                    if (canChat) ...[
                      SizedBox(width: 4.w),
                      Expanded(
                        flex: 184,
                        child: _button('聊一聊', const Color(0xFFFFCE45), () {
                          final id = ref
                              .read(messagesProvider.notifier)
                              .greet(
                                publisher.name,
                                publisher.avatar,
                                peerId: publisher.id,
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
                        }, Colors.black),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  /// 圆角信息分区。
  Widget _section(String title, Widget child) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEDEDED)),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: child,
        ),
      ],
    ),
  );

  /// 封面上的圆形导航按钮。
  Widget _navigationIcon(String name) => Container(
    width: 32.r,
    height: 32.r,
    decoration: const BoxDecoration(
      color: Color(0xB3000000),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: _icon(name, 24.r),
  );

  Widget _icon(String name, double size) => SvgPicture.asset(
    'assets/activity/activity_detail_${name}_icon.svg',
    width: size,
    height: size,
  );

  Widget _info(String icon, String text) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6.h),
    child: Row(
      children: [
        _icon(icon, 16.r),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              height: 18 / 13,
              color: const Color(0xFF999999),
            ),
          ),
        ),
      ],
    ),
  );

  /// 与设计一致的细分隔线。
  Widget _divider() =>
      const Divider(height: 1, thickness: 0.5, color: Color(0xFFF1F1F1));

  /// 发布人关注，沿用原有持久化入口。
  Widget _followButton(ActivityDetail activity) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26.r),
      gradient: const LinearGradient(
        colors: [Color(0xFFFFDF87), Color(0xFFFFCE45)],
      ),
    ),
    child: TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: Colors.black,
        textStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
      ),
      onPressed: _saving
          ? null
          : () => _save(
              () => ref
                  .read(activityDetailRepositoryProvider)
                  .follow(activity.publisher!.id, !activity.followed),
            ),
      child: Text(activity.followed ? '已关注' : '关注'),
    ),
  );

  /// 成员横向列表，小屏和大字模式允许横向滚动。
  Widget _participants(ActivityDetail activity) =>
      activity.publisher == null &&
          !activity.joined &&
          activity.joinBlockedReason != null
      ? const AppEmptyState(message: '暂无报名', compact: true)
      : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activity.publisher case final publisher?)
                  _member(publisher.avatar, publisher.name, leader: true),
                if (activity.joined &&
                    activity.publisher?.id != activity.viewer.id)
                  _member(activity.viewer.avatar, activity.viewer.name),
                if (!activity.isOwn && activity.joinBlockedReason == null)
                  InkWell(
                    onTap: () => _join(activity),
                    child: SizedBox(
                      width: 64.w,
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            'assets/activity/activity_detail_join_placeholder.svg',
                            width: 48.r,
                            height: 48.r,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '参加',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

  /// 48像素头像与领队角标；名字截断保持成员栏紧凑。
  Widget _member(String avatar, String name, {bool leader = false}) => SizedBox(
    width: 68.w,
    child: Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AppImage(src: avatar, width: 48.r, height: 48.r, radius: 24.r),
            if (leader)
              Positioned(
                bottom: -2.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD151),
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '领队',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFF333333)),
        ),
      ],
    ),
  );

  /// 胶囊操作按钮，保留禁用状态和长限制文案的换行空间。
  Widget _button(
    String label,
    Color color,
    VoidCallback? onPressed,
    Color foreground,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(59.r),
      gradient: LinearGradient(
        colors: onPressed == null
            ? [const Color(0xFFE0E0E0), const Color(0xFFE0E0E0)]
            : color == const Color(0xFFFFCE45)
            ? [const Color(0xFFFFDF87), color]
            : [const Color(0xFFFF54F4), const Color(0xFFFF83E8)],
      ),
    ),
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        minimumSize: Size(0, 52.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        shape: const StadiumBorder(),
        textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
      ),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}
