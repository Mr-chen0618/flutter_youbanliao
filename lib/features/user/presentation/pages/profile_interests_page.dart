import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';

/// 编辑兴趣或标签，最多保存六项。
class ProfileInterestsPage extends StatefulWidget {
  const ProfileInterestsPage({
    super.key,
    required this.title,
    required this.initial,
    required this.options,
  });
  final String title;
  final List<String> initial, options;
  @override
  State<ProfileInterestsPage> createState() => _ProfileInterestsPageState();
}

class _ProfileInterestsPageState extends State<ProfileInterestsPage> {
  late final _selected = widget.initial.toSet();
  Widget _chip(String value) => Padding(
    padding: EdgeInsets.only(right: 8.w, bottom: 8.h),
    child: InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: () {
        if (!_selected.contains(value) && _selected.length >= 6) {
          AppToast.show('最多选择 6 项');
          return;
        }
        setState(() {
          if (!_selected.remove(value)) _selected.add(value);
        });
      },
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        alignment: Alignment.center,
        constraints: BoxConstraints(minWidth: 66.w),
        decoration: BoxDecoration(
          color: _selected.contains(value)
              ? const Color(0xFFFFF6CB)
              : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(8.r),
          border: _selected.contains(value)
              ? Border.all(color: const Color(0xFFFFD152))
              : null,
        ),
        child: Text(
          '$value${_selected.contains(value) ? ' ✓' : ''}',
          style: TextStyle(fontSize: 13.sp),
        ),
      ),
    ),
  );
  Map<String, List<String>> _groups() {
    final all = {...widget.initial, ...widget.options};
    final outdoor = all
        .where((s) => RegExp('运动|球|跑|徒步|登山|露营|骑行|健身|游泳|瑜伽|飞盘').hasMatch(s))
        .toList();
    final art = all
        .where(
          (s) =>
              RegExp('摄影|音乐|阅读|手作|绘画|电影|艺术|展|旅行').hasMatch(s) &&
              !outdoor.contains(s),
        )
        .toList();
    return {
      '户外与运动': outdoor,
      '城市与生活': all
          .where((s) => !outdoor.contains(s) && !art.contains(s))
          .toList(),
      '文艺与记录': art,
    };
  }

  @override
  Widget build(BuildContext context) => CompanionPageSurface(
    title: widget.title,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              CompanionCardSurfaceWidget(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '已选兴趣        ${_selected.length} / 6',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      children: _selected
                          .map((v) => IntrinsicWidth(child: _chip(v)))
                          .toList(),
                    ),
                    Text(
                      '最多选择 6 项，还可以再选 ${6 - _selected.length} 项',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              for (final group in _groups().entries) ...[
                Text(
                  group.key,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  children: group.value
                      .map((v) => IntrinsicWidth(child: _chip(v)))
                      .toList(),
                ),
                SizedBox(height: 20.h),
              ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16.w),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFD04F),
              foregroundColor: Colors.black,
              minimumSize: Size.fromHeight(52.h),
            ),
            onPressed: () => Navigator.pop(context, _selected.toList()),
            child: const Text('保存'),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Text(
            '让友伴为你推荐更合拍的组队',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey),
          ),
        ),
      ],
    ),
  );
}
