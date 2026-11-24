import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/config/app_globals.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../teen/presentation/teen_mode_provider.dart';
import '../providers/growth_provider.dart';
import '../pages/sign_in_dialog.dart';

final signInNowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// 登录完成且解除青少年锁后，每次打开为未签到账号提醒一次。
class DailySignInGate extends ConsumerStatefulWidget {
  const DailySignInGate({super.key, required this.child, this.navigatorKey});
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;
  @override
  ConsumerState<DailySignInGate> createState() => _DailySignInGateState();
}

class _DailySignInGateState extends ConsumerState<DailySignInGate>
    with WidgetsBindingObserver {
  String? _eligibility;
  int _epoch = 0;
  DialogRoute<void>? _route;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _epoch++;
    final route = _route;
    _route = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route?.isActive == true) route!.navigator?.removeRoute(route);
    });
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final auth = ref.read(authSessionProvider).value;
      final now = ref.read(signInNowProvider)();
      final key = auth == null
          ? null
          : '${auth.accountId}:${now.toIso8601String().substring(0, 10)}';
      if (_route?.isActive == true && key == _eligibility) return;
      _eligibility = null;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authSessionProvider);
    final auth = authState.value;
    final teen = ref.watch(teenModeProvider);
    final now = ref.read(signInNowProvider)();
    final eligible =
        !authState.isLoading &&
        !authState.hasError &&
        auth != null &&
        auth.profileCompleted &&
        !teen.isLoading &&
        !teen.hasError &&
        teen.hasValue &&
        teen.value == false;
    final key = eligible
        ? '${auth.accountId}:${now.toIso8601String().substring(0, 10)}'
        : null;
    if (key != _eligibility) {
      _eligibility = key;
      final epoch = ++_epoch;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || epoch != _epoch) return;
        _dismiss();
        if (key != null) _show(epoch);
      });
    }
    return widget.child;
  }

  void _dismiss() {
    final route = _route;
    _route = null;
    if (route?.isActive == true) {
      route!.navigator?.removeRoute(route);
    }
  }

  Future<void> _show(int epoch) async {
    final navigator =
        (widget.navigatorKey ?? globalKeyNavigatorKey).currentState;
    if (navigator?.overlay == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && epoch == _epoch) _show(epoch);
      });
      return;
    }
    final repo = ref.read(growthRepositoryProvider);
    try {
      final now = ref.read(signInNowProvider)();
      final token =
          'gate:${identityHashCode(this)}:$epoch:${DateTime.now().microsecondsSinceEpoch}';
      final accepted = await repo.reserveAutomaticSignIn(now, token);
      if (!accepted) return;
      if (!mounted || epoch != _epoch || navigator!.overlay == null) {
        await repo.releaseAutomaticSignIn(token);
        return;
      }
      final confirmed = await repo.confirmAutomaticSignIn(now, token);
      if (!confirmed) return;
      if (!mounted || epoch != _epoch || navigator.overlay == null) {
        await repo.releaseAutomaticSignIn(token);
        return;
      }
      final route = DialogRoute<void>(
        context: navigator.overlay!.context,
        barrierColor: const Color(0xB3000000),
        builder: (_) => const SignInDialog(),
      );
      _route = route;
      await navigator.push(route);
      if (identical(_route, route)) _route = null;
    } catch (_) {
      /* 本地读取失败不阻塞主业务，下一次恢复到前台可重试。 */
    }
  }
}
