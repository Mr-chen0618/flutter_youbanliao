import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/widgets/feedback/app_toast.dart';

/// 系统相册选择后复制到应用目录，取消返回 null；路径可跨重启使用。
class AppMediaPicker {
  AppMediaPicker._();
  static Future<String?> Function()? pickOverride;
  static Future<XFile?> Function()? sourcePicker;
  static Future<Directory> Function()? directoryResolver;
  static Future<String?> pickImage() async {
    try {
      if (pickOverride case final pick?) return await pick();
      final source =
          await (sourcePicker?.call() ??
              ImagePicker().pickImage(source: ImageSource.gallery));
      if (source == null) return null;
      final bytes = await source.readAsBytes();
      if (bytes.isEmpty || bytes.length > 20 * 1024 * 1024)
        throw StateError('请选择20MB以内的有效图片');
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      codec.dispose();
      final directory =
          await (directoryResolver?.call() ?? getApplicationSupportDirectory());
      final photos = Directory('${directory.path}/media');
      await photos.create(recursive: true);
      final extension = source.name.split('.').last.toLowerCase();
      final safeExtension = RegExp(r'^[a-z0-9]{1,5}$').hasMatch(extension)
          ? extension
          : 'jpg';
      final path =
          '${photos.path}/${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}.$safeExtension';
      await source.saveTo(path);
      return path;
    } on PlatformException {
      AppToast.show('无法访问相册，请检查相册权限后重试');
      return null;
    } catch (error) {
      AppToast.show('图片读取失败，请选择有效图片后重试');
      return null;
    }
  }
}
