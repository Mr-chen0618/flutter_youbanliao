import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svga/flutter_svga.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'bundled welcome SVGA is the supplied asset and decodes images and frames',
    () async {
      final bytes = await File('assets/auth/auth_welcome.svga').readAsBytes();
      expect(bytes.length, 231987);
      final movie = await SVGAParser.shared.decodeFromBuffer(bytes);
      expect(movie.params.viewBoxWidth, greaterThan(0));
      expect(movie.params.viewBoxHeight, greaterThan(0));
      expect(movie.params.frames, greaterThan(1));
      expect(movie.params.fps, greaterThan(0));
      expect(movie.sprites, isNotEmpty);
      expect(movie.bitmapCache, isNotEmpty);
      for (final image in movie.bitmapCache.values) {
        image.dispose();
      }
    },
  );
}
