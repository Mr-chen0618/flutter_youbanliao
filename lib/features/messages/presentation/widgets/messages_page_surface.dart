import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';

/// 新版聊天共用背景和导航容器。
class MessagesPageSurface extends StatelessWidget {
  const MessagesPageSurface({
    super.key,
    required this.child,
    required this.title,
    this.actions,
    this.backButton,
    this.titleStyle,
  });

  final Widget child;
  final String title;
  final List<Widget>? actions;
  final Widget? backButton;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) => AppScaffold(
    navigatorTitle: title,
    navigatorBackWidget: backButton,
    navigatorTiTleStyle: titleStyle,
    navigatorActionWidget: actions,
    isExtendBodyBehindAppBar: true,
    backgroundColor: Colors.white,
    body: Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppImage(
            src: 'assets/messages/messages_v2_backdrop.svg',
            height: 255.h,
            fit: BoxFit.fill,
          ),
        ),
        SafeArea(child: child),
      ],
    ),
  );
}
