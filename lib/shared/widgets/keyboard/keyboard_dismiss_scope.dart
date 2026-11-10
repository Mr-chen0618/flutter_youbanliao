import 'package:flutter/material.dart';

/// 显式处理移动端输入区域外点击，不参与手势竞技或拦截按钮事件。
class KeyboardDismissScope extends StatelessWidget {
  const KeyboardDismissScope({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Actions(
    actions: <Type, Action<Intent>>{
      EditableTextTapOutsideIntent:
          CallbackAction<EditableTextTapOutsideIntent>(
            onInvoke: (intent) {
              intent.focusNode.unfocus();
              return null;
            },
          ),
    },
    child: child,
  );
}
