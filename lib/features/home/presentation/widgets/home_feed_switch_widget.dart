import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/gestures/app_tap_area.dart';
import '../constant/home_assets_constant.dart';
import '../constant/home_style_constant.dart';
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
          for (final kind in HomeFeedKindEnum.values) ...[
            Semantics(
              selected: widget.selected == kind,
              button: true,
              child: AppTapArea(
                onTap: () => widget.onChanged(kind),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    homeText(
                      kind == HomeFeedKindEnum.activities ? '活动' : '友伴',
                      widget.selected == kind ? 17 : 15,
                      color: widget.selected == kind ? homeInk : homeMuted,
                      weight: widget.selected == kind
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    if (widget.selected == kind)
                      Positioned(
                        right: -10.w,
                        top: 0,
                        child: homeAsset(HomeAssets.feedSelectedIcon, 19),
                      ),
                  ],
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
