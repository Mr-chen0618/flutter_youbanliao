import '../../../../core/storage/mock_json_store.dart';
import '../model/order_state.dart';

/// 保存订单示例的最后一个已完成状态。
class OrderMockRepository {
  const OrderMockRepository(this.store);

  final MockJsonStore store;
  static const _path = 'example/order';

  Future<OrderState> load() => store.read(
    _path,
    (json) => OrderState.fromJson(json as Map<String, dynamic>),
  );

  Future<void> save(OrderState state) => store.write(_path, state.toJson());
}
