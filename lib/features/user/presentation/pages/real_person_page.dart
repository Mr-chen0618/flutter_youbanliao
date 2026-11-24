import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../providers/growth_provider.dart';

class RealPersonPage extends ConsumerStatefulWidget {
  const RealPersonPage({super.key});
  @override
  ConsumerState<RealPersonPage> createState() => _RealPersonState();
}

class _RealPersonState extends ConsumerState<RealPersonPage> {
  bool busy = false;
  Future<void> capture() async {
    final repo = ref.read(growthRepositoryProvider);
    setState(() => busy = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
      if (photo == null || !mounted) return;
      // 仅记录本地待审状态，照片及敏感信息不冒充服务端核验。
      await repo.submitRealPerson();
      ref.invalidate(growthProvider);
      AppToast.show('本地拍摄已完成，待接入核验服务');
    } catch (e) {
      AppToast.show('无法拍摄，请检查相机权限后重试');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(growthProvider).value?.realPerson == true;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('真人认证', style: TextStyle(fontSize: 16)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                const Row(
                  children: [
                    Text(
                      '●',
                      style: TextStyle(color: Color(0xFFFFCF45), fontSize: 8),
                    ),
                    SizedBox(width: 8),
                    Text('实时拍照认证', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 8),
                    Expanded(child: Divider()),
                    SizedBox(width: 8),
                    Text(
                      '1 / 1',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 345,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF212121),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '●',
                            style: TextStyle(
                              color: Color(0xFFFF5050),
                              fontSize: 7,
                            ),
                          ),
                          SizedBox(width: 7),
                          Text(
                            '实时拍摄',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                          Spacer(),
                          Text(
                            '请保持正脸',
                            style: TextStyle(
                              color: Color(0xFFC7C7C7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '正对镜头，保持自然表情',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _tip('01', '五官清晰可见', '摘下口罩、帽子和墨镜'),
                      const SizedBox(height: 10),
                      _tip('02', '光线均匀充足', '避免逆光或背景过暗'),
                      const SizedBox(height: 10),
                      _tip('03', '本人实时拍摄', '请勿使用照片或视频翻拍'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '🔒 照片仅用于真人核验，通过后展示认证标识',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCF45),
                    foregroundColor: const Color(0xFF2E2E2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: busy || pending ? null : capture,
                  child: Text(
                    pending
                        ? '待审核'
                        : busy
                        ? '拍摄中…'
                        : '拍照认证',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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

  Widget _tip(String number, String title, String subtitle) => Row(
    children: [
      CircleAvatar(
        radius: 13,
        backgroundColor: const Color(0xFFFFFBEC),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF2E2E2E),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    ],
  );
}
