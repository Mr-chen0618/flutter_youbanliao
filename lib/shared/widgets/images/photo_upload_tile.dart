import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_image.dart';

/// 相册复用的虚线上传入口，选择与导航由调用方负责。
class PhotoUploadTile extends StatelessWidget {
  const PhotoUploadTile({super.key, required this.onTap}) : _feedback = false;

  /// 客服佐证使用较细边框、较小圆角与加号。
  const PhotoUploadTile.feedback({super.key, required this.onTap})
    : _feedback = true;

  final bool _feedback;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _UploadBorder(
      (_feedback ? 12 : 16).r,
      (_feedback ? 1 : 2).w,
    ),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular((_feedback ? 12 : 16).r),
      child: InkWell(
        borderRadius: BorderRadius.circular((_feedback ? 12 : 16).r),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onTap == null)
                SizedBox(
                  width: (_feedback ? 20 : 24).r,
                  height: (_feedback ? 20 : 24).r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              else
                AppImage(
                  src: _feedback
                      ? 'assets/profile/profile_feedback_add.svg'
                      : 'assets/profile/profile_upload_add.svg',
                  width: (_feedback ? 20 : 24).r,
                  height: (_feedback ? 20 : 24).r,
                ),
              SizedBox(height: _feedback ? 0 : 8.h),
              Text(
                _feedback ? '添加图片' : '上传照片',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 12.sp,
                  fontWeight: _feedback ? FontWeight.w400 : FontWeight.w500,
                  height: _feedback ? 1.5 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _UploadBorder extends CustomPainter {
  const _UploadBorder(this.radius, this.stroke);
  final double radius, stroke;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(stroke / 2),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = const Color(0xFFF1F1F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    for (final metric in path.computeMetrics()) {
      for (double start = 0; start < metric.length; start += 8.w) {
        canvas.drawPath(
          metric.extractPath(start, math.min(start + 4.w, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _UploadBorder oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.stroke != stroke;
}
