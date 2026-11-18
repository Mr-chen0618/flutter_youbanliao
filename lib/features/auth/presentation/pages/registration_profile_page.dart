import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/input_validator.dart';
import '../widgets/registration_profile_sheets.dart';
import '../../../user/presentation/widgets/profile_avatar_guide.dart';
import '../../../user/presentation/pages/profile_field_page.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../user/data/model/member_profile.dart';
import '../../data/model/auth_session.dart';
import '../../data/repository/auth_repository.dart';

/// 新号资料引导，只有全部必填资料落盘后才允许进入主页面。
class RegistrationProfilePage extends StatefulWidget {
  const RegistrationProfilePage({
    super.key,
    required this.session,
    required this.auth,
    required this.onChanged,
  });
  final AuthSession session;
  final AuthRepository auth;
  final VoidCallback onChanged;
  @override
  State<RegistrationProfilePage> createState() =>
      _RegistrationProfilePageState();
}

class _RegistrationProfilePageState extends State<RegistrationProfilePage> {
  final _name = TextEditingController();
  String _avatar = '', _gender = '男';
  DateTime? _birthday;
  bool _saving = false, _picking = false, _sheetOpen = false;
  final _random = Random.secure();
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// 返回时先按设计提示继续完善，关闭弹窗保留当前填写。
  Future<void> _back() async {
    if (_saving || _sheetOpen) return;
    _sheetOpen = true;
    try {
      await showRegistrationNotice(context, '只差一步就注册成功了！退出也太可惜了');
    } finally {
      _sheetOpen = false;
    }
  }

  /// 先展示对应性别的头像规则，再调用共享系统选图能力。
  Future<void> _avatarPicker() async {
    if (_saving || _picking || _sheetOpen) return;
    _picking = true;
    try {
      final selected = await showProfileAvatarGuide(
        context,
        female: _gender == '女',
      );
      if (mounted && selected != null) setState(() => _avatar = selected);
    } finally {
      _picking = false;
    }
  }

  Future<void> _genderChanged(String value) async {
    if (_saving || _sheetOpen || _gender == value) return;
    setState(() => _gender = value);
    _sheetOpen = true;
    try {
      await showRegistrationNotice(context, '注册成功后，性别将无法更换，请谨慎选择');
    } finally {
      _sheetOpen = false;
    }
  }

  Future<void> _nickname() async {
    if (_saving || _sheetOpen) return;
    _sheetOpen = true;
    try {
      final value = await showRegistrationNickname(
        context,
        initial: _name.text,
      );
      if (mounted && value != null) setState(() => _name.text = value);
    } finally {
      _sheetOpen = false;
    }
  }

