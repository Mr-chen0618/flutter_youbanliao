import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../images/app_image.dart';

class CompanionBackdropWidget extends StatelessWidget {
  const CompanionBackdropWidget({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 242.h,
    child: ClipRect(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBBF), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -16.w,
              top: -39.h,
              child: Opacity(
                opacity: .25,
                child: AppImage(
                  src: 'assets/home/home_ambience_background.png',
                  width: 180.w,
                  height: 237.h,
                ),
              ),
            ),
            Positioned(
              left: -30.w,
              top: -79.h,
              child: Opacity(
                opacity: .25,
                child: Transform.rotate(
                  angle: .225,
                  child: Transform.flip(
                    flipX: true,
                    child: AppImage(
                      src: 'assets/home/home_ambience_background.png',
                      width: 183.w,
                      height: 239.h,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
