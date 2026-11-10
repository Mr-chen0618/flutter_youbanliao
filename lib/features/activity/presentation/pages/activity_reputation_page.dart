import '../../../../app/widgets/business_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../data/model/activity_reputation.dart';
import '../providers/activity_reputation_provider.dart';

/// 展示活动信誉分、计分规则和履约记录。
class ActivityReputationPage extends ConsumerWidget {
  const ActivityReputationPage({super.key});

  static const _muted = Color(0xFF999999);
  static const _brown = Color(0xFF91641A);

  @override
  Widget build(BuildContext context, WidgetRef ref) => CompanionPageSurface(
    title: '活动信誉分',
    child: ref
        .watch(activityReputationProvider)
        .when(
          skipError: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(activityReputationProvider),
              child: const Text('加载失败，点击重试'),
            ),
          ),
          data: (data) => BusinessRefresh(
            scope: 'reputation',
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
              children: [
                // 当前信誉
                CompanionCardSurfaceWidget(
                  padding: EdgeInsets.all(18.w),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _icon('shield', 18),
                          SizedBox(width: 6.w),
                          const Text(
                            '当前活动信誉分',
                            style: TextStyle(color: Color(0xFF666666)),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${data.score}',
                              style: TextStyle(
                                fontSize: 64.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B1005),
                              ),
                            ),
                            TextSpan(
                              text: ' 分',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD04F),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _icon('check', 14),
                            SizedBox(width: 4.w),
                            Text(
                              '每一次如约，都值得信赖',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '初始默认 100 分 · 如期到达不扣分',
                        style: TextStyle(color: _muted, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                // 信誉规则与履约提醒
                CompanionCardSurfaceWidget(
                  padding: EdgeInsets.all(18.w),
                  child: Column(
                    children: [
                      _heading('信誉分如何变化', '当前暂定规则'),
                      SizedBox(height: 12.h),
                      _rule('attended', '如期到达', '按约参加活动，分值保持不变', '0 分', false),
                      SizedBox(height: 12.h),
                      _rule('missed', '活动爽约', '未按约到场，每次扣除 10 分', '−10 分', true),
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6E1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _icon('bell', 14),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                '记得预留出行时间；行程有变时，提前联系活动伙伴，别让彼此空等。',
                                style: TextStyle(
                                  color: _brown,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                // 分值变动记录
                CompanionCardSurfaceWidget(
                  padding: EdgeInsets.all(18.w),
                  child: Column(
                    children: [
                      _heading('活动记录', '分值变动'),
                      if (data.records.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('暂无活动记录'),
                        ),
                      for (final (index, record) in data.records.indexed) ...[
                        if (index > 0) const Divider(color: Color(0xFFF3F3F3)),
                        Padding(
                          padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
                          child: _record(record),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
  );

  /// 卡片标题与右侧说明。
  Widget _heading(String title, String note) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
      Text(
        note,
        style: TextStyle(fontSize: 10.sp, color: _muted),
      ),
    ],
  );

  /// 单项信誉规则。
  Widget _rule(
    String icon,
    String title,
    String note,
    String points,
    bool missed,
  ) => Row(
    children: [
      Container(
        width: 36.r,
        height: 36.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: missed ? const Color(0xFFFDEEEE) : const Color(0xFFFFF6E1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: _icon(icon, 20),
      ),
      SizedBox(width: 10.w),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              note,
              style: TextStyle(fontSize: 11.sp, color: _muted),
            ),
          ],
        ),
      ),
      Text(
        points,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: missed ? const Color(0xFFDA5748) : null,
        ),
      ),
    ],
  );

  /// 一条活动履约记录。
  Widget _record(ReputationRecord record) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${record.change == 0 ? '如期到达' : '活动爽约'}   ${record.date}',
              style: TextStyle(fontSize: 10.sp, color: _muted),
            ),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${record.change}',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          Text(
            record.change == 0 ? '不扣分' : '已扣分',
            style: TextStyle(fontSize: 10.sp, color: _muted),
          ),
        ],
      ),
    ],
  );

  Widget _icon(String name, double size) => SvgPicture.asset(
    'assets/profile/profile_reputation_$name.svg',
    width: size.r,
    height: size.r,
  );
}
