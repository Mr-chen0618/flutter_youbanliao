import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/order_mock_repository.dart';
import 'order_event.dart';
import '../../data/order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc(this._repository, OrderState initial) : super(initial) {
    on<CreateOrderRequested>(_onCreateOrderRequested);
    on<PayOrderRequested>(_onPayOrderRequested);
    on<CompleteOrderRequested>(_onCompleteOrderRequested);
  }

  final OrderMockRepository _repository;

  Future<void> _onCreateOrderRequested(
    CreateOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    if (state.status == OrderStatus.creating ||
        state.status == OrderStatus.paying) {
      return;
    }
    emit(state.copyWith(status: OrderStatus.creating));

    await Future.delayed(const Duration(seconds: 1));

    await _save(
      emit,
      state.copyWith(
        status: OrderStatus.pendingPayment,
        message: '订单创建成功，等待支付',
      ),
    );
  }

  Future<void> _onPayOrderRequested(
    PayOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    if (state.status != OrderStatus.pendingPayment) return;
    emit(state.copyWith(status: OrderStatus.paying));

    await Future.delayed(const Duration(seconds: 1));

    await _save(
      emit,
      state.copyWith(status: OrderStatus.paid, message: '支付成功'),
    );
  }

  Future<void> _onCompleteOrderRequested(
    CompleteOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    if (state.status != OrderStatus.paid) return;
    await _save(
      emit,
      state.copyWith(status: OrderStatus.completed, message: '订单已完成'),
    );
  }

  /// 写入后才发布新的订单结果。
  Future<void> _save(Emitter<OrderState> emit, OrderState next) async {
    try {
      await _repository.save(next);
      if (!emit.isDone) emit(next);
    } catch (_) {
      if (!emit.isDone) {
        emit(const OrderState(status: OrderStatus.failure, message: '订单保存失败'));
      }
    }
  }
}
