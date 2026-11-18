import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../../../shared/widgets/layout/app_empty_state.dart';
import '../../../../core/utils/input_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';

/// 资料字段编辑页，保存后向资料页返回用户确认的值。
class ProfileFieldPage extends StatefulWidget {
  const ProfileFieldPage({
    super.key,
    required this.title,
    required this.initial,
    this.options = const [],
    this.limit = 20,
  });
  final String title, initial;
  final List<String> options;
  final int limit;

  @override
  State<ProfileFieldPage> createState() => _ProfileFieldPageState();
}

class _ProfileFieldPageState extends State<ProfileFieldPage> {
  late final _text = TextEditingController(text: widget.initial);
  late String _selected = widget.initial;
  String _query = '';
  bool _discarding = false;
  bool _allowExit = false;

  bool get _isEditableText =>
      widget.title == '修改昵称' || widget.title.contains('签名');
  Future<void> _discard() async {
    if (_discarding) return;
    _discarding = true;
    final label = widget.title.contains('签名') ? '个性签名' : '昵称';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text('$label未保存，确定放弃本次编辑吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    _discarding = false;
    if (confirmed == true && mounted) {
      setState(() => _allowExit = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  void _save() {
    final value = widget.options.isEmpty ? _text.text.trim() : _selected;
    if (_isEditableText && value.isEmpty) {
      AppToast.show(widget.title.contains('签名') ? '请输入个性签名' : '请输入昵称');
      return;
    }
    if (_isEditableText && value == widget.initial.trim()) {
      AppToast.show('内容未修改');
      return;
    }
    if (widget.title == '修改昵称' && !InputValidator.validateNickname(value)) {
      AppToast.show('请输入有效昵称');
      return;
    }
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, value);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// 城市页保留原始选项，并支持常用城市拼音检索。
  Widget _cityPage() {
    const roman = {
      '杭州': 'hangzhou',
      '上海': 'shanghai',
      '北京': 'beijing',
      '广州': 'guangzhou',
      '深圳': 'shenzhen',
      '成都': 'chengdu',
      '南京': 'nanjing',
      '苏州': 'suzhou',
      '武汉': 'wuhan',
      '重庆': 'chongqing',
      '西安': 'xian',
      '厦门': 'xiamen',
    };
    final values = {...widget.options, ...roman.keys}
        .where(
          (value) =>
              value.contains(_query) ||
              roman.entries.any(
                (e) =>
                    value.contains(e.key) &&
                    e.value.contains(_query.toLowerCase()),
              ),
        )
        .toList();
    return CompanionPageSurface(
      title: widget.title,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: '输入城市名称或拼音',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
                SizedBox(height: 16.h),
                CompanionCardSurfaceWidget(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '当前常驻城市',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _selected,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.my_location),
                        title: const Text('定位当前城市'),
                        trailing: TextButton(
                          onPressed: () => AppToast.show('当前未接入定位服务，请手动选择城市'),
                          child: const Text('重新定位'),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  '常用城市',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    for (final value in values)
                      ChoiceChip(
                        label: Text(value),
                        selected: _selected == value,
                        selectedColor: const Color(0xFFFFF6CB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        onSelected: (_) => setState(() => _selected = value),
                      ),
                  ],
                ),
                if (values.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: AppEmptyState(message: '未找到城市', compact: true),
                  ),
                SizedBox(height: 16.h),
                const Text(
                  '选择常驻城市，更容易发现附近合拍的朋友。',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          _footer(
            '完成',
            '仅展示城市，不公开你的具体位置',
            () => Navigator.pop(context, _selected),
          ),
        ],
      ),
    );
  }

  /// 昵称与签名共用新版导航保存和单一大输入卡片。
  Widget _textPage() {
    final signature = widget.title.contains('签名');
    final limit = signature ? 100 : widget.limit;
    return AppScaffold(
      navigatorTitle: signature ? '个性签名' : '昵称',
      navigatorBackWidget: const BackButton(),
      navigatorColor: const Color(0xFFF8F8F8),
      backgroundColor: const Color(0xFFF8F8F8),
      navigatorActionWidget: [
        Padding(
          padding: EdgeInsets.only(right: 16.w, top: 8.h, bottom: 8.h),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFD152),
              foregroundColor: const Color(0xFF180E04),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              minimumSize: Size(52.w, 32.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text('保存', style: TextStyle(fontSize: 14.sp)),
          ),
        ),
      ],
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        children: [
          Container(
            height: 190.h,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: TextField(
              controller: _text,
              maxLength: limit,
              minLines: null,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(fontSize: 15.sp, color: const Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: signature ? '请填写个性签名' : '请填写昵称',
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_text.text.characters.length}/$limit',
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(String label, String tip, VoidCallback save) => Padding(
    padding: EdgeInsets.all(16.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52.h,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFD152),
              foregroundColor: const Color(0xFF333333),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            onPressed: save,
            child: Text(label),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          tip,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF666666)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _text,
        builder: (context, value, _) => PopScope(
          canPop:
              _allowExit || !_isEditableText || value.text == widget.initial,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _isEditableText) _discard();
          },
          child: _buildPage(context),
        ),
      );

  Widget _buildPage(BuildContext context) {
    final city = widget.title == '选择常驻城市';
    if (city) return _cityPage();
    if (_isEditableText) return _textPage();
    final gender = widget.title == '选择性别';
    final options = widget.options
        .where((value) => value.contains(_query))
        .toList();
    return CompanionPageSurface(
      title: widget.title,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                if (city) ...[
                  const Text('搜索城市'),
                  SizedBox(height: 10.h),
                  TextField(
                    decoration: const InputDecoration(hintText: '输入城市名称'),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  SizedBox(height: 20.h),
                ],
                if (!city && !gender) ...[
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
                if (gender) ...[
                  Text('当前性别：${widget.initial}'),
                  SizedBox(height: 20.h),
                ],
                CompanionCardSurfaceWidget(
                  padding: EdgeInsets.all(16.w),
                  child: widget.options.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title),
                            SizedBox(height: 10.h),
                            TextField(
                              controller: _text,
                              maxLength: widget.limit,
                              maxLines: widget.limit > 40 ? 5 : 1,
                            ),
                            Text(
                              '当前昵称：${widget.initial}',
                              style: const TextStyle(color: Color(0xFF999999)),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            for (final value in options)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(value),
                                trailing: Icon(
                                  _selected == value
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: _selected == value
                                      ? const Color(0xFFFFCE43)
                                      : Colors.grey,
                                ),
                                onTap: () => setState(() => _selected = value),
                              ),
                          ],
                        ),
                ),
                SizedBox(height: 20.h),
                Text(
                  city
                      ? '选择常驻城市，更容易发现附近合拍的朋友。'
                      : gender
                      ? '选择你希望在个人资料中展示的性别。'
                      : '昵称会展示在你的主页、动态和组队中。请勿使用冒充他人、广告或不友善的内容。',
                  style: const TextStyle(color: Color(0xFF777777)),
                ),
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
              onPressed: _save,
              child: Text(city ? '完成' : '保存'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 生日选择使用系统滚轮，并保留取消前的原始值。
class ProfileBirthdayPage extends StatefulWidget {
  const ProfileBirthdayPage({
    super.key,
    required this.initial,
    this.asSheet = false,
    this.maximumDate,
  });
  final DateTime initial;
  final bool asSheet;
  final DateTime? maximumDate;
  @override
  State<ProfileBirthdayPage> createState() => _ProfileBirthdayPageState();
}

class _ProfileBirthdayPageState extends State<ProfileBirthdayPage> {
  late DateTime _date = widget.initial;
  @override
  Widget build(BuildContext context) {
    if (widget.asSheet) {
      return SafeArea(
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
                      '设置你的出生日期🎂',
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
              const Text('填写生日，让对方更了解你～', style: TextStyle(color: Colors.grey)),
              SizedBox(
                height: 224.h,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _date,
                  maximumDate: widget.maximumDate ?? DateTime.now(),
                  minimumYear: 1900,
                  onDateTimeChanged: (value) => _date = value,
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _date),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD152),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return CompanionPageSurface(
      title: '选择生日',
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: CompanionCardSurfaceWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('当前生日'),
                  Text(
                    '${_date.year}–${_date.month.toString().padLeft(2, '0')}–${_date.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('选择你的出生日期'),
            ),
          ),
          SizedBox(
            height: 220.h,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _date,
              maximumDate: widget.maximumDate ?? DateTime.now(),
              minimumYear: 1900,
              onDateTimeChanged: (value) => setState(() => _date = value),
            ),
          ),
          const Text('上下滑动选择年、月、日', style: TextStyle(color: Colors.grey)),
          const Spacer(),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD04F),
                foregroundColor: Colors.black,
                minimumSize: Size.fromHeight(52.h),
              ),
              onPressed: () => Navigator.pop(context, _date),
              child: const Text('完成'),
            ),
          ),
        ],
      ),
    );
  }
}
