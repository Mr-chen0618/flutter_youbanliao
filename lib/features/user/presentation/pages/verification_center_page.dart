import '../../../../shared/widgets/images/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/navigation/app_navigator.dart';
import '../providers/growth_provider.dart';
import 'user_verification_page.dart';

import 'real_person_page.dart';

class VerificationCenterPage extends ConsumerWidget {
  const VerificationCenterPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(growthProvider).value;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F0F0),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(
            height: 148,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AppImage(
                    src: 'assets/profile/growth/3781_12261_img4.svg',
                    fit: BoxFit.fill,
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 20,
                  width: 187,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '身份认证',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '致力于构造一个安全、真实优质的社区环境，点亮越多认证，越受欢迎哦',
                        style: TextStyle(fontSize: 12, height: 1.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                width: 4,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text('请完成以下认证', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _card(
                  context,
                  '真人认证',
                  '认证后展示已认证标识',
                  data?.realPerson == true,
                  data?.realPersonVerified == true,
                  const RealPersonPage(),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _card(
                  context,
                  '实名认证',
                  '提供真实可信的交友环境',
                  data?.identityPending == true,
                  data?.identityVerified == true,
                  const UserVerificationPage(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String title,
    String desc,
    bool pending,
    bool verified,
    Widget page,
  ) => Container(
    height: 171,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppImage(
          key: ValueKey(
            '$title-badge-${verified ? 'verified' : 'unverified'}',
          ),
          src:
              'assets/profile/growth/3781_12261_img${title == '真人认证' ? (verified ? 5 : 6) : (verified ? 8 : 9)}.svg',
          width: 38,
          height: 38,
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(fontSize: 11)),
        const Spacer(),
        SizedBox(
          width: 132,
          height: 34,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFD43F),
              foregroundColor: const Color(0xFF333333),
              padding: EdgeInsets.zero,
              shape: const StadiumBorder(),
            ),
            onPressed: verified
                ? null
                : () => AppNavigator.push<void>(context, page: page),
            child: Text(
              verified
                  ? '已认证'
                  : pending
                  ? '审核中'
                  : '去认证',
            ),
          ),
        ),
      ],
    ),
  );
}
