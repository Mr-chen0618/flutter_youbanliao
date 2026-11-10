import '../../../../core/media/app_media_picker.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';
import '../../data/activity_publication_repository.dart';

/// 创建搭子和发起邀约共用的活动表单。
class ActivityFormWidget extends StatefulWidget {
  const ActivityFormWidget({
    super.key,
    required this.onSubmit,
    this.isInvitation = false,
  });

  final Future<void> Function(ActivityDraft) onSubmit;
  final bool isInvitation;

  @override
  State<ActivityFormWidget> createState() => _ActivityFormWidgetState();
}

class _ActivityFormWidgetState extends State<ActivityFormWidget> {
  static const _assets = 'assets/profile/profile_activity_form_';
  static const _categories = {
    '羽毛球': 'sports',
    '网球': 'sports',
    '户外': 'outdoors',
    '探店': 'shops',
    '美食': 'food',
    '研学': 'study',
    '桌游': 'games',
    '旅游': 'travel',
    '摄影': 'photo',
  };
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _address = '';
  final _photos = <String>[];
  String _category = '羽毛球';
  String _gender = '不限';
  DateTime? _time;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  /// 保存活动，成功后由入口刷新对应列表。
  Future<void> _submit() async {
    if (_saving) return;
    if (_title.text.trim().isEmpty) {
      AppToast.show('请填写活动标题');
      return;
    }
    final time = _time;
    if (time == null ||
        time.isBefore(DateTime.now()) ||
        _address.trim().isEmpty) {
      AppToast.show('请填写未来的活动时间和活动地址');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
    });
    try {
      await widget.onSubmit(
        ActivityDraft(
          title: _title.text.trim(),
          description: _description.text.trim(),
          categoryId: _categories[_category]!,
          category: _category,
          eventTime: time,
          location: _address.trim(),
          gender: _gender,
          photos: List.unmodifiable(_photos),
        ),
      );
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        AppToast.show('提交失败，请重试');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: _time ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 2, 12, 31),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _time ?? DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    if (!mounted || time == null) return;
    setState(
      () => _time = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<String?> _pick(String title, Iterable<String> options) =>
      showModalBottomSheet<String>(
        context: context,
        builder: (sheet) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: Text(title)),
              for (final option in options)
                ListTile(
                  title: Text(option),
                  onTap: () => Navigator.pop(sheet, option),
                ),
            ],
          ),
        ),
      );

  Future<void> _pickAddress() async {
    var draft = _address;
    final address = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('活动地址'),
        content: TextFormField(
          initialValue: draft,
          autofocus: true,
          maxLength: 100,
          onChanged: (value) => draft = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, draft.trim()),
            child: const Text('完成'),
          ),
        ],
      ),
    );
    if (mounted && address != null) setState(() => _address = address);
  }

  Future<void> _pickPhoto() async {
    final photo = await AppMediaPicker.pickImage();
    if (mounted && photo != null) setState(() => _photos.add(photo));
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            children: [
              // 标题、描述和发布图片
              CompanionCardSurfaceWidget(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _title,
                      maxLength: 40,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _input('请设置活动标题'),
                    ),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    TextFormField(
                      controller: _description,
                      minLines: widget.isInvitation ? 2 : 5,
                      maxLines: widget.isInvitation ? 3 : 6,
                      maxLength: 200,
                      decoration: _input('请输入简短的活动描述！'),
                    ),
                    if (!widget.isInvitation) ...[
                      SizedBox(height: 10.h),
                      LayoutBuilder(
                        builder: (context, constraints) =>
                            _photoRow((constraints.maxWidth - 16.w) / 3),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              // 活动条件
              CompanionCardSurfaceWidget(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Column(
                  children: [
                    _row('category', '选择活动', _category, () async {
                      final value = await _pick('选择活动', _categories.keys);
                      if (mounted && value != null) {
                        setState(() => _category = value);
                      }
                    }),
                    _divider,
                    _row(
                      'time',
                      '活动时间',
                      _time == null ? '请选择' : _formatTime(context, _time!),
                      _pickTime,
                    ),
                    _divider,
                    _row(
                      'location',
                      '活动地址',
                      _address.isEmpty ? '请填写' : _address,
                      _pickAddress,
                    ),
                    if (!widget.isInvitation) ...[
                      _divider,
                      _row('gender', '性别限制', _gender, () async {
                        final value = await _pick('性别限制', ['不限', '仅女生', '仅男生']);
                        if (mounted && value != null) {
                          setState(() => _gender = value);
                        }
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // 底部提交操作
      Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFCD44),
            foregroundColor: const Color(0xFF171717),
            minimumSize: Size.fromHeight(52.h),
          ),
          onPressed: _saving ? null : _submit,
          child: Text(
            _saving
                ? '提交中…'
                : widget.isInvitation
                ? '发出邀约'
                : '发布',
          ),
        ),
      ),
    ],
  );

  /// 显示已选择的图片和添加位置。
  Widget _photoRow(double width) => Row(
    children: [
      for (final photo in _photos)
        Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: InkWell(
            onTap: () => setState(() => _photos.remove(photo)),
            child: AppImage(
              src: photo,
              width: width,
              height: 118.h,
              radius: 16.r,
            ),
          ),
        ),
      if (_photos.length < 2)
        InkWell(
          onTap: _pickPhoto,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            width: width,
            height: 118.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 32, color: Color(0xFFBBBBBB)),
                Text('选择照片', style: TextStyle(color: Color(0xFF999999))),
              ],
            ),
          ),
        ),
    ],
  );

  String _formatTime(BuildContext context, DateTime time) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatCompactDate(time);
    final hour = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(time),
      alwaysUse24HourFormat: true,
    );
    return '$date $hour';
  }

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFBFBFBF)),
    counterText: '',
    filled: false,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
  );

  static const _divider = Divider(height: 1, color: Color(0xFFF4F4F4));

  /// 可点击的活动条件行。
  Widget _row(String icon, String label, String value, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52.h,
          child: Row(
            children: [
              SvgPicture.asset('$_assets$icon.svg', width: 20.r, height: 20.r),
              SizedBox(width: 8.w),
              Text(label),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF999999)),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: const Color(0xFF999999),
                size: 20.r,
              ),
            ],
          ),
        ),
      );
}
