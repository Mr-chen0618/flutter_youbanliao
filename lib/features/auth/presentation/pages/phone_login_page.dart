import '../../../../app/config/legal_links.dart';
import '../../../../shared/pages/app_web_page.dart';
import '../../../../app/navigation/app_navigator.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/input_validator.dart';
import '../../../../shared/form/widgets/app_text_field.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_backdrop_widget.dart';
import '../../data/repository/auth_repository.dart';
import '../../data/request-model/phone_login_request.dart';

/// 手机验证码登录及自动注册，所有请求由认证仓库校验。
class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({
    super.key,
    required this.auth,
    required this.onSignedIn,
  });
  final AuthRepository auth;
  final VoidCallback onSignedIn;
  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final _phone = TextEditingController(), _code = TextEditingController();
  Timer? _timer;
  int _seconds = 0;
  bool _sending = false, _submitting = false;
  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || _seconds > 0) return;
    setState(() {
      _sending = true;
    });
    try {
      await widget.auth.sendCode(_phone.text.trim());
      if (!mounted) return;
      setState(() => _seconds = 60);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _seconds--);
        if (_seconds == 0) timer.cancel();
      });
      AppToast.show('发送成功');
    } catch (error) {
      if (mounted) AppToast.showError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _login() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
    });
    try {
      await widget.auth.login(
        PhoneLoginRequest(_phone.text.trim(), _code.text.trim()),
      );
      if (mounted) widget.onSignedIn();
    } catch (error) {
      if (mounted) AppToast.showError(error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _policy(String title) => AppNavigator.push(
    context,
    page: AppWebPage(
      title: title,
      url: title == '用户协议'
          ? LegalLinks.userAgreementUrl
          : LegalLinks.privacyPolicyUrl,
    ),
  );
  @override
  Widget build(BuildContext context) {
    final validPhone = InputValidator.isAcceptableLoginPhoneNumber(
      _phone.text.trim(),
    );
    final enabled = validPhone && _code.text.trim().length == 4 && !_submitting;
    return Scaffold(
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
                children: [
                  SizedBox(height: 62.h),
                  AppImage(
                    src: 'assets/auth/auth_brand_logo_image.png',
                    width: 88.r,
                    height: 88.r,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '友伴聊',
                    style: TextStyle(
                      fontSize: 23.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '喜欢的事，有伴一起',
                    style: TextStyle(
                      color: const Color(0xFF949494),
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 46.h),
                  _box(
                    Row(
                      children: [
                        Text('+86', style: TextStyle(fontSize: 16.sp)),
                        SizedBox(width: 12.w),
                        Container(
                          width: 1,
                          height: 24.h,
                          color: const Color(0xFFEDEDED),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: AppTextField(
                            key: const ValueKey('auth-phone'),
                            controller: _phone,
                            hint: '请输入手机号',
                            keyboardType: TextInputType.phone,
                            formatter: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            onChanged: (_) => setState(() {}),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _box(
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            key: const ValueKey('auth-code'),
                            controller: _code,
                            hint: '请输入验证码',
                            keyboardType: TextInputType.number,
                            formatter: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            onChanged: (_) => setState(() {}),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        TextButton(
                          onPressed: validPhone && !_sending && _seconds == 0
                              ? _send
                              : null,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD152),
                            foregroundColor: const Color(0xFF180E04),
                            disabledBackgroundColor: const Color(0x7FFFD152),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            _sending
                                ? '发送中'
                                : _seconds > 0
                                ? '${_seconds}s后重发'
                                : '获取验证码',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 58.h),
                  SizedBox(
                    width: 311.w,
                    height: 52.h,
                    child: FilledButton(
                      onPressed: enabled ? _login : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD152),
                        foregroundColor: const Color(0xFF180E04),
                        disabledBackgroundColor: const Color(0x7FFFD152),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(_submitting ? '登录中…' : '登录/注册'),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    '未注册手机号验证后将自动创建账号',
                    style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '登录即表示同意',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF8C6B2E),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _policy('用户协议'),
                        child: const Text('《用户协议》'),
                      ),
                      TextButton(
                        onPressed: () => _policy('隐私政策'),
                        child: const Text('《隐私政策》'),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
}
