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
                    child: Text('未找到城市'),
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

  /// 个性签名按独立画板展示输入与介绍提示，不混入昵称编辑内容。
  Widget _signaturePage() => CompanionPageSurface(
    title: widget.title,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              CompanionCardSurfaceWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '用一句话，介绍真实的你',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _text,
                      maxLength: 100,
                      minLines: 4,
                      maxLines: 5,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        hintText: '聊聊最近喜欢的事…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              CompanionCardSurfaceWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '让朋友更了解你',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    const Text(
                      '聊聊最近喜欢的事，或是期待一起完成的小计划。最多可填写 100 字。',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _footer(
          '保存',
          '真实的你，更容易遇见合拍的朋友',
          () => Navigator.pop(context, _text.text.trim()),
        ),
      ],
    ),
  );

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
  Widget build(BuildContext context) {
    final city = widget.title == '选择常驻城市';
    if (city) return _cityPage();
    if (widget.title.contains('签名')) return _signaturePage();
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
                    widget.title == '修改昵称' ? '想让朋友怎么称呼你？' : '介绍一下自己',
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
                            Text(widget.title == '修改昵称' ? '昵称' : '个性签名'),
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
              onPressed: () => Navigator.pop(
                context,
                widget.options.isEmpty ? _text.text.trim() : _selected,
              ),
              child: Text(city ? '完成' : '保存'),
            ),
          ),
          if (widget.title == '修改昵称')
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: const Text(
                '一个好记的昵称，让相遇从这里开始',
                style: TextStyle(fontSize: 11, color: Color(0xFF666666)),
              ),
            ),
        ],
      ),
    );
  }
}

/// 生日选择使用系统滚轮，并保留取消前的原始值。
class ProfileBirthdayPage extends StatefulWidget {
  const ProfileBirthdayPage({super.key, required this.initial});
  final DateTime initial;
  @override
  State<ProfileBirthdayPage> createState() => _ProfileBirthdayPageState();
}

class _ProfileBirthdayPageState extends State<ProfileBirthdayPage> {
  late DateTime _date = widget.initial;
  @override
  Widget build(BuildContext context) => CompanionPageSurface(
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
            maximumDate: DateTime.now(),
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
