import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../data/model/activity_detail.dart';
import '../providers/activity_detail_provider.dart';
import '../providers/activity_reputation_provider.dart';

/// 报名确认页核对活动信息和守约声明后才保存报名。
class ActivityJoinPage extends ConsumerStatefulWidget {
  const ActivityJoinPage({super.key, required this.id, required this.activity});
  final String id;
  final ActivityDetail activity;
  @override
  ConsumerState<ActivityJoinPage> createState() => _ActivityJoinPageState();
}

class _ActivityJoinPageState extends ConsumerState<ActivityJoinPage> {
  bool _agreed = false, _saving = false;
  Future<void> _submit() async {
    if (!_agreed || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(activityDetailRepositoryProvider).join(widget.id);
      ref.invalidate(activityDetailProvider(widget.id));
      ref.invalidate(joinedActivityIdsProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      AppToast.showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final reputation = ref.watch(activityReputationProvider);
    return CompanionPageSurface(
      title: '报名确认',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                CompanionCardSurfaceWidget(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '请确认本次活动安排',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.title,
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          AppImage(
                            src: activity.cover,
                            width: 64.r,
                            height: 64.r,
                            radius: 12.r,
                          ),
                        ],
                      ),
                      Text(activity.description),
                      SizedBox(height: 16.h),
                      ListTile(
                        leading: const Icon(Icons.schedule),
                        title: const Text('活动时间'),
                        subtitle: Text(
                          activity.eventTime?.toString() ?? '发布者尚未填写，请提前联系确认',
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.map_outlined),
                        title: const Text('集合地点'),
                        subtitle: Text(activity.location),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                CompanionCardSurfaceWidget(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: reputation.when(
                      loading: () => const Text('正在读取信誉分…'),
                      error: (_, _) => TextButton(
                        onPressed: () =>
                            ref.invalidate(activityReputationProvider),
                        child: const Text('信誉分读取失败，点击重试'),
                      ),
                      data: (value) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('当前信誉分 ${value.score}分'),
                          const Text('信誉良好，可直接报名无需审核'),
                          if (activity.joinBlockedReason case final reason?)
                            Text(
                              reason,
                              style: const TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6DF),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Text('如期到达不扣分，爽约扣10分/次\n请预留出行时间，行程有变请提前沟通。'),
                ),
              ],
            ),
          ),
          CheckboxListTile(
            value: _agreed,
            onChanged: _saving
                ? null
                : (value) => setState(() => _agreed = value!),
            title: const Text('我已核对活动时间与集合地点，确认可按时到达'),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD04F),
                foregroundColor: Colors.black,
                minimumSize: Size.fromHeight(48.h),
              ),
              onPressed:
                  _agreed &&
                      !_saving &&
                      reputation.hasValue &&
                      activity.joinBlockedReason == null
                  ? _submit
                  : null,
              child: Text(_saving ? '提交中' : '提交报名'),
            ),
          ),
        ],
      ),
    );
  }
}
