import '../../../../core/media/app_media_picker.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/input_validator.dart';
import '../../../../shared/form/widgets/app_text_field.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_backdrop_widget.dart';
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
  String _avatar = '', _gender = '';
  DateTime? _birthday;
  bool _saving = false;
  final _random = Random.secure();
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _back() async {
    if (_saving) return;
    try {
      await widget.auth.signOut();
      if (mounted) widget.onChanged();
    } catch (error) {
      if (mounted) AppToast.showError(error);
    }
  }

  Future<void> _avatarPicker() async {
    final selected = await AppMediaPicker.pickImage();
    if (mounted && selected != null) setState(() => _avatar = selected);
  }

  Future<void> _date() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 1)),
    );
    if (mounted && date != null) setState(() => _birthday = date);
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (_avatar.isEmpty ||
        _gender.isEmpty ||
        !InputValidator.validateNickname(_name.text.trim()) ||
        _birthday == null) {
      AppToast.show('请添加头像，选择性别、设置有效昵称和生日');
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
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CompanionBackdropWidget(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: '返回登录',
                      onPressed: _saving ? null : _back,
                      icon: const Icon(Icons.chevron_left),
                    ),
                  ),
                  Text(
                    '完善资料',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '完善资料，让搭子更快认识你',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF8F8F8F),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Center(
                    child: Semantics(
                      button: true,
                      label: '更换头像',
                      child: InkWell(
                        key: const ValueKey('registration-avatar'),
                        onTap: _saving ? null : _avatarPicker,
                        child: SizedBox(
                          width: 116.r,
                          height: 116.r,
                          child: Stack(
                            children: [
                              AppImage(
                                src: _avatar.isEmpty
                                    ? 'assets/auth/auth_profile_default_avatar_image.png'
                                    : _avatar,
                                width: 108.r,
                                height: 108.r,
                                radius: 54.r,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 4,
                                child: Container(
                                  width: 32.r,
                                  height: 32.r,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFD152),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '添加一张清晰的头像，让搭子更快认识你',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF949494),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _label('你的性别 (注册后不可修改)'),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _genderButton(
                          '男',
                          '我是男生',
                          Icons.male,
                          const Color(0xFF21B1FF),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _genderButton(
                          '女',
                          '我是女生',
                          Icons.female,
                          const Color(0xFFFF83AE),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _label('设置昵称'),
                  SizedBox(height: 10.h),
                  _box(
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            key: const ValueKey('registration-name'),
                            controller: _name,
                            hint: '请设置一个昵称',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _saving
                              ? null
                              : () => setState(
                                  () => _name.text =
                                      '友伴${_random.nextInt(9000) + 1000}',
                                ),
                          icon: const Icon(Icons.shuffle, size: 18),
                          label: const Text('随机一个'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _label('选择生日'),
                  SizedBox(height: 10.h),
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
                                  : '${_birthday!.year}年${_birthday!.month}月${_birthday!.day}日',
                              style: TextStyle(
                                color: _birthday == null
                                    ? const Color(0xFFD4D9DD)
                                    : Colors.black,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 130.h),
                  SizedBox(
                    height: 52.h,
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD152),
                        foregroundColor: const Color(0xFF180E04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(_saving ? '保存中…' : '立即进入'),
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
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
    height: 48.h,
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFD4D9DD)),
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: child,
  );
  Widget _genderButton(
    String value,
    String label,
    IconData icon,
    Color color,
  ) => SizedBox(
    height: 52.h,
    child: FilledButton.icon(
      onPressed: _saving ? null : () => setState(() => _gender = value),
      style: FilledButton.styleFrom(
        backgroundColor: _gender == value ? color : const Color(0xFFF8F8F8),
        foregroundColor: _gender == value
            ? Colors.white
            : const Color(0xFF999999),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      icon: Icon(icon),
      label: Text(label),
    ),
  );
}
