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
                      colors: [Colors.black54, Colors.transparent],
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (activity.category.isNotEmpty)
                    Chip(
                      label: Text(activity.category),
                      backgroundColor: const Color(0xFFFFEFE4),
                    ),
                  // 发布人
                  if (publisher != null) ...[
                    const Divider(),
                    Row(
                      children: [
                        AppImage(
                          src: publisher.avatar,
                          width: 28.r,
                          height: 28.r,
                          radius: 14.r,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => AppNavigator.pushNamed<void>(
                                context,
                                RouteNames.userDetail(publisher.id),
                                arguments: publisher.id,
                              ),
                              child: Text('发布人：${publisher.name}'),
                            ),
                          ),
                        ),
                        if (!activity.isOwn)
                          TextButton(
                            onPressed: _saving
                                ? null
                                : () => _save(
                                    () => ref
                                        .read(activityDetailRepositoryProvider)
                                        .follow(
                                          publisher.id,
                                          !activity.followed,
                                        ),
                                  ),
                            child: Text(activity.followed ? '已关注' : '关注'),
                          ),
                      ],
                    ),
                  ],
                  const Divider(),
                  _section(
                    '发布的活动',
                    Column(
                      children: [
                        _info('time', '发布时间：${activity.publishedAt}'),
                        if (activity.eventTime case final time?)
                          _info(
                            'time',
                            '活动时间：${MaterialLocalizations.of(context).formatCompactDate(time)} ${TimeOfDay.fromDateTime(time).format(context)}',
                          ),
                        if (activity.gender case final gender?)
                          Text('性别限制：$gender'),
                        _info('location', '地址：${activity.location}'),
                        if (activity.description.isNotEmpty)
                          _info('restriction', activity.description),
                      ],
                    ),
                  ),
                  // 报名人员
                  _section(
                    '已报名（${activity.joined ? 1 : 0}）',
                    activity.joined
                        ? Row(
                            children: [
                              AppImage(
                                src: activity.viewer.avatar,
                                width: 44.r,
                                height: 44.r,
                                radius: 22.r,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(child: Text(activity.viewer.name)),
                            ],
                          )
                        : const Text('暂无报名'),
                  ),
                  // 活动图片
                  if (activity.photos.isNotEmpty) ...[
                    const Text('活动图片'),
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
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
                      SizedBox(width: 8.w),
                      Expanded(
                        flex: 184,
                        child: _button('聊一聊', const Color(0xFFFFCE45), () {
                          final id = ref
                              .read(messagesProvider.notifier)
                              .greet(publisher.name, publisher.avatar);
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
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.all(12.w),
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
      color: Colors.black54,
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
    padding: EdgeInsets.symmetric(vertical: 5.h),
    child: Row(
      children: [
        _icon(icon, 16.r),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
          ),
        ),
      ],
    ),
  );

  Widget _button(
    String label,
    Color color,
    VoidCallback? onPressed,
    Color foreground,
  ) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: foreground,
      minimumSize: Size(0, 52.h),
    ),
    child: Text(label),
  );
}
