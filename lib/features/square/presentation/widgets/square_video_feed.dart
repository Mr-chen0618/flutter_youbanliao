import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../providers/square_provider.dart';
import '../../../messages/presentation/providers/messages_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/layout/app_empty_state.dart';
import '../providers/square_video_publishers_provider.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../app/navigation/app_navigator.dart';
import '../../../user/presentation/pages/user_detail_page.dart';
import '../../data/model/square_video_catalog.dart';

/// 本地视频目录，滑动时只挂载当前播放器，避免同时解码多个视频。
class SquareVideoFeed extends ConsumerStatefulWidget {
  const SquareVideoFeed({super.key, required this.isActive});
  final bool isActive;

  @override
  ConsumerState<SquareVideoFeed> createState() => _SquareVideoFeedState();
}

class _SquareVideoFeedState extends ConsumerState<SquareVideoFeed> {
  int _index = 0;
  String? _feedKey;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(squareProvider);
    final publishers = ref.watch(squareVideoPublishersProvider);
    final blocked = ref.watch(messagesProvider).blocked.values;
    final blockedIds = {
      for (final thread in blocked) ...[
        thread.id,
        if (thread.peerId != null) thread.peerId!,
      ],
    };
    final ids = squareVideoIds
        .where((id) => !blockedIds.contains(squareVideoAuthorIds[id]))
        .toList();
    final accountId = ref.watch(authSessionProvider).value?.accountId ?? '';
    // 目录或账号变化时销毁旧PageView/播放器；旧滚动回调不再改写新目录索引。
    final feedKey = '$accountId:${ids.join(',')}';
    if (_feedKey != feedKey) {
      _feedKey = feedKey;
      _index = 0;
    }
    if (ids.isEmpty) {
      return const Center(
        child: AppEmptyState(
          message: '暂无可展示的视频',
          foregroundColor: Colors.white,
        ),
      );
    }
    final visible =
        widget.isActive && (ModalRoute.isCurrentOf(context) ?? true);
    return PageView.builder(
      key: ValueKey(feedKey),
      scrollDirection: Axis.vertical,
      itemCount: ids.length,
      onPageChanged: (index) {
        if (_feedKey == feedKey) setState(() => _index = index);
      },
      itemBuilder: (context, index) {
        final id = ids[index];
        final publisher = publishers.value?[squareVideoAuthorIds[id]];
        final base = 'assets/square/videos/$id';
        final liked = state.videoLikes.contains(id);
        final saved = state.videoSaves.contains(id);
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('$base.jpg', fit: BoxFit.contain),
            if (index == _index)
              _AssetVideo(
                key: ValueKey(id),
                asset: '$base.mp4',
                active: visible,
              ),
            if (publisher != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(15, 45, 15, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB3000000)],
                    ),
                  ),
                  child: InkWell(
                    key: ValueKey('video-publisher-$id'),
                    onTap: () => AppNavigator.push(
                      context,
                      page: UserDetailPage(userId: publisher.id),
                    ),
                    child: Row(
                      children: [
                        AppImage(
                          src: publisher.avatar,
                          width: 58,
                          height: 58,
                          radius: 29,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                publisher.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                publisher.signature,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
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
            Positioned(
              right: 16,
              bottom: 100,
              child: Column(
                children: [
                  IconButton(
                    tooltip: '喜欢',
                    color: liked ? Colors.pinkAccent : Colors.white,
                    icon: const Icon(Icons.thumb_up),
                    onPressed: () =>
                        ref.read(squareProvider.notifier).toggleVideoLike(id),
                  ),
                  IconButton(
                    tooltip: '收藏',
                    color: saved ? Colors.amber : Colors.white,
                    icon: const Icon(Icons.star),
                    onPressed: () =>
                        ref.read(squareProvider.notifier).toggleVideoSave(id),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 切换Tab、覆盖路由及进入后台时暂停；手动暂停在恢复前台时保持。
class _AssetVideo extends StatefulWidget {
  const _AssetVideo({super.key, required this.asset, required this.active});
  final String asset;
  final bool active;
  @override
  State<_AssetVideo> createState() => _AssetVideoState();
}

class _AssetVideoState extends State<_AssetVideo> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _paused = false;
  bool _foreground =
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    final controller = VideoPlayerController.asset(widget.asset);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      await controller.setLooping(true);
      if (!mounted || _controller != controller) return;
      controller.addListener(_listen);
      setState(() {});
      _sync();
    } catch (_) {
      if (mounted && _controller == controller) setState(() => _failed = true);
    }
  }

  void _listen() {
    if (mounted && _controller!.value.hasError && !_failed) {
      setState(() => _failed = true);
    }
  }

  void _sync() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (widget.active && _foreground && !_paused && !_failed) {
      controller.play();
    } else {
      controller.pause();
    }
  }

  @override
  void didUpdateWidget(covariant _AssetVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_listen);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: TextButton(
          onPressed: () {
            _controller?.removeListener(_listen);
            _controller?.dispose();
            setState(() => _failed = false);
            _load();
          },
          child: const Text('播放失败，点击重试', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    if (!(_controller?.value.isInitialized ?? false)) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _paused = !_paused);
        _sync();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          if (_paused)
            const Icon(Icons.play_arrow, color: Colors.white, size: 64),
        ],
      ),
    );
  }
}
