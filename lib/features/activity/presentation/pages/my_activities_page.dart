import '../../../../app/widgets/business_refresh.dart';
import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../data/my_activity_repository.dart';
import '../providers/my_activities_provider.dart';

/// 展示自己发布或参加的组队。
class MyActivitiesPage extends ConsumerWidget {
  const MyActivitiesPage({super.key, this.joined = false});

  final bool joined;

  static const _labels = {
    ActivityStatus.recruiting: '招募中',
    ActivityStatus.formed: '已成队',
    ActivityStatus.ended: '已结束',
    ActivityStatus.unknown: '未知',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) => CompanionPageSurface(
    title: joined ? '我参加的' : '我发布的',
    child: ref
        .watch(myActivitiesProvider(joined))
        .when(
          skipError: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(myActivitiesProvider(joined)),
              child: const Text('加载失败，点击重试'),
            ),
          ),
          data: (data) {
            final activities = data
                .where((activity) => !joined || activity.joined)
                .toList();
            final statuses = [
              if (!joined) ActivityStatus.recruiting,
              ActivityStatus.formed,
              ActivityStatus.ended,
            ];
            return DefaultTabController(
              length: statuses.length + 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 组队总览
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 6.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            joined ? '每一次参与，都值得记录' : '每一次发起，都有回应',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text('共 ${activities.length} 个组队', style: _muted(12)),
                      ],
                    ),
                  ),
                  // 状态筛选
                  TabBar(
                    dividerColor: Colors.transparent,
                    labelPadding: EdgeInsets.zero,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorColor: const Color(0xFFFFCE43),
                    labelColor: const Color(0xFF333333),
                    unselectedLabelColor: const Color(0xFF999999),
                    tabs: [
                      Tab(text: '全部 ${activities.length}'),
                      for (final status in statuses)
                        Tab(
                          text:
                              '${_labels[status]} ${activities.where((item) => item.status == status).length}',
                        ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _list(context, activities),
                        for (final status in statuses)
                          _list(
                            context,
                            activities
                                .where((item) => item.status == status)
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
  );

  /// 组队卡片和出发提醒。
  Widget _list(BuildContext context, List<MyActivity> activities) =>
      BusinessRefresh(
        scope: 'teams',
        id: joined ? 'joined' : 'published',
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 20.h),
          children: [
            if (activities.isEmpty) const Center(child: Text('暂无组队')),
            for (final activity in activities)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => AppNavigator.pushNamed<void>(
                    context,
                    RouteNames.activityDetail(activity.id),
                    arguments: activity.id,
                  ),
                  child: _card(activity),
                ),
              ),
            if (activities.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '友伴小提醒：出发前记得确认集合信息，及时回复报名的小伙伴哦。',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF91641A),
                  ),
                ),
              ),
          ],
        ),
      );

  /// 单个组队的状态、简介与活动信息。
  Widget _card(MyActivity activity) {
    final outdoor = activity.category == '户外';
    final (statusBackground, statusColor) = switch (activity.status) {
      ActivityStatus.recruiting => (
        const Color(0xFFFFF4CA),
        const Color(0xFF91641A),
      ),
      ActivityStatus.formed => (
        const Color(0xFFE2F6EF),
        const Color(0xFF00AE85),
      ),
      _ => (const Color(0xFFF5F5F5), const Color(0xFF999999)),
    };
    return CompanionCardSurfaceWidget(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6.w,
                  children: [
                    _badge(
                      activity.category,
                      outdoor
                          ? const Color(0xFFE2F6EF)
                          : const Color(0xFFEBEEFF),
                      outdoor
                          ? const Color(0xFF00AE85)
                          : const Color(0xFF4768FF),
                      icon: outdoor
                          ? 'assets/home/home_category_outdoors_icon.png'
                          : 'assets/square/square_sport_badge.png',
                    ),
                    _badge(
                      _labels[activity.status]!,
                      statusBackground,
                      statusColor,
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
                Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(activity.description, style: _muted(11)),
                SizedBox(height: 6.h),
                _detail('time', '发布时间：${activity.time}'),
                SizedBox(height: 3.h),
                _detail('map', '地址：${activity.location}'),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          AppImage(src: activity.cover, width: 82.r, height: 82.r, radius: 8.r),
        ],
      ),
    );
  }

  Widget _badge(String label, Color background, Color color, {String? icon}) =>
      Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: color),
        ),
      );

  Widget _detail(String icon, String label) => Row(
    children: [
      SvgPicture.asset(
        'assets/profile/profile_activity_$icon.svg',
        width: 14.r,
        height: 14.r,
      ),
      SizedBox(width: 7.w),
      Flexible(child: Text(label, style: _muted(11))),
    ],
  );

  TextStyle _muted(double size) =>
      TextStyle(fontSize: size.sp, color: const Color(0xFF999999));
}
