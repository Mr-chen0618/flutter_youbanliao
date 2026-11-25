import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/gestures/app_tap_area.dart';
import '../../../../shared/widgets/layout/feed_tab_label.dart';
import '../enum/home_feed_kind_enum.dart';

class HomeFeedSwitchWidget extends StatefulWidget {
  const HomeFeedSwitchWidget({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final HomeFeedKindEnum selected;
  final ValueChanged<HomeFeedKindEnum> onChanged;

  @override
  State<HomeFeedSwitchWidget> createState() => _HomeFeedSwitchWidgetState();
}

class _HomeFeedSwitchWidgetState extends State<HomeFeedSwitchWidget> {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48.h,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          for (final kind in const [
            HomeFeedKindEnum.companions,
            HomeFeedKindEnum.activities,
          ]) ...[
            Semantics(
              selected: widget.selected == kind,
              button: true,
              child: AppTapArea(
                onTap: () => widget.onChanged(kind),
                child: FeedTabLabel(
                  label: kind == HomeFeedKindEnum.activities ? '活动' : '友伴',
                  selected: widget.selected == kind,
                ),
              ),
            ),
            SizedBox(width: widget.selected == kind ? 20.w : 14.w),
          ],
        ],
      ),
    ),
  );
}
