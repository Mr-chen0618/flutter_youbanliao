import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'teen_mode_provider.dart';

/// 根导航上方的独立导航，覆盖所有平台页面且允许监护验证。
class TeenModeGate extends ConsumerStatefulWidget {
  const TeenModeGate({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<TeenModeGate> createState() => _TeenModeGateState();
}

class _TeenModeGateState extends ConsumerState<TeenModeGate> {
  bool latched = false;
  @override
  Widget build(BuildContext context) => ref
      .watch(teenModeProvider)
      .when(
        loading: () => const ColoredBox(
          color: Color(0xFFF6F6F6),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Material(
          child: Center(
            child: TextButton(
              onPressed: () => ref.invalidate(teenModeProvider),
              child: const Text('监护设置读取失败，点击重试'),
            ),
          ),
        ),
        data: (enabled) {
          if (enabled) latched = true;
          return latched
              ? Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => TeenModePage(
                      locked: true,
                      onFinished: () => setState(() => latched = false),
                    ),
                  ),
                )
              : widget.child;
        },
      );
}

class TeenModePage extends ConsumerStatefulWidget {
  const TeenModePage({super.key, this.locked = false, this.onFinished});
  final bool locked;
  final VoidCallback? onFinished;
  @override
  ConsumerState<TeenModePage> createState() => _TeenModePageState();
}

class _TeenModePageState extends ConsumerState<TeenModePage> {
  int step = 0;
  String first = '', pin = '', error = '';
  bool busy = false, success = false;
  bool get enabled => ref.read(teenModeProvider).value == true;
  void next() => setState(() {
    step = enabled ? 3 : 1;
    pin = '';
    error = '';
  });
  Future<void> keyPress(String key) async {
    if (busy) return;
    setState(() {
      error = '';
      pin = key == '⌫'
          ? (pin.isEmpty ? '' : pin.substring(0, pin.length - 1))
          : '$pin$key';
    });
    if (pin.length != 4) return;
    if (step == 1) {
      setState(() {
        first = pin;
        pin = '';
        step = 2;
      });
      return;
    }
    if (step == 2 && first != pin) {
      setState(() {
        pin = '';
        error = '两次密码不一致，请重新输入';
      });
      return;
    }
    setState(() => busy = true);
    try {
      if (step == 2) {
        await ref.read(teenModeProvider.notifier).enable(pin);
        if (mounted) {
          setState(() {
            step = 0;
            pin = '';
          });
        }
      } else {
        final accepted = await ref.read(teenModeProvider.notifier).disable(pin);
        if (mounted) {
          setState(() {
            pin = '';
            if (accepted) {
              step = 0;
              success = true;
            } else {
              error = '密码错误，请重新输入';
            }
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          pin = '';
          error = '保存失败，请重试';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(teenModeProvider);
    final password = step > 0;
    return PopScope(
      canPop: !widget.locked,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AppBar(
          toolbarHeight: 48.h,
          backgroundColor: const Color(0xFFF6F6F6),
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            password
                ? (step == 1
                      ? '设置密码'
                      : step == 2
                      ? '确认密码'
                      : '关闭青少年模式')
                : '青少年模式',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF333333),
            ),
          ),
          leading: widget.locked && !password
              ? const SizedBox.shrink()
              : BackButton(
                  onPressed: () {
                    if (password) {
                      setState(() {
                        step = 0;
                        pin = '';
                        first = '';
                      });
                    } else {
                      Navigator.maybePop(context);
                    }
                  },
                ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = math.max(constraints.maxHeight, 684.h);
              return SingleChildScrollView(
                child: SizedBox(
                  height: height,
                  child: password ? _passwordCanvas() : _statusCanvas(height),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _label(
    String value, {
    double size = 13,
    Color color = const Color(0xFF888888),
    TextAlign align = TextAlign.left,
    FontWeight weight = FontWeight.normal,
  }) => Text(
    value,
    textAlign: align,
    style: TextStyle(
      fontSize: size.sp,
      color: color,
      fontWeight: weight,
      height: 1.4,
    ),
  );
  Widget _slot(
    double top,
    double left,
    double width,
    double height,
    Widget child,
  ) => Positioned(
    top: top.h,
    left: left.w,
    width: width.w,
    height: height.h,
    child: child,
  );
  Widget _surface({required double radius, Color color = Colors.white}) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius.r),
        ),
      );
  Widget _centerText(
    String value, {
    double size = 13,
    Color color = const Color(0xFF888888),
    FontWeight weight = FontWeight.normal,
  }) => _label(
    value,
    size: size,
    color: color,
    align: TextAlign.center,
    weight: weight,
  );
  Widget _statusCanvas(double height) {
    final closed = success && !enabled;
    final buttonY = height - (enabled || closed ? 128.h : 80.h);
    return Stack(
      children: [
        if (!enabled && !closed) ...[
          _slot(
            24,
            97,
            180,
            150,
            SvgPicture.asset('assets/profile/teen_umbrella.svg'),
          ),
          _slot(
            190,
            24,
            327,
            30,
            _centerText(
              '青少年模式未开启',
              size: 21,
              color: const Color(0xFF333333),
              weight: FontWeight.w500,
            ),
          ),
          _slot(
            236,
            24,
            327,
            42,
            _centerText('开启后，友伴聊平台内容与服务将暂停。关闭青少年模式后，方可继续使用。'),
          ),
          _slot(286, 16, 343, 170, _surface(radius: 18)),
          _slot(
            304,
            32,
            295,
            21,
            _label(
              '使用方法',
              size: 15,
              color: const Color(0xFF333333),
              weight: FontWeight.w500,
            ),
          ),
          _slot(335, 32, 311, 1, const ColoredBox(color: Color(0xFFEBEBEB))),
          _slot(
            351,
            32,
            28,
            20,
            _label(
              '01',
              size: 11,
              color: const Color(0xFFB18000),
              weight: FontWeight.w500,
            ),
          ),
          _slot(351, 68, 264, 34, _label('开启后立即生效，关闭时需验证监护密码。', size: 12)),
          _slot(
            389,
            32,
            28,
            20,
            _label(
              '02',
              size: 11,
              color: const Color(0xFFB18000),
              weight: FontWeight.w500,
            ),
          ),
          _slot(389, 68, 264, 38, _label('关闭青少年模式后，方可继续使用平台内容与服务。', size: 12)),
          _slot(473, 24, 327, 18, _centerText('请由监护人设置并妥善保管密码。', size: 11)),
        ] else if (enabled) ...[
          _slot(32, 16, 343, 202, _surface(radius: 20)),
          _slot(
            54,
            162,
            52,
            52,
            SvgPicture.asset('assets/profile/teen_enabled.svg'),
          ),
          _slot(
            69,
            174,
            28,
            22,
            _centerText(
              'Ⅱ',
              size: 20,
              color: Colors.white,
              weight: FontWeight.w500,
            ),
          ),
          _slot(
            94,
            158,
            60,
            24,
            _surface(radius: 12, color: const Color(0xFFFFF6D8)),
          ),
          _slot(
            98,
            158,
            60,
            16,
            _centerText(
              '已开启',
              size: 11,
              color: const Color(0xFFE7A900),
              weight: FontWeight.w500,
            ),
          ),
          _slot(
            128,
            32,
            311,
            28,
            _centerText(
              '青少年模式已开启',
              size: 20,
              color: const Color(0xFF333333),
              weight: FontWeight.w500,
            ),
          ),
          _slot(169, 32, 311, 22, _centerText('开启期间，平台内容与服务暂停。', size: 14)),
          _slot(
            256,
            16,
            343,
            114,
            _surface(radius: 18, color: const Color(0xFFFFF6D8)),
          ),
          _slot(
            276,
            32,
            295,
            22,
            _label(
              '关闭后方可继续使用',
              size: 15,
              color: const Color(0xFF333333),
              weight: FontWeight.w500,
            ),
          ),
          _slot(
            309,
            32,
            295,
            42,
            _label('如需使用平台内容与服务，请关闭青少年模式并完成监护密码验证。', size: 12),
          ),
        ] else ...[
          _slot(
            78,
            139,
            96,
            96,
            SvgPicture.asset('assets/profile/teen_success.svg'),
          ),
          _slot(
            99,
            139,
            96,
            52,
            _centerText(
              '✓',
              size: 38,
              color: const Color(0xFF52B788),
              weight: FontWeight.w500,
            ),
          ),
          _slot(
            210,
            24,
            327,
            30,
            _centerText(
              '青少年模式已关闭',
              size: 21,
              color: const Color(0xFF333333),
              weight: FontWeight.w500,
            ),
          ),
          _slot(252, 24, 327, 22, _centerText('现在可以继续使用平台内容与服务。')),
          _slot(314, 16, 343, 82, _surface(radius: 18)),
          _slot(
            332,
            32,
            279,
            20,
            _label(
              '服务已恢复',
              size: 14,
              color: const Color(0xFF333333),
              weight: FontWeight.w500,
            ),
          ),
          _slot(360, 32, 295, 18, _label('你也可以在设置中重新开启青少年模式。', size: 12)),
        ],
        Positioned(
          top: buttonY,
          left: 16.w,
          right: 16.w,
          height: 52.h,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFD13F),
              foregroundColor: const Color(0xFF333333),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: closed
                ? () {
                    if (widget.onFinished != null) {
                      widget.onFinished!();
                    } else {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  }
                : next,
            child: Text(
              closed
                  ? '返回首页'
                  : enabled
                  ? '关闭青少年模式'
                  : '开启青少年模式',
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordCanvas() => Stack(
    children: [
      _slot(
        40,
        24,
        327,
        30,
        _label(
          step == 1
              ? '设置监护密码'
              : step == 2
              ? '再次输入密码'
              : '请输入监护密码',
          size: 21,
          color: const Color(0xFF333333),
          weight: FontWeight.w500,
        ),
      ),
      _slot(
        78,
        24,
        327,
        38,
        _label(
          step == 1
              ? '请设置 4 位数字密码，并由监护人妥善保管'
              : step == 2
              ? '再次输入 4 位数字密码，完成设置'
              : '验证通过后，青少年模式将关闭',
        ),
      ),
      _slot(
        128,
        24,
        108,
        25,
        _surface(
          radius: 13,
          color: step == 3 ? Colors.white : const Color(0xFFFFF6D8),
        ),
      ),
      _slot(
        133,
        32,
        92,
        16,
        _centerText(
          step == 3 ? '关闭验证' : '设置步骤  0$step / 02',
          size: 10,
          color: step == 3 ? const Color(0xFF8A8A8A) : const Color(0xFFE7A900),
          weight: FontWeight.w500,
        ),
      ),
      if (step != 3) ...[
        _slot(
          139,
          150,
          201,
          4,
          _surface(radius: 2, color: const Color(0xFFE9E9E9)),
        ),
        _slot(
          139,
          step == 1 ? 150 : 250,
          step == 1 ? 100 : 101,
          4,
          _surface(radius: 2, color: const Color(0xFFFFD13F)),
        ),
      ],
      _slot(171, 24, 327, 54, _surface(radius: 16)),
      for (var i = 0; i < 4; i++)
        _slot(
          185,
          103 + i * 52,
          12,
          12,
          pin.length > i
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF333333),
                    shape: BoxShape.circle,
                  ),
                )
              : SvgPicture.asset('assets/profile/teen_pin_empty.svg'),
        ),
      _slot(
        239,
        24,
        327,
        18,
        _centerText(error.isEmpty ? '请输入 4 位数字密码' : error, size: 12),
      ),
      for (var row = 0; row < 4; row++)
        for (var col = 0; col < 3; col++)
          if (row < 3 || col > 0)
            _slot(
              270 + row * 64,
              31 + col * 112,
              88,
              58,
              _numberKey(
                row == 3 ? (col == 1 ? '0' : '⌫') : '${row * 3 + col + 1}',
              ),
            ),
      _slot(
        538,
        24,
        327,
        20,
        _centerText(
          step == 3
              ? '忘记密码？请联系监护人协助重置'
              : step == 2
              ? '两次密码需保持一致'
              : '关闭青少年模式时，需要验证此密码',
          size: 11,
          color: step == 3 ? const Color(0xFFE7A900) : const Color(0xFF8A8A8A),
        ),
      ),
    ],
  );
  Widget _numberKey(String key) {
    const captions = {
      '2': 'ABC',
      '3': 'DEF',
      '4': 'GHI',
      '5': 'JKL',
      '6': 'MNO',
      '7': 'PQRS',
      '8': 'TUV',
      '9': 'WXYZ',
    };
    return FilledButton(
      style: FilledButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFFEFEFEF)),
        ),
      ),
      onPressed: busy ? null : () => keyPress(key),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _centerText(
            key,
            size: 21,
            color: const Color(0xFF333333),
            weight: FontWeight.w500,
          ),
          if (captions.containsKey(key))
            _centerText(
              captions[key]!,
              size: 9,
              color: const Color(0xFF999999),
            ),
        ],
      ),
    );
  }
}
