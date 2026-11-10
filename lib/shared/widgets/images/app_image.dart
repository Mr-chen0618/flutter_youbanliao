import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_cached_image.dart';

class AppImage extends StatefulWidget {
  const AppImage({
    super.key,
    this.borderRadius,
    this.radius,
    this.fit,
    this.defaultAssets,
    this.src,
    this.width,
    this.height,
    this.iconColor,
    this.networkPlaceholderWidget,
    this.aspectRatio,
    this.enableCache = true,
    this.errorWidget,
    this.file,
  });

  final BorderRadiusGeometry? borderRadius;
  final double? radius;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final BoxFit? fit;
  final String? defaultAssets;
  final String? src;
  final Color? iconColor;
  final Widget? networkPlaceholderWidget;
  final Widget? errorWidget;
  final bool enableCache;
  final File? file;

  @override
  State<AppImage> createState() => _AppImageState();
}

enum _ImageType { empty, asset, network, base64, file }

class _AppImageState extends State<AppImage> {
  static const _defaultRadius = 0.0;
  static const _defaultFit = BoxFit.cover;

  _ImageType _imageType = _ImageType.empty;
  bool _needClip = false;
  Uint8List? _memoryBytes;

  BorderRadiusGeometry get _borderRadius {
    return widget.borderRadius ??
        BorderRadius.all(Radius.circular(widget.radius ?? _defaultRadius));
  }

  @override
  void initState() {
    super.initState();
    _resolveAll();
  }

  @override
  void didUpdateWidget(covariant AppImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.src != widget.src ||
        oldWidget.file != widget.file ||
        oldWidget.radius != widget.radius ||
        oldWidget.borderRadius != widget.borderRadius) {
      _resolveAll();
    }
  }

  void _resolveAll() {
    _imageType = _resolveImageType();
    _needClip = _checkNeedClip();
    _memoryBytes = null;

    if (_imageType == _ImageType.base64 && widget.src != null) {
      _memoryBytes = _decodeBase64(widget.src!);
    }
  }

  _ImageType _resolveImageType() {
    if (widget.file != null) return _ImageType.file;

    final src = widget.src;
    if (src == null || src.isEmpty) return _ImageType.empty;
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return _ImageType.network;
    }
    if (src.startsWith('/') || src.startsWith('file://')) {
      return _ImageType.file;
    }
    if (src.startsWith('data:image/')) return _ImageType.base64;

    return _ImageType.asset;
  }

  bool _checkNeedClip() {
    if (widget.borderRadius != null) return true;
    final r = widget.radius;
    return r != null && r > 0;
  }

  Uint8List? _decodeBase64(String src) {
    try {
      final data = src.contains('base64,') ? src.split('base64,').last : src;
      return base64.decode(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget image;

    switch (_imageType) {
      case _ImageType.file:
        image = _buildFileImage(
          widget.file ??
              (widget.src!.startsWith('file://')
                  ? File.fromUri(Uri.parse(widget.src!))
                  : File(widget.src!)),
        );
        break;
      case _ImageType.network:
        image = _buildNetworkImage(widget.src!);
        break;
      case _ImageType.base64:
        image = _buildMemoryImage();
        break;
      case _ImageType.asset:
        image = _buildAssetImage(widget.src ?? '');
        break;
      case _ImageType.empty:
        image = _buildPlaceholder();
        break;
    }

    if (_needClip) {
      image = ClipRRect(borderRadius: _borderRadius, child: image);
    }

    if (widget.aspectRatio != null) {
      return AspectRatio(aspectRatio: widget.aspectRatio!, child: image);
    }

    return image;
  }

  Widget _buildNetworkImage(String url) {
    return AppCachedImage(
      imageUrl: url,
      fit: widget.fit ?? _defaultFit,
      width: widget.width,
      height: widget.height,
      placeholder: _buildPlaceholder(),
      errorWidget: widget.errorWidget ?? _buildErrorWidget(),
    );
  }

  Widget _buildAssetImage(String asset, {BoxFit? fit}) {
    if (asset.isEmpty) return _buildErrorWidget();

    // 发布页等业务图标使用 SVG，必须交给矢量解码器渲染。
    if (asset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        width: widget.width,
        height: widget.height,
        fit: fit ?? widget.fit ?? BoxFit.contain,
        colorFilter: widget.iconColor == null
            ? null
            : ColorFilter.mode(widget.iconColor!, BlendMode.srcIn),
        errorBuilder: (_, _, _) => _buildErrorWidget(),
      );
    }

    return Image.asset(
      asset,
      width: widget.width,
      height: widget.height,
      fit: fit ?? widget.fit ?? _defaultFit,
      color: widget.iconColor,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _buildErrorWidget(),
    );
  }

  Widget _buildFileImage(File file) {
    return Image.file(
      file,
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? _defaultFit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _buildErrorWidget(),
    );
  }

  Widget _buildMemoryImage() {
    if (_memoryBytes == null) return _buildErrorWidget();

    return Image.memory(
      _memoryBytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? _defaultFit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _buildErrorWidget(),
    );
  }

  Widget _buildPlaceholder() {
    return _buildAssetImage(widget.defaultAssets ?? "", fit: BoxFit.cover);
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) return widget.errorWidget!;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: _borderRadius,
        color: Colors.grey.shade500,
      ),
      child: const Icon(Icons.error_outline, color: Colors.grey, size: 24),
    );
  }

  // @override
  // void dispose() {
  //   if (!widget.enableCache && widget.src != null) {
  //     CachedNetworkImage.evictFromCache(widget.src!);
  //   }
  //   super.dispose();
  // }
}
