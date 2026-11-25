import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/mock_json_store.dart';
import '../../data/model/square_video_publisher.dart';

/// 使用公共种子目录，自己的资料编辑不会改写固定模拟发布者。
final squareVideoPublishersProvider =
    FutureProvider<Map<String, SquareVideoPublisher>>((ref) async {
      final data = await ref
          .watch(mockJsonStoreProvider)
          .seed('home/catalog', (value) => value as Map<String, dynamic>);
      return {
        for (final item in data['companions'] as List)
          (item as Map<String, dynamic>)['id'] as String:
              SquareVideoPublisher.fromJson(item),
      };
    });
