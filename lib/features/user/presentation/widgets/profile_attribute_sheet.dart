import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 新版基础资料滚轮，保存前不会改变资料。
Future<String?> showProfileAttributeSheet(
  BuildContext context, {
  required String label,
  required String icon,
  required String initial,
  required Map<String, List<String>> options,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
  ),
  builder: (_) => _ProfileAttributeSheet(
    label: label,
    icon: icon,
    initial: initial,
    options: options,
  ),
);

class _ProfileAttributeSheet extends StatefulWidget {
  const _ProfileAttributeSheet({
    required this.label,
    required this.icon,
    required this.initial,
    required this.options,
  });
  final String label, icon, initial;
  final Map<String, List<String>> options;
  @override
  State<_ProfileAttributeSheet> createState() => _ProfileAttributeSheetState();
}

class _ProfileAttributeSheetState extends State<_ProfileAttributeSheet> {
  late int _group, _item;
  late final FixedExtentScrollController _groupController;
  late final FixedExtentScrollController _itemController;
  List<String> get _groups => widget.options.keys.toList();
  List<String> get _items => widget.options[_groups[_group]]!;
  bool get _hasGroups => _groups.length > 1;

  @override
  void initState() {
    super.initState();
    _group = _groups.indexWhere(
      (entry) => widget.initial.startsWith('$entry '),
    );
    if (_group < 0) _group = 0;
    _item = _items.indexOf(widget.initial.split(' ').last);
    if (_item < 0) _item = _items.length > 100 ? 50 : 0;
    _groupController = FixedExtentScrollController(initialItem: _group);
    _itemController = FixedExtentScrollController(initialItem: _item);
  }

  @override
  void dispose() {
    _groupController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  Widget _wheel(
    List<String> values,
    FixedExtentScrollController controller,
    ValueChanged<int> select,
  ) => CupertinoPicker(
    itemExtent: 44.h,
    scrollController: controller,
    onSelectedItemChanged: select,
    children: [
      for (final value in values)
        Center(
          child: Text(value, style: TextStyle(fontSize: 17.sp)),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '设置你的${widget.label}${widget.icon}',
                  style: TextStyle(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            '填写${widget.label}，让对方更了解你～',
            style: const TextStyle(color: Colors.grey),
          ),
          SizedBox(
            height: 224.h,
            child: Row(
              children: [
                if (_hasGroups)
                  Expanded(
                    child: _wheel(_groups, _groupController, (index) {
                      if (index == _group) return;
                      setState(() {
                        _group = index;
                        _item = 0;
                      });
                      if (_itemController.hasClients) {
                        _itemController.jumpToItem(0);
                      }
                    }),
                  ),
                Expanded(
                  child: _wheel(
                    _items,
                    _itemController,
                    (index) => _item = index,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD152),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(
                context,
                _hasGroups
                    ? '${_groups[_group]} ${_items[_item.clamp(0, _items.length - 1)]}'
                    : _items[_item],
              ),
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    ),
  );
}
