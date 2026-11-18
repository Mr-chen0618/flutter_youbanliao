import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svga/flutter_svga.dart';

import '../../../../shared/widgets/images/app_image.dart';

/// 欢迎页的本地SVGA，切后台暂停，离页或迟到解码均释放。
class WelcomeAnimation extends StatefulWidget {
  const WelcomeAnimation({super.key, this.decoder});
  final Future<MovieEntity> Function()? decoder;
  static const asset = 'assets/auth/auth_welcome.svga';

  @override
  State<WelcomeAnimation> createState() => _WelcomeAnimationState();
}

class _WelcomeAnimationState extends State<WelcomeAnimation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final SVGAAnimationController _controller;
  bool _ready = false, _foreground = true;

  @override
  void initState() {
    super.initState();
    _controller = SVGAAnimationController(vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      // 本地资源直接解码，避免播放器的磁盘缓存平台依赖。
      final movie = await (widget.decoder?.call() ?? _decodeAsset());
      if (!mounted) {
        movie.dispose();
        return;
      }
      _controller.videoItem = movie;
      setState(() => _ready = true);
      _syncPlayback();
    } catch (_) {
      // 解码失败仍允许阅读协议和手机号登录。
    }
  }

  Future<MovieEntity> _decodeAsset() async {
    final bytes = await rootBundle.load(WelcomeAnimation.asset);
    return SVGAParser.shared.decodeFromBuffer(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
  }

  void _syncPlayback() {
    if (!_ready) return;
    if (_foreground &&
        TickerMode.of(context) &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: _ready
        ? SVGAImage(
            _controller,
            fit: BoxFit.contain,
            clearsAfterStop: false,
            allowDrawingOverflow: false,
          )
        : const AppImage(
            src: 'assets/auth/auth_brand_logo_image.png',
            fit: BoxFit.contain,
          ),
  );
}
