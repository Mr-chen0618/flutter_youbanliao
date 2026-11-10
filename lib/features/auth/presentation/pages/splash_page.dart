import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../shared/widgets/images/app_image.dart';

/// 启动品牌页，对应3262:33636；同一页面承接会话及账号数据恢复。
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width / 375;
        final height = constraints.maxHeight;
        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 454 * scale,
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 812 * scale,
                      child: const AppImage(
                        src: 'assets/auth/auth_splash_atmosphere_image.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              // 保持白色RGB，避免透明黑与白色插值形成灰色横带。
                              Color(0x00FFFFFF),
                              Colors.white,
                              Colors.white,
                            ],
                            stops: [.44824, .69653, 1],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 111 * scale,
              top: 209 * scale,
              width: 141 * scale,
              height: 141 * scale,
              // SVG的高斯模糊滤镜不受矢量渲染器支持，使用原生模糊保留柔光。
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: 5 * scale,
                  sigmaY: 5 * scale,
                ),
                child: Padding(
                  padding: EdgeInsets.all(10 * scale),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 145 * scale,
              top: 194 * scale,
              child: Semantics(
                label: '喜欢的事',
                image: true,
                child: AppImage(
                  src: 'assets/auth/auth_splash_slogan_right_image.png',
                  width: 34 * scale,
                  height: 162 * scale,
                ),
              ),
            ),
            Positioned(
              left: 193 * scale,
              top: 219 * scale,
              child: Semantics(
                label: '有伴一起',
                image: true,
                child: AppImage(
                  src: 'assets/auth/auth_splash_slogan_left_image.png',
                  width: 34 * scale,
                  height: 162 * scale,
                ),
              ),
            ),
            Positioned(
              left: 214 * scale,
              top: 377 * scale,
              child: Opacity(
                opacity: .5,
                child: AppImage(
                  src: 'assets/auth/auth_splash_quote_image.png',
                  width: 44 * scale,
                  height: 28.8 * scale,
                ),
              ),
            ),
            Positioned(
              left: 117 * scale,
              top: 175 * scale,
              child: Transform.rotate(
                angle: math.pi,
                child: Opacity(
                  opacity: .5,
                  child: AppImage(
                    src: 'assets/auth/auth_splash_quote_image.png',
                    width: 44 * scale,
                    height: 28.8 * scale,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: math.max(450 * scale, height - 107 * scale),
              child: Center(
                child: Semantics(
                  label: '友伴聊',
                  image: true,
                  child: AppImage(
                    src: 'assets/auth/auth_splash_brand_image.png',
                    width: 118 * scale,
                    height: 38 * scale,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
