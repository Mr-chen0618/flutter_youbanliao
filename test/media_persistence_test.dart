import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_app_framework/core/media/app_media_picker.dart';
import 'package:flutter_app_framework/shared/widgets/images/app_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('media_quality_');
    AppMediaPicker.pickOverride = null;
    AppMediaPicker.directoryResolver = () async => directory;
  });
  tearDown(() async {
    AppMediaPicker.pickOverride = null;
    AppMediaPicker.sourcePicker = null;
    AppMediaPicker.directoryResolver = null;
    await directory.delete(recursive: true);
  });
  test('source picker cancellation writes no media', () async {
    AppMediaPicker.sourcePicker = () async => null;
    expect(await AppMediaPicker.pickImage(), isNull);
    expect(await Directory('${directory.path}/media').exists(), isFalse);
  });
  test(
    'selected image is copied to durable storage and survives source removal',
    () async {
      final source = await File(
        'assets/auth/auth_brand_logo_image.png',
      ).copy('${directory.path}/temporary.png');
      final bytes = await source.readAsBytes();
      AppMediaPicker.sourcePicker = () async => XFile(source.path);
      final path = await AppMediaPicker.pickImage();
      expect(path, isNotNull);
      expect(path, startsWith('${directory.path}/media/'));
      expect(path, isNot(source.path));
      await source.delete();
      expect(await File(path!).readAsBytes(), bytes);
      // 业务快照持久化绝对路径后，新的文件句柄仍能读到真实图片。
      final reopened = File(path);
      expect(await reopened.length(), bytes.length);
    },
  );
  test(
    'picker permission error and invalid or missing file do not create attachments',
    () async {
      AppMediaPicker.sourcePicker = () async =>
          throw PlatformException(code: 'photo_access_denied');
      expect(await AppMediaPicker.pickImage(), isNull);
      final corrupt = await File(
        '${directory.path}/bad.png',
      ).writeAsString('not an image');
      AppMediaPicker.sourcePicker = () async => XFile(corrupt.path);
      expect(await AppMediaPicker.pickImage(), isNull);
      AppMediaPicker.sourcePicker = () async =>
          XFile('${directory.path}/absent.png');
      expect(await AppMediaPicker.pickImage(), isNull);
      expect(await Directory('${directory.path}/media').exists(), isFalse);
    },
  );
  for (final uri in [false, true]) {
    testWidgets('AppImage decodes persistent local src (file URI=$uri)', (
      tester,
    ) async {
      final file = (await tester.runAsync(
        () => File(
          'assets/auth/auth_brand_logo_image.png',
        ).copy('${directory.path}/render.png'),
      ))!;
      final source = uri ? file.uri.toString() : file.path;
      final size = await tester.runAsync(() async {
        final provider = FileImage(file);
        final stream = provider.resolve(ImageConfiguration.empty);
        final completer = Completer<Size>();
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (image, sync) {
            completer.complete(
              Size(image.image.width.toDouble(), image.image.height.toDouble()),
            );
          },
          onError: (Object error, StackTrace? stack) {
            completer.completeError(error, stack);
          },
        );
        stream.addListener(listener);
        try {
          return await completer.future.timeout(const Duration(seconds: 5));
        } finally {
          stream.removeListener(listener);
        }
      });
      expect(size!.width, greaterThan(0));
      expect(size.height, greaterThan(0));
      await tester.pumpWidget(
        MaterialApp(home: AppImage(src: source, width: 88, height: 88)),
      );
      await tester.pumpAndSettle();
      final rendered = tester.widget<Image>(find.byType(Image));
      expect(rendered.image, isA<FileImage>());
      expect((rendered.image as FileImage).file.path, file.path);
      expect(tester.takeException(), isNull);
    });
  }
}
