import 'profile_shop_page.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../data/model/growth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/navigation/app_navigator.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../purchases/presentation/providers/apple_purchase_provider.dart';
import '../providers/growth_provider.dart';
import 'user_verification_page.dart';
import '../../../messages/presentation/pages/messages_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../square/presentation/pages/square_publish_page.dart';

import 'real_person_page.dart';
import 'video_show_page.dart';

/// 任务入口由真实业务动作驱动；认证奖励等待审核服务，不在客户端假发放。
class TaskCenterPage extends ConsumerStatefulWidget {
  const TaskCenterPage({super.key, this.signInOnly = false});
  final bool signInOnly;
  @override
  ConsumerState<TaskCenterPage> createState() => _TaskCenterState();
}

class _TaskCenterState extends ConsumerState<TaskCenterPage> {
  bool busy = false;
  Future<void> check() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final repo = ref.read(growthRepositoryProvider);
      await ref
          .read(purchaseFulfillmentProvider)
          .loadEntitlements(repo.accountId);
      await repo.checkIn(DateTime.now());
      ref.invalidate(growthProvider);
      await ref
          .read(applePurchaseControllerProvider)
          .refreshEntitlements(repo.accountId);
      AppToast.show('签到成功，获得1金币');
    } catch (e) {
      AppToast.show('签到失败，请重试');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(growthProvider);
    final account = ref.watch(growthRepositoryProvider).accountId;
    final balance = ref
        .watch(applePurchaseStateProvider)
        .value
        ?.entitlements[account]
        ?.coinBalance;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 48,
        title: const Text(
          '任务中心',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: _rules,
            child: const Text(
              '规则',
              style: TextStyle(fontSize: 13, color: Color(0xFF665E50)),
            ),
          ),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(growthProvider),
            child: const Text('加载失败，点击重试'),
          ),
        ),
        data: (value) {
          final now = DateTime.now();
          String day(DateTime d) => d.toIso8601String().substring(0, 10);
          final checked = value.checks.contains(day(now));
          var cursor = checked ? now : now.subtract(const Duration(days: 1));
          var consecutive = 0;
          while (value.checks.contains(day(cursor))) {
            consecutive++;
            cursor = cursor.subtract(const Duration(days: 1));
          }
          final monday = now.subtract(Duration(days: now.weekday - 1));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Container(
                height: 122,
                padding: const EdgeInsets.fromLTRB(16, 0, 14, 0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            '我的金币',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA89D82),
                            ),
                          ),
                          const SizedBox(height: 3),
                          InkWell(
                            onTap: () => AppNavigator.push<void>(
                              context,
                              page: CoinRechargePage(balance: balance ?? 0),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${balance ?? '—'}',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2F2D2A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '金币 ›',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF39352E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            '签到和完成任务赚金币',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA89D82),
                            ),
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                    const AppImage(
                      src: 'assets/profile/growth/3748_26714_img.png',
                      width: 124,
                      height: 114,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD23F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Text(
                        '已连续签到$consecutive天',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF292929),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: List.generate(7, (i) {
                              final claimed = value.checks.contains(
                                day(monday.add(Duration(days: i))),
                              );
                              return Expanded(
                                child: Column(
                                  children: [
                                    Container(
                                      height: 64,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8E8),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        children: [
                                          const AppImage(
                                            src:
                                                'assets/profile/growth/3748_26714_img2.png',
                                            width: 30,
                                            height: 30,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            claimed ? '已领' : 'x1',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: claimed
                                                  ? const Color(0xFFAAAAAA)
                                                  : const Color(0xFFFF920D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      [
                                        '周一',
                                        '周二',
                                        '周三',
                                        '周四',
                                        '周五',
                                        '周六',
                                        '周日',
                                      ][i],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: claimed
                                            ? const Color(0xFFAAAAAA)
                                            : const Color(0xFF333333),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 44,
                            width: 202,
                            child: FilledButton(
                              style: _buttonStyle,
                              onPressed: checked || busy ? null : check,
                              child: Text(
                                checked
                                    ? '明日再来'
                                    : busy
                                    ? '领取中…'
                                    : '签到领取',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _group('新手任务', [
                _row(
                  '发布视频秀',
                  '完成 1 次·+10金币',
                  'img1',
                  const Color(0xFFFFF2D4),
                  value.video != null ? '查看' : '去完成',
                  () => AppNavigator.push<void>(
                    context,
                    page: const VideoShowPage(),
                  ),
                ),
                _row(
                  '真人认证',
                  '拍照完成核验·+10金币',
                  'img3',
                  const Color(0xFFEAF3FF),
                  value.realPerson ? '查看' : '去完成',
                  () => AppNavigator.push<void>(
                    context,
                    page: const RealPersonPage(),
                  ),
                ),
                _row(
                  '实名认证',
                  '完善身份信息·+10金币',
                  'img4',
                  const Color(0xFFFFF0ED),
                  value.identityPending ? '查看' : '去完成',
                  () => AppNavigator.push<void>(
                    context,
                    page: const UserVerificationPage(),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              _group('每日任务', [
                _daily(
                  '发布一条动态',
                  '分享今天的生活·+10金币',
                  'publish',
                  'img5',
                  const Color(0xFFEAF3FF),
                  value,
                  const SquarePublishPage(),
                ),
                _daily(
                  '完成一次聊天',
                  '和搭子聊聊兴趣·+10金币',
                  'chat',
                  'img6',
                  const Color(0xFFFFF5DE),
                  value,
                  const MessagesPage(),
                ),
                _daily(
                  '发现新搭子',
                  '浏览推荐用户·+10金币',
                  'discover',
                  'img7',
                  const Color(0xFFECF7EF),
                  value,
                  const HomePage(),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  ButtonStyle get _buttonStyle => FilledButton.styleFrom(
    backgroundColor: const Color(0xFFFFD23F),
    foregroundColor: const Color(0xFF362B13),
    padding: EdgeInsets.zero,
    shape: const StadiumBorder(),
  );
  void _rules() => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('任务规则'),
      content: const Text(
        '每天签到可领取1金币。每日任务完成后可领取10金币，每项每日一次。新手任务奖励待视频或认证审核通过后发放。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
  Widget _group(String title, List<Widget> rows) => Container(
    height: 242,
    padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF292929),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: _rules,
              child: const Text(
                '更多 ›',
                style: TextStyle(fontSize: 10, color: Color(0xFF999999)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final (i, row) in rows.indexed) ...[
          row,
          if (i < rows.length - 1)
            const Padding(
              padding: EdgeInsets.only(left: 52),
              child: Divider(height: 1, color: Color(0xFFECECEC)),
            ),
        ],
      ],
    ),
  );
  Widget _row(
    String title,
    String subtitle,
    String asset,
    Color color,
    String action,
    VoidCallback? onPressed,
  ) => SizedBox(
    height: 59,
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: AppImage(
              src: 'assets/profile/growth/3748_26714_$asset.svg',
              width: 22,
              height: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF292929),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 66,
          height: 30,
          child: FilledButton(
            style: _buttonStyle,
            onPressed: onPressed,
            child: Text(action, style: const TextStyle(fontSize: 10)),
          ),
        ),
      ],
    ),
  );
  Widget _daily(
    String title,
    String subtitle,
    String key,
    String asset,
    Color color,
    GrowthState data,
    Widget page,
  ) {
    final day = DateTime.now().toIso8601String().substring(0, 10);
    final completed = data.days[key] == day;
    final claimed = data.claims[key] == day;
    return _row(
      title,
      subtitle,
      asset,
      color,
      claimed
          ? '已领取'
          : completed
          ? '领取'
          : '去完成',
      busy || claimed
          ? null
          : () async {
              if (!completed) {
                await AppNavigator.push<void>(context, page: page);
                return;
              }
              setState(() => busy = true);
              try {
                final repo = ref.read(growthRepositoryProvider);
                await ref
                    .read(purchaseFulfillmentProvider)
                    .loadEntitlements(repo.accountId);
                await repo.claimDaily(key, DateTime.now());
                ref.invalidate(growthProvider);
                await ref
                    .read(applePurchaseControllerProvider)
                    .refreshEntitlements(repo.accountId);
                AppToast.show('领取成功');
              } catch (e) {
                AppToast.show('领取失败，请重试');
              } finally {
                if (mounted) setState(() => busy = false);
              }
            },
    );
  }
}
