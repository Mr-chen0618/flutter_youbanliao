import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/navigation/main_tab_shell.dart';
import '../../../../app/navigation/app_router.dart';
import '../../../../app/navigation/app_navigator.dart';
import '../../../../core/storage/mock_json_store.dart';
import '../../../../core/storage/account_mock_json_store.dart';
import '../../../user/presentation/providers/profile_provider.dart';
import '../../data/model/auth_session.dart';
import '../../data/repository/auth_repository.dart';
import '../providers/auth_provider.dart';
import 'phone_login_page.dart';
import 'registration_profile_page.dart';

/// 根路由只由持久化会话决定，退出时销毁账号下的全部页面和状态。
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    return session.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(authSessionProvider),
            child: const Text('账号读取失败，点击重试'),
          ),
        ),
      ),
      data: (session) {
        final auth = ref.read(authRepositoryProvider);
        void reload() => ref.invalidate(authSessionProvider);
        if (session == null) {
          return PhoneLoginPage(auth: auth, onSignedIn: reload);
        }
        if (!session.profileCompleted) {
          return RegistrationProfilePage(
            session: session,
            auth: auth,
            onChanged: reload,
          );
        }
        return _AccountScope(
          key: ValueKey(session.accountId),
          store: AccountMockJsonStore(
            ref.read(mockJsonStoreProvider),
            session.accountId,
          ),
          child: _AccountNavigator(
            session: session,
            auth: auth,
            reload: reload,
          ),
        );
      },
    );
  }
}

/// 独立 Navigator 让退出登录能丢弃所有二三级页面。
class _AccountNavigator extends ConsumerStatefulWidget {
  const _AccountNavigator({
    required this.session,
    required this.auth,
    required this.reload,
  });
  final AuthSession session;
  final AuthRepository auth;
  final VoidCallback reload;
  @override
  ConsumerState<_AccountNavigator> createState() => _AccountNavigatorState();
}

class _AccountNavigatorState extends ConsumerState<_AccountNavigator> {
  bool _leaving = false, _deleteRequested = false;
  Object? _exitError;
  Future<void> _leave(bool deleted) async {
    if (_leaving) return;
    _deleteRequested = deleted;
    setState(() {
      _leaving = true;
      _exitError = null;
    });
    try {
      if (deleted) {
        await widget.auth.deleteAccount(widget.session.accountId);
      } else {
        await widget.auth.signOut();
      }
      if (mounted) widget.reload();
    } catch (error) {
      if (mounted) {
        setState(() {
          _leaving = false;
          _exitError = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = ref.watch(profileInitialProvider);
    if (!initial.hasValue) {
      if (!initial.hasError) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        body: Center(
          child: initial.hasError
              ? TextButton(
                  onPressed: () => ref.invalidate(profileInitialProvider),
                  child: const Text('账号资料读取失败，点击重试'),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }
    ref.listen(profileProvider, (previous, next) async {
      final account = next.value;
      if (account == null || account.isSignedIn || _leaving) return;
      await _leave(account.isDeleted);
    });
    if (_exitError != null) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => _leave(_deleteRequested),
            child: const Text('账号操作保存失败，点击重试'),
          ),
        ),
      );
    }
    if (_leaving) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Navigator(
      observers: [RouteObserverService()],
      onGenerateRoute: (settings) => settings.name == '/'
          ? MaterialPageRoute<void>(builder: (_) => const MainTabShell())
          : AppRouter.onGenerateRoute(settings),
    );
  }
}

/// 独立容器避免根作用域中曾读取的仓库被账号作用域复用。
class _AccountScope extends StatefulWidget {
  const _AccountScope({super.key, required this.store, required this.child});
  final MockJsonStore store;
  final Widget child;
  @override
  State<_AccountScope> createState() => _AccountScopeState();
}

class _AccountScopeState extends State<_AccountScope> {
  late final ProviderContainer container = ProviderContainer(
    overrides: [mockJsonStoreProvider.overrideWithValue(widget.store)],
  );
  @override
  void dispose() {
    RouteObserverService.pageStack.clear();
    container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      UncontrolledProviderScope(container: container, child: widget.child);
}
