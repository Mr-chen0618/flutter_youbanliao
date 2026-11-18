import 'package:flutter/material.dart';

import '../../../../shared/widgets/images/app_image.dart';

/// 登录氛围背景在底部自然渐隐至页面白底。
class LoginBackdrop extends StatelessWidget {
  const LoginBackdrop({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: const Stack(
          fit: StackFit.expand,
          children: [
            AppImage(
              src: 'assets/auth/auth_login_backdrop.svg',
              fit: BoxFit.fill,
            ),
            // 同一白色仅改变透明度，避免透明黑参与插值产生灰色过渡。
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00FFFFFF),
                    Color(0x00FFFFFF),
                    Color(0xFFFFFFFF),
                  ],
                  stops: [0, .35, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
