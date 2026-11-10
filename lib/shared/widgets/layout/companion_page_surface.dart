import 'package:flutter/material.dart';

import 'app_scaffold.dart';
import 'companion_backdrop_widget.dart';

/// The same ambient background used by the home, feed, inbox and profile.
class CompanionPageSurface extends StatelessWidget {
  const CompanionPageSurface({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.backButton,
    this.titleStyle,
  });
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? backButton;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      fit: StackFit.expand,
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CompanionBackdropWidget(),
        ),
        SafeArea(bottom: title != null, child: child),
      ],
    );
    if (title == null) return content;
    return AppScaffold(
      navigatorTitle: title,
      navigatorBackWidget: backButton ?? const BackButton(),
      navigatorTiTleStyle: titleStyle,
      navigatorActionWidget: actions,
      isExtendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: content,
    );
  }
}
