import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../purchases/presentation/providers/apple_purchase_provider.dart';
import '../providers/growth_provider.dart';

Future<void> showSignInDialog(BuildContext context) => showDialog<void>(
  context: context,
  barrierColor: const Color(0xB3000000),
  builder: (_) => const SignInDialog(),
);

/// 签到与成功共用同一覆盖层，领取结果由原子账本决定。
class SignInDialog extends ConsumerStatefulWidget {
  const SignInDialog({super.key});
  @override
  ConsumerState<SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends ConsumerState<SignInDialog> {
  bool _busy = false;
  bool _success = false;
  Future<void> _check() async {
    if (_busy) return;
    setState(() => _busy = true);
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
      if (mounted) setState(() => _success = true);
    } catch (_) {
      AppToast.show('签到失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final growth = ref.watch(growthProvider);
    final checks = growth.value?.checks ?? <String>[];
    final today = DateTime.now();
    String day(DateTime d) => d.toIso8601String().substring(0, 10);
    final checked = checks.contains(day(today));
    int consecutive = 0;
    var cursor = checked ? today : today.subtract(const Duration(days: 1));
    while (checks.contains(day(cursor))) {
      consecutive++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    final index = consecutive % 7;
    Widget image(String name, double width, double height) => AppImage(
      src: 'assets/profile/sign_in_$name',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
    final success = _success || checked;
    Widget tile(int i, double width, double scale) {
      final active = i == index && !checked;
      return Container(
        width: width * scale,
        height: 98 * scale,
        padding: EdgeInsets.all(6 * scale),
        decoration: BoxDecoration(
          color: active ? null : Colors.white,
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFF4B52), Color(0xFFFF8353)],
                )
              : null,
          borderRadius: BorderRadius.circular(12 * scale),
          border: active ? Border.all(color: Colors.white) : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: i < index ? 0.67 : 1.0,
                      child: image('coin.png', 31.92 * scale, 31.92 * scale),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '金币x1',
                      style: TextStyle(
                        fontSize: 10 * scale,
                        color: const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              active ? '今天' : '第${i + 1}天',
              style: TextStyle(
                fontSize: 12 * scale,
                color: active
                    ? Colors.white
                    : i < index
                    ? const Color(0xFFCCCCCC)
                    : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      alignment: const Alignment(0, .05),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(0.0, 375.0);
          final scale = width / 375;
          Widget pos(double x, double y, double w, double h, Widget child) =>
              Positioned(
                left: x * scale,
                top: y * scale,
                width: w * scale,
                height: h * scale,
                child: child,
              );
          Widget line(bool reverse) => Container(
            width: 29 * scale,
            height: 2 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: reverse
                    ? const [Color(0xFFD96D9A), Color(0x00D96D9A)]
                    : const [Color(0x00D96D9A), Color(0xFFD96D9A)],
              ),
            ),
          );
          return SingleChildScrollView(
            child: SizedBox(
              width: width,
              height: 525 * scale,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 纯装饰层3628:23444导出，包含原滤镜/高光，不含文字、格子、按钮。
                  pos(
                    24,
                    0,
                    351,
                    463,
                    image('decoration.png', 351 * scale, 463 * scale),
                  ),
                  pos(
                    56,
                    62,
                    200,
                    30,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        success ? '签到成功！！' : '做任务 领奖励',
                        style: TextStyle(
                          fontSize: 21 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  pos(
                    65,
                    94,
                    200,
                    18,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        success ? '每天登录，奖励领不停' : '连续签到领福利！！',
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: const Color(0xFFFFE5B6),
                        ),
                      ),
                    ),
                  ),
                  pos(
                    30,
                    106,
                    49,
                    49,
                    image('mascot.png', 49 * scale, 49 * scale),
                  ),
                  if (success) ...[
                    pos(
                      103,
                      147,
                      170,
                      29,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          line(false),
                          Flexible(
                            child: Text(
                              '恭喜获得',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24 * scale,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF9D0043),
                              ),
                            ),
                          ),
                          line(true),
                        ],
                      ),
                    ),
                    pos(
                      129,
                      196,
                      118,
                      118,
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16 * scale),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            image('coin.png', 48 * scale, 48 * scale),
                            SizedBox(height: 8 * scale),
                            Text(
                              '金币x1',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    pos(
                      70,
                      135,
                      236,
                      20,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.rotate(
                            angle: 2.356,
                            child: Transform.flip(
                              flipY: true,
                              child: image(
                                'arrow_left.svg',
                                16 * scale,
                                16 * scale,
                              ),
                            ),
                          ),
                          SizedBox(width: 4 * scale),
                          Text(
                            '已连续签到$consecutive天',
                            style: TextStyle(
                              fontSize: 14 * scale,
                              color: const Color(0xFFA61D3F),
                            ),
                          ),
                          SizedBox(width: 4 * scale),
                          Transform.rotate(
                            angle: 0.7854,
                            child: image(
                              'arrow_right.svg',
                              16 * scale,
                              16 * scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pos(
                      46,
                      163,
                      284,
                      98,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i < 4; i++) tile(i, 68, scale),
                        ],
                      ),
                    ),
                    pos(
                      46,
                      267,
                      284,
                      98,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          tile(4, 68, scale),
                          tile(5, 68, scale),
                          tile(6, 140, scale),
                        ],
                      ),
                    ),
                  ],
                  pos(
                    81,
                    381,
                    213,
                    52,
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8330), Color(0xFFFF3056)],
                        ),
                        borderRadius: BorderRadius.circular(40 * scale),
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: _busy || growth.isLoading
                            ? null
                            : success
                            ? () => Navigator.pop(context)
                            : _check,
                        child: Text(
                          _busy
                              ? '签到中…'
                              : success
                              ? '明日再来'
                              : '签到',
                          style: TextStyle(
                            fontSize: 24 * scale,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFF0CE),
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 2,
                                color: Color(0x40000000),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  pos(
                    168,
                    485,
                    40,
                    40,
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.cancel_outlined,
                        color: Colors.white70,
                        size: 40 * scale,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
