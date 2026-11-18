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
import '../widgets/login_restriction_dialogs.dart';
import '../widgets/login_backdrop.dart';
import '../../data/model/auth_login_restriction.dart';
import '../../data/repository/auth_repository.dart';
import '../../data/request-model/phone_login_request.dart';

/// 手机验证码登录及自动注册，所有请求由认证仓库校验。
class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({
    super.key,
    required this.auth,
    required this.onSignedIn,
    this.onBack,
  });
  final AuthRepository auth;
  final VoidCallback onSignedIn;
  final VoidCallback? onBack;
  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final _phone = TextEditingController(), _code = TextEditingController();
  Timer? _timer;
  int _seconds = 0;
  bool _sending = false, _submitting = false, _sentOnce = false;
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
      setState(() {
        _seconds = 60;
        _sentOnce = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _seconds--);
        if (_seconds == 0) timer.cancel();
      });
      AppToast.show('验证码已发送');
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
    } on AuthAccountPendingDeletion catch (restriction) {
      if (!mounted) return;
      final request = PhoneLoginRequest(_phone.text.trim(), _code.text.trim());
      await showPendingDeletionDialog(
        context,
        onRecover: () async {
          final auth = widget.auth;
          if (auth is! AuthRecoveryRepository) throw StateError('暂不支持恢复账号');
          await (auth as AuthRecoveryRepository).recoverAccount(
            restriction.accountId,
            request,
          );
          if (mounted) widget.onSignedIn();
        },
      );
    } on AuthAccountSuspended catch (restriction) {
      if (mounted) await showSuspendedDialog(context, restriction);
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
    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_submitting) widget.onBack?.call();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LoginBackdrop(height: 334.h),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(
                      height: 36.h,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: '返回',
                          onPressed: _submitting ? null : widget.onBack,
                          icon: const Icon(Icons.chevron_left),
                        ),
                      ),
                    ),
                    _loginBanner(),
                    SizedBox(height: 12.h),
                    Text(
                      '友伴聊找搭子，都是真资料！',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '使用手机号登录/注册解锁全部功能',
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 50.h),
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
                                  : _sentOnce
                                  ? '重新获取'
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
      ),
    );
  }

  /// 顶部人物与气泡完整对应2769:7325的已输入状态。
  Widget _loginBanner() => SizedBox(
    width: 220.w,
    height: 110.h,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 0,
          child: AppImage(
            src: 'assets/auth/auth_login_banner_caption.svg',
            width: 186.w,
            height: 29.h,
          ),
        ),
        _face('right', 163, 53, 41),
        _face('left', 16, 53, 41),
        _face('inner_right', 126, 47, 54),
        _face('inner_left', 40, 47, 54),
        _face('center', 76, 40, 68),
      ],
    ),
  );

  Widget _face(String name, double left, double top, double size) => Positioned(
    left: left.w,
    top: top.h,
    child: AppImage(
      src: 'assets/auth/auth_login_face_$name.png',
      width: size.r,
      height: size.r,
    ),
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
}
