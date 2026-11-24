import '../../../../shared/widgets/images/app_image.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../providers/growth_provider.dart';

class VideoShowPage extends ConsumerStatefulWidget {
  const VideoShowPage({super.key});
  @override
  ConsumerState<VideoShowPage> createState() => _VideoShowState();
}

class _VideoShowState extends ConsumerState<VideoShowPage> {
  bool busy = false;
  Future<void> select() async {
    final repo = ref.read(growthRepositoryProvider);
    setState(() => busy = true);
    try {
      final video = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
      if (video == null || !mounted) return;
      if (await video.length() > 100 * 1024 * 1024) {
        throw StateError('文件超过100MB');
      }
      final probe = VideoPlayerController.file(File(video.path));
      try {
        await probe.initialize();
        final size = probe.value.size;
        final duration = probe.value.duration;
        if (duration < const Duration(seconds: 5) ||
            duration > const Duration(seconds: 30) ||
            size.width > size.height) {
          throw StateError('请选择5–30秒的竖屏视频');
        }
      } finally {
        await probe.dispose();
      }
      final dir = await getApplicationSupportDirectory();
      final target = Directory('${dir.path}/media/videos');
      await target.create(recursive: true);
      final path =
          '${target.path}/${DateTime.now().microsecondsSinceEpoch}.mp4';
      await video.saveTo(path);
      if (!mounted) return;
      await repo.saveVideo(path);
      ref.invalidate(growthProvider);
      AppToast.show('已保存视频，等待审核');
    } catch (e) {
      AppToast.show('请选择100MB以内、5–30秒的有效竖屏视频');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = ref.watch(growthProvider).value?.video?.path;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('上传视频秀', style: TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 154,
              height: 182,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9AD),
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: video != null
                        ? LocalVideoPreview(path: video)
                        : InkWell(
                            onTap: busy ? null : select,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppImage(
                                  src:
                                      'assets/profile/growth/3715_13618_imgIcon.svg',
                                  width: 32,
                                  height: 32,
                                ),
                                SizedBox(height: 12),
                                Text('添加视频', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                  ),
                  if (video != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Semantics(
                        label: '删除视频',
                        button: true,
                        child: InkWell(
                          onTap: busy
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(growthRepositoryProvider)
                                        .deleteVideo();
                                    ref.invalidate(growthProvider);
                                  } catch (e) {
                                    AppToast.show('删除失败，请重试');
                                  }
                                },
                          child: const CircleAvatar(
                            radius: 9,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '让搭子认识真实的你',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            '上传一段短视频，展示你的兴趣与日常',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '上传前请确认',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text('内容规范', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _tip('↕', '竖屏拍摄', '画面清晰、收音正常'),
                const SizedBox(height: 10),
                _tip('⏱', '时长 5–30 秒', '文件大小不超过100MB'),
                const SizedBox(height: 10),
                _tip('☺', '真实原创', '本人出镜，不搬运他人内容'),
                const SizedBox(height: 10),
                _tip('✓', '内容健康', '不含广告、联系方式或违规信息'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'ⓘ 审核通过后，视频将展示在你的个人主页',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _tip(String symbol, String title, String subtitle) => Row(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(symbol, style: const TextStyle(fontSize: 12)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    ],
  );
}

class LocalVideoPreview extends StatefulWidget {
  const LocalVideoPreview({super.key, required this.path});
  final String path;
  @override
  State<LocalVideoPreview> createState() => _LocalVideoPreviewState();
}

class _LocalVideoPreviewState extends State<LocalVideoPreview> {
  late VideoPlayerController controller;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    controller = VideoPlayerController.file(File(widget.path));
    controller
        .initialize()
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((Object e) {
          if (mounted) setState(() => error = '视频无法播放，请重新选择');
        });
  }

  @override
  void didUpdateWidget(covariant LocalVideoPreview old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      controller.dispose();
      error = null;
      _load();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => error != null
      ? Text(error!)
      : controller.value.isInitialized
      ? Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
                setState(() {});
              },
              child: Text(controller.value.isPlaying ? '暂停' : '播放'),
            ),
          ],
        )
      : const Center(child: CircularProgressIndicator());
}
