import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/counter_provider.dart';

class CounterPage extends ConsumerWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod Counter')),
      body: Center(
        child: count.when(
          data: (value) =>
              Text('Count: $value', style: const TextStyle(fontSize: 24)),
          loading: () => const CircularProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(counterProvider),
            child: const Text('读取失败，点击重试'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: count.hasValue
            ? ref.read(counterProvider.notifier).increment
            : null,
        child: const Icon(Icons.add),
      ),
    );
  }
}
