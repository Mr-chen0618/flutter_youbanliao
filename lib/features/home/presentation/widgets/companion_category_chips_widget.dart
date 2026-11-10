import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/model/home_model.dart';
import '../constant/home_style_constant.dart';

class CompanionCategoryChipsWidget extends StatefulWidget {
  const CompanionCategoryChipsWidget({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.selectedChip,
    required this.onSelected,
  });

  final List<HomeCategoryModel> categories;
  final String selectedId;
  final GlobalKey selectedChip;
  final ValueChanged<String> onSelected;

  @override
  State<CompanionCategoryChipsWidget> createState() =>
      _CompanionCategoryChipsWidgetState();
}

class _CompanionCategoryChipsWidgetState
    extends State<CompanionCategoryChipsWidget> {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(horizontal: 12.w),
    child: Row(
      spacing: 5.w,
      children: [
        for (final category in widget.categories)
          Semantics(
            key: category.id == widget.selectedId ? widget.selectedChip : null,
            button: true,
            selected: category.id == widget.selectedId,
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
                side: category.id == widget.selectedId
                    ? const BorderSide(color: homeYellow)
                    : BorderSide.none,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8.r),
                onTap: () => widget.onSelected(category.id),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  child: Row(
                    spacing: 4.w,
                    children: [
                      homeCategoryIcon(category.id, 24),
                      homeText(category.label, 13),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