  Future<void> _date() async {
    if (_saving || _sheetOpen) return;
    _sheetOpen = true;
    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    try {
      final date = await showModalBottomSheet<DateTime>(
        context: context,
        isScrollControlled: true,
        barrierColor: Colors.black.withValues(alpha: .7),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        builder: (_) => ProfileBirthdayPage(
          initial: _birthday ?? DateTime(2000, 1, 1),
          maximumDate: yesterday,
          asSheet: true,
        ),
      );
      if (mounted && date != null) setState(() => _birthday = date);
    } finally {
      _sheetOpen = false;
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (_avatar.isEmpty) {
      AppToast.show('请上传头像');
      return;
    }
    if (_name.text.trim().isEmpty) {
      AppToast.show('请设置昵称');
      return;
    }
    if (!InputValidator.validateNickname(_name.text.trim()) ||
        _name.text.characters.length > 7) {
      AppToast.show('请输入7字以内的有效昵称');
      return;
    }
    if (_birthday == null) {
      AppToast.show('请设置出生日期');
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      await widget.auth.completeProfile(
        widget.session.accountId,
        MemberProfile(
          id: widget.session.accountId,
          name: _name.text.trim(),
          avatar: _avatar,
          gender: _gender,
          birthday: _birthday,
          signature: '',
          city: '',
          interests: const [],
          tags: const [],
          following: 0,
          followers: 0,
          friends: 0,
        ),
      );
      if (mounted) widget.onChanged();
    } catch (error) {
      if (mounted) AppToast.showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _asset(
              'backdrop_lower.svg',
              height: 334.h,
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _asset(
              'backdrop_upper.svg',
              height: 334.h,
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 顶部标题与头像。
                        SizedBox(
                          height: 40.h,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: '返回',
                              onPressed: _saving ? null : _back,
                              icon: const Icon(Icons.chevron_left),
                            ),
                          ),
                        ),
                        Text(
                          '完善资料',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '花30秒完善资料，你会更受欢迎哦～',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: const Color(0xFF999999),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Center(
                          child: Semantics(
                            button: true,
                            label: '更换头像',
                            child: InkWell(
                              key: const ValueKey('registration-avatar'),
                              onTap: _saving ? null : _avatarPicker,
                              child: SizedBox(
                                width: 108.r,
                                height: 108.r,
                                child: Stack(
                                  children: [
                                    AppImage(
                                      src: _avatar.isEmpty
                                          ? 'assets/auth/auth_registration_avatar.png'
                                          : _avatar,
                                      width: 108.r,
                                      height: 108.r,
                                      radius: 54.r,
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: _asset(
                                        'camera.svg',
                                        width: 36.r,
                                        height: 36.r,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        // 白色资料表单与底部进入操作。
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 8.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24.r),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label('你的性别 (注册后不可修改)'),
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _genderButton(
                                        '男',
                                        '我是男生',
                                        const Color(0xFF21B1FF),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: _genderButton(
                                        '女',
                                        '我是女生',
                                        const Color(0xFFEF43FF),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                _label('设置昵称'),
                                SizedBox(height: 8.h),
                                _box(
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          key: const ValueKey(
                                            'registration-name',
                                          ),
                                          onTap: _saving ? null : _nickname,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12.h,
                                            ),
                                            child: Text(
                                              _name.text.isEmpty
                                                  ? '请设置一个昵称'
                                                  : _name.text,
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                color: _name.text.isEmpty
                                                    ? const Color(0xFFD4D9DD)
                                                    : const Color(0xFF333333),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _saving
                                            ? null
                                            : () => setState(
                                                () => _name.text =
                                                    '友伴${_random.nextInt(9000) + 1000}',
                                              ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF333333,
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _asset(
                                              'random.svg',
                                              width: 20.r,
                                              height: 20.r,
                                            ),
                                            SizedBox(width: 4.w),
                                            const Text('随机一个'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                _label('选择生日'),
                                SizedBox(height: 8.h),
                                InkWell(
                                  key: const ValueKey('registration-birthday'),
                                  onTap: _saving ? null : _date,
                                  child: _box(
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _birthday == null
                                                ? '请选择你的生日'
                                                : '${_birthday!.year}–${_birthday!.month.toString().padLeft(2, '0')}–${_birthday!.day.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              color: _birthday == null
                                                  ? const Color(0xFFD4D9DD)
                                                  : const Color(0xFF333333),
                                            ),
                                          ),
                                        ),
                                        RotatedBox(
                                          quarterTurns: 2,
                                          child: _asset(
                                            'arrow.svg',
                                            width: 16.r,
                                            height: 16.r,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 60.h),
                                const Spacer(),
                                Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      '🎉进入友伴聊，感受无限快乐',
                                      style: TextStyle(
                                        color: const Color(0xFFFFD152),
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: _asset(
                                    'tip_arrow.svg',
                                    width: 10.w,
                                    height: 6.h,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                SizedBox(
                                  height: 52.h,
                                  child: FilledButton(
                                    key: const ValueKey('registration-submit'),
                                    onPressed: _saving ? null : _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFD152),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                      ),
                                    ),
                                    child: Text(_saving ? '保存中…' : '立即进入'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _label(String text) => Text(
    text,
    style: TextStyle(fontSize: 12.sp, color: const Color(0xFF666666)),
  );

  Widget _box(Widget child) => Container(
    constraints: BoxConstraints(minHeight: 48.h),
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFD4D9DD)),
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: child,
  );

  Widget _genderButton(String value, String label, Color color) => Semantics(
    selected: _gender == value,
    child: SizedBox(
      height: 52.h,
      child: FilledButton(
        key: ValueKey('registration-gender-$value'),
        onPressed: _saving ? null : () => _genderChanged(value),
        style: FilledButton.styleFrom(
          backgroundColor: _gender == value ? color : const Color(0xFFF8F8F8),
          foregroundColor: _gender == value
              ? Colors.white
              : const Color(0xFF999999),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _asset(
              value == '男' ? 'male.svg' : 'female.svg',
              width: 24.r,
              height: 24.r,
              color: _gender == value ? Colors.white : const Color(0xFF999999),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _asset(
    String name, {
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) => AppImage(
    src: 'assets/auth/auth_registration_$name',
    width: width,
    height: height,
    iconColor: color,
    fit: fit,
  );
}
