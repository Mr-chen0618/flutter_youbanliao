import '../../../../shared/widgets/images/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../providers/growth_provider.dart';

/// 实名信息只在表单内存中校验；本地实现保存待审状态，不冒充身份核验通过。
class UserVerificationPage extends ConsumerStatefulWidget {
  const UserVerificationPage({super.key});
  @override
  ConsumerState<UserVerificationPage> createState() =>
      _UserVerificationPageState();
}

class _UserVerificationPageState extends ConsumerState<UserVerificationPage> {
  final form = GlobalKey<FormState>();
  bool agreed = false, busy = false;
  Future<void> submit() async {
    if (!(form.currentState?.validate() ?? false)) return;
    if (!agreed) {
      AppToast.show('请先阅读并同意协议');
      return;
    }
    setState(() => busy = true);
    final repo = ref.read(growthRepositoryProvider);
    try {
      await repo.submitIdentity();
      if (mounted) {
        ref.invalidate(growthProvider);
        AppToast.show('本地提交已保存，等待核验服务');
      }
    } catch (e) {
      AppToast.show('提交失败，请重试');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(growthProvider).value?.identityPending == true;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('实名认证', style: TextStyle(fontSize: 16)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  height: 116,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '完成实名认证',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '提升账号可信度，获得更多信任',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              '信息仅用于本人身份核验',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 82,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const AppImage(
                                    src:
                                        'assets/profile/growth/identity_dot.svg',
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 4,
                                          color: const Color(0xFFEDEDED),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 4,
                                          color: const Color(0xFFEDEDED),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                height: 3,
                                color: const Color(0xFFEDEDED),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: pending
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('认证待审核'),
                        )
                      : Form(
                          key: form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '👤 真实姓名',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _field(
                                '请输入与身份证一致的姓名',
                                (v) => v?.trim().isNotEmpty == true
                                    ? null
                                    : '请输入真实姓名',
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1),
                              ),
                              const Text(
                                '🪪 身份证号码',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _field(
                                '请输入 18 位身份证号码',
                                (v) =>
                                    RegExp(
                                      r'^[0-9]{17}[0-9Xx]$',
                                    ).hasMatch(v?.trim() ?? '')
                                    ? null
                                    : '请输入有效的身份证号码',
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '🔐 身份信息仅用于实名认证，不会公开展示',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (!pending)
                  Row(
                    children: [
                      Checkbox(
                        value: agreed,
                        onChanged: busy
                            ? null
                            : (v) => setState(() => agreed = v ?? false),
                      ),
                      const Text(
                        '我已阅读并同意',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('实名认证服务协议'),
                            content: const Text(
                              '正式协议正文尚未提供，当前认证仅为本地演示提交，不会进行真实身份核验。',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('知道了'),
                              ),
                            ],
                          ),
                        ),
                        child: const Text(
                          '《实名认证服务协议》',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD23F),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: busy || pending ? null : submit,
                  child: Text(
                    pending
                        ? '待审核'
                        : busy
                        ? '提交中…'
                        : '提交认证',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String hint, FormFieldValidator<String> validator) =>
      TextFormField(
        validator: validator,
        enabled: !busy,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFF6F6F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
