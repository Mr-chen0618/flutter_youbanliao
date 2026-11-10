import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../images/app_image.dart';

enum DiscoverySection {
  following('关注'),
  discover('发现'),
  video('视频');

  const DiscoverySection(this.label);
  final String label;
}

class DiscoveryHeader extends StatelessWidget {
  const DiscoveryHeader({
    super.key,
    required this.section,
    required this.onSelected,
    this.isDark = false,
    this.action,
  });

  final DiscoverySection section;
  final ValueChanged<DiscoverySection> onSelected;
  final bool isDark;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48.h,
    child: Row(
      children: [
        SizedBox(width: 6.w),
        for (final item in DiscoverySection.values)
          Semantics(
            selected: item == section,
            child: InkWell(
              onTap: () => onSelected(item),
              child: SizedBox(
                width: 53.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: item == section ? 17.sp : 16.sp,
                        fontWeight: item == section
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isDark
                            ? (item == section ? Colors.white : Colors.white70)
                            : (item == section
                                  ? const Color(0xFF333333)
                                  : const Color(0xFF666666)),
                      ),
                    ),
                    if (item == section)
                      AppImage(
                        src: 'assets/square/square_active_indicator.png',
                        width: 23.w,
                        height: 8.h,
                        fit: BoxFit.contain,
                      )
                    else
                      SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
          ),
        if (action case final action?) ...[
          const Spacer(),
          action,
          SizedBox(width: 8.w),
        ],
      ],
    ),
  );
}
