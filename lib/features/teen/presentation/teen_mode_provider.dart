import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/mock_json_store.dart';
import '../data/teen_mode_repository.dart';

final teenModeRepositoryProvider = Provider(
  (ref) => TeenModeRepository(ref.watch(mockJsonStoreProvider)),
);
final teenModeProvider = AsyncNotifierProvider<TeenModeController, bool>(
  TeenModeController.new,
);

class TeenModeController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(teenModeRepositoryProvider).enabled();
  Future<void> enable(String pin) async {
    await ref.read(teenModeRepositoryProvider).enable(pin);
    state = const AsyncData(true);
  }

  Future<bool> disable(String pin) async {
    final accepted = await ref.read(teenModeRepositoryProvider).disable(pin);
    if (accepted) state = const AsyncData(false);
    return accepted;
  }
}
