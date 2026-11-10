import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CompanionCardSurfaceWidget extends StatelessWidget {
  const CompanionCardSurfaceWidget({
    super.key,
    required this.child,
    this.padding,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: const Color(0xFFFEFEFE),
      border: Border.all(color: const Color(0xFFEEEEEE), width: 2.w),
      borderRadius: BorderRadius.circular(20.r),
    ),
    child: child,
  );
}
