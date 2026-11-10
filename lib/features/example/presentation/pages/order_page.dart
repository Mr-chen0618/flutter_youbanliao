import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/mock_json_store.dart';
import '../../data/order_mock_repository.dart';

import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../../data/order_state.dart';

final _orderRepository = Provider(
  (ref) => OrderMockRepository(ref.watch(mockJsonStoreProvider)),
);
final _initialOrder = FutureProvider.autoDispose(
  (ref) => ref.watch(_orderRepository).load(),
);

class OrderPage extends ConsumerWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(_initialOrder)
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => ref.invalidate(_initialOrder),
              child: const Text('读取失败，点击重试'),
            ),
          ),
        ),
        data: (initial) => BlocProvider(
          create: (_) => OrderBloc(ref.read(_orderRepository), initial),
          child: const _OrderView(),
        ),
      );
}

class _OrderView extends StatelessWidget {
  const _OrderView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bloc Order Flow')),
      body: Center(
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            return Text(
              'Status: ${state.status.name}\n${state.message ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<OrderBloc>().add(const CreateOrderRequested());
                },
                child: const Text('创建订单'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<OrderBloc>().add(const PayOrderRequested());
                },
                child: const Text('支付'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
