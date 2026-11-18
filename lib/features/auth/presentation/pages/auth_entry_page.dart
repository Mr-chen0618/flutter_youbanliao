import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/config/legal_links.dart';
import '../../../../app/navigation/app_navigator.dart';
import '../../../../shared/pages/app_web_page.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../widgets/login_backdrop.dart';
import '../../data/repository/auth_repository.dart';
import '../widgets/welcome_animation.dart';
import 'phone_login_page.dart';

/// 未登录入口先展示欢迎动画与协议，再进入手机验证码登录。
class AuthEntryPage extends StatefulWidget {
  const AuthEntryPage({
    super.key,
    required this.auth,
    required this.onSignedIn,
  });
  final AuthRepository auth;
  final VoidCallback onSignedIn;

  @override
  State<AuthEntryPage> createState() => _AuthEntryPageState();
}

class _AuthEntryPageState extends State<AuthEntryPage> {
  bool _agreed = false, _phone = false;

  void _openPhone() {
    if (!_agreed) {
      AppToast.show('请先阅读并同意用户协议和隐私政策');
      return;
    }
    setState(() => _phone = true);
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
    if (_phone) {
      return PhoneLoginPage(
        auth: widget.auth,
        onSignedIn: widget.onSignedIn,
        onBack: () => setState(() => _phone = false),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LoginBackdrop(height: 414.h),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        SizedBox(height: 4.h),
                        SizedBox(
                          width: double.infinity,
                          height: 252.h,
                          child: const WelcomeAnimation(),
                        ),
                        Text(
                          '友伴聊找搭子，都是真资料！',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          '立即登录，有颜有趣的Ta在等你！',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: const Color(0xFF999999),
                          ),
                        ),
                        SizedBox(height: 36.h),
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 37.w),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: FilledButton(
                              key: const ValueKey('welcome-phone-login'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD152),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                              onPressed: _openPhone,
                              child: const Text('手机号登录'),
                            ),
                          ),
                        ),
                        SizedBox(height: 70.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Row(
                            children: [
                              Checkbox(
                                key: const ValueKey('welcome-agreement'),
                                value: _agreed,
                                activeColor: const Color(0xFFFFD152),
                                checkColor: Colors.black,
                                onChanged: (value) =>
                                    setState(() => _agreed = value ?? false),
                              ),
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '阅读并同意',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: const Color(0xFF999999),
                                      ),
                                    ),
                                    _link('用户协议'),
                                    Text(
                                      '和',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: const Color(0xFF999999),
                                      ),
                                    ),
                                    _link('隐私政策'),
                                  ],
                                ),
                              ),
                            ],
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
    );
  }

  Widget _link(String title) => TextButton(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF333333),
      minimumSize: const Size(0, 32),
      padding: EdgeInsets.zero,
      textStyle: TextStyle(fontSize: 11.sp),
    ),
    onPressed: () => _policy(title),
    child: Text('《$title》'),
  );
}
