import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/storage/mock_json_store.dart';
import '../../features/messages/presentation/providers/messages_provider.dart';
import '../../features/square/presentation/providers/square_provider.dart';
import '../../features/user/presentation/providers/profile_provider.dart';
import '../../features/home/presentation/constant/home_assets_constant.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/messages/presentation/pages/messages_page.dart';
import '../../features/user/presentation/pages/profile_page.dart';
import '../../features/square/presentation/pages/square_page.dart';
import '../../shared/widgets/images/app_image.dart';
import '../../shared/widgets/text/app_text.dart';

class MainTabShell extends ConsumerStatefulWidget {
  const MainTabShell({super.key});

  @override
  ConsumerState<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends ConsumerState<MainTabShell> {
  static const _labels = ['首页', '广场', '消息', '我的'];
  static const _idle = [
    HomeAssets.tabUnselectedIcon,
    HomeAssets.tabSquareUnselectedIcon,
    HomeAssets.tabMessagesUnselectedIcon,
    HomeAssets.tabProfileUnselectedIcon,
  ];
  static const _active = [
    HomeAssets.tabSelectedIcon,
    HomeAssets.tabSquareSelectedIcon,
    HomeAssets.tabMessagesSelectedIcon,
    HomeAssets.tabProfileSelectedIcon,
  ];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final loaded = [
      ref.watch(messagesInitialProvider),
      ref.watch(squareInitialProvider),
      ref.watch(profileInitialProvider),
    ];
    if (loaded.any((value) => value.hasError)) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () {
              ref.invalidate(messagesInitialProvider);
              ref.invalidate(squareInitialProvider);
              ref.invalidate(profileInitialProvider);
            },
            child: const Text('本地数据读取失败，点击重试'),
          ),
        ),
      );
    }
    if (loaded.any((value) => !value.hasValue)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final writeErrors = ref.watch(mockWritesProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            if (writeErrors.isNotEmpty)
              SafeArea(
                bottom: false,
                child: TextButton(
                  onPressed: ref.read(mockWritesProvider.notifier).retry,
                  child: const Text('有修改尚未保存，点击重试'),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _selected,
                children: const [
                  HomePage(),
                  SquarePage(),
                  MessagesPage(),
                  ProfilePage(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Material(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 28.r + 4.h + 12.sp + 14.h,
              child: Row(
                children: [
                  for (final (index, label) in _labels.indexed)
                    Expanded(
                      child: Semantics(
                        selected: index == _selected,
                        button: true,
                        child: InkWell(
                          key: ValueKey('main-tab-$index'),
                          onTap: () => setState(() => _selected = index),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppImage(
                                src: (index == _selected
                                    ? _active
                                    : _idle)[index],
                                width: 28.r,
                                height: 28.r,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: 4.h),
                              AppText(
                                label,
                                fontSize: 10.sp,
                                color: index == _selected
                                    ? const Color(0xFF333333)
                                    : const Color(0xFFCCCCCC),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
