import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/layout/app_scaffold.dart';

/// 通用应用内H5页面，保留页面标题、返回及主文档加载失败重试。
class AppWebPage extends StatefulWidget {
  const AppWebPage({super.key, required this.title, required this.url});
  final String title, url;
  @override
  State<AppWebPage> createState() => _AppWebPageState();
}

class _AppWebPageState extends State<AppWebPage> {
  late final WebViewController _controller;
  bool _loading = true, _failed = false;
  bool _active = true;
  String? _mainUrl;
  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _mainUrl = url;
            if (_active && mounted) {
              setState(() {
                _loading = true;
                _failed = false;
              });
            }
          },
          onPageFinished: (_) {
            if (_active && mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && _active && mounted) {
              setState(() {
                _failed = true;
                _loading = false;
              });
            }
          },
          onHttpError: (error) {
            if (error.request?.uri.toString() == _mainUrl &&
                _active &&
                mounted) {
              setState(() {
                _failed = true;
                _loading = false;
              });
            }
          },
          onNavigationRequest: (request) =>
              ['https', 'http'].contains(Uri.tryParse(request.url)?.scheme)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      );
      await _load();
    } catch (_) {
      if (_active && mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _load() async {
    if (!_active || !mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await _controller.loadRequest(Uri.parse(widget.url));
    } catch (_) {
      if (_active && mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _active = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    navigatorTitle: widget.title,
    body: Stack(
      children: [
        if (!_failed) WebViewWidget(controller: _controller),
        if (_loading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
        if (_failed)
          Center(
            child: TextButton(
              onPressed: _initialize,
              child: const Text('网页加载失败，点击重试'),
            ),
          ),
      ],
    ),
  );
}
