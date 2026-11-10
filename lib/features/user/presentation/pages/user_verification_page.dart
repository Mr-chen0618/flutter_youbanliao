import '../../../../shared/widgets/feedback/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_card_surface_widget.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../bloc/user_event.dart';
import '../providers/profile_provider.dart';

/// 展示实名认证说明并收集核验信息。
class UserVerificationPage extends ConsumerStatefulWidget {
  const UserVerificationPage({super.key});

  @override
  ConsumerState<UserVerificationPage> createState() =>
      _UserVerificationPageState();
}

class _UserVerificationPageState extends ConsumerState<UserVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _valid = true;
  static const _instructions = '请填写真实姓名与身份证号码，提交后即可完成实名认证。';

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(profileProvider).value ?? ref.read(userBlocProvider).state;
    final verified = state.isVerified;
    return CompanionPageSurface(
      title: '我的认证',
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // 认证简介
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3BF),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppImage(
                      src: state.profile.avatar,
                      width: 50.r,
                      height: 50.r,
                      radius: 25.r,
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.profile.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _instructions,
                            style: TextStyle(
                              color: const Color(0xFF91641A),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    SvgPicture.asset(
                      'assets/profile/profile_verification_shield.svg',
                      width: 24.r,
                      height: 24.r,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                const Text('给信任多一份保障， 让志趣相投的人放心靠近。'),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          const Text('实名认证', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 16.h),
          // 实名认证表单
          CompanionCardSurfaceWidget(
            padding: EdgeInsets.all(14.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '实名认证',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E2),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          child: Text(
                            verified ? '已认证' : '待提交',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF91641A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    _instructions,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF999999),
                    ),
                  ),
                  const Divider(color: Color(0xFFF3F3F3)),
                  if (!verified) ...[
                    _field(
                      '真实姓名',
                      '请输入真实姓名',
                      (value) =>
                          (value?.trim().isEmpty ?? true) ? '请输入真实姓名' : null,
                    ),
                    SizedBox(height: 10.h),
                    _field(
                      '身份证号码',
                      '请输入身份证号码',
                      (value) =>
                          RegExp(
                            r'^[0-9]{17}[0-9Xx]$',
                          ).hasMatch(value?.trim() ?? '')
                          ? null
                          : '请输入有效的身份证号码',
                    ),
                    SizedBox(height: 10.h),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD04F),
                        foregroundColor: const Color(0xFF333333),
                        minimumSize: Size.fromHeight(52.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      onPressed: () {
                        _valid = true;
                        if (_formKey.currentState!.validate() && _valid) {
                          ref.read(userBlocProvider).add(const UserVerified());
                        }
                      },
                      child: const Text('提交认证'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // 信息使用说明
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '认证信息仅用于身份核验，不会公开展示你的真实姓名及证件号码。请勿冒用他人身份，携手维护真实、友善的友伴社区。',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF91641A)),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            '友伴守护每一次真诚的相遇',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  /// 单行核验字段。
  Widget _field(
    String label,
    String hint,
    FormFieldValidator<String> validator,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      SizedBox(height: 8.h),
      TextFormField(
        validator: (value) {
          final error = validator(value);
          if (error != null) {
            _valid = false;
            AppToast.show(error);
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF6F6F6),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Color(0xFFE7D8BA)),
          ),
        ),
      ),
    ],
  );
}
