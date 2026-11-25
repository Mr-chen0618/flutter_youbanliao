import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'feed_tab_label.dart';

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
                child: Center(
                  child: FeedTabLabel(
                    label: item.label,
                    selected: item == section,
                    isDark: isDark,
                  ),
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
