import '../../../../shared/widgets/layout/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';

/// 编辑个性标签或分组兴趣。旧平铺兴趣继续显示并可移除。
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
  static const _interestGroups = {
    '旅游足迹': ['杭州', '厦门', '天津', '北京', '上海', '深圳', '成都', '重庆'],
    '运动': ['羽毛球', '篮球', '网球', '跑步', '游泳', '徒步', '骑行', '飞盘'],
    '音乐': ['流行音乐', '古典音乐', 'R&B', '民谣', '摇滚', '爵士'],
    '美食': ['火锅', '烧烤', '甜品', '咖啡', '日料', '探店'],
    '影视': ['剧情', '喜剧', '科幻', '纪录片', '动画', '悬疑'],
  };
  static const _personality = [
    '内向',
    '外向',
    '热情',
    '冷静',
    '乐观',
    '悲观',
    '创新者',
    '传统主义者',
    '细心',
    '粗心',
  ];
  late final _selected = widget.initial.toSet();
  String _active = _interestGroups.keys.first;
  bool get _isInterest => widget.title.contains('兴趣');
  String _label(String value) =>
      RegExp(r'^([^：]+)：(.+)$').firstMatch(value)?.group(2) ?? value;
  int _count(String group) =>
      _selected.where((value) => value.startsWith('$group：')).length;

  void _toggle(String value, {String? group}) {
    if (_selected.contains(value)) {
      setState(() => _selected.remove(value));
      return;
    }
    if (group != null && _count(group) >= 3) {
      AppToast.show('最多选择3个$group标签');
      return;
    }
    if (!_isInterest && _selected.length >= 10) {
      AppToast.show('最多选择10项');
      return;
    }
    setState(() => _selected.add(value));
  }

  Widget _chip(String value, {String? group}) => Padding(
    padding: EdgeInsets.only(right: 8.w, bottom: 8.h),
    child: FilterChip(
      label: Text(_label(value)),
      selected: _selected.contains(value),
      checkmarkColor: Colors.black,
      selectedColor: const Color(0xFFFFEDB6),
      backgroundColor: const Color(0xFFF6F6F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      onSelected: (_) => _toggle(value, group: group),
    ),
  );

  @override
  Widget build(BuildContext context) => CompanionPageSurface(
    title: widget.title,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              Center(
                child: Text(
                  _isInterest ? '请选择你的兴趣爱好' : '填写个性标签，更快找到兴趣相投的Ta',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(height: 12.h),
              CompanionCardSurfaceWidget(
                padding: EdgeInsets.all(16.w),
                child: _selected.isEmpty
                    ? AppEmptyState(
                        message: _isInterest ? '暂无兴趣' : '暂无标签',
                        compact: true,
                      )
                    : Wrap(
                        children: [for (final value in _selected) _chip(value)],
                      ),
              ),
              SizedBox(height: 16.h),
              if (_isInterest) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final group in _interestGroups.keys)
                        TextButton(
                          onPressed: () => setState(() => _active = group),
                          child: Text(
                            '$group (${_count(group)}/3)',
                            style: TextStyle(
                              color: group == _active
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  children: [
                    for (final value in _interestGroups[_active]!)
                      _chip('$_active：$value', group: _active),
                  ],
                ),
              ] else
                Wrap(
                  children: [
                    for (final value in {..._personality, ...widget.options})
                      _chip(value),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16.w),
          child: SizedBox(
            width: double.infinity,
            height: 52.h,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD152),
                foregroundColor: Colors.black,
              ),
              onPressed: () =>
                  Navigator.pop(context, List<String>.unmodifiable(_selected)),
              child: const Text('保存'),
            ),
          ),
        ),
      ],
    ),
  );
}
