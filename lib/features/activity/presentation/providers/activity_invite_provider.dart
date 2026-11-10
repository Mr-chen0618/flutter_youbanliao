import '../../../messages/presentation/providers/messages_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/mock_json_store.dart';
import '../../data/mock/activity_invite_mock_repository.dart';
import '../../data/repository/activity_invite_repository.dart';
import '../../data/request-model/activity_draft.dart';
import '../../data/request-model/activity_invite_request_model.dart';
import '../state/activity_invite_state.dart';

final activityInviteRepositoryProvider = Provider<ActivityInviteRepository>(
  (ref) => ActivityInviteMockRepository(ref.watch(mockJsonStoreProvider)),
);

final activityInviteProvider =
    NotifierProvider<ActivityInviteNotifier, ActivityInviteState>(
      ActivityInviteNotifier.new,
    );

class ActivityInviteNotifier extends Notifier<ActivityInviteState> {
  @override
  ActivityInviteState build() => const ActivityInviteState();

  Future<bool?> submitInvite(String companionId, {ActivityDraft? draft}) async {
    final previous = state.submissions[companionId];
    if (previous?.isLoading == true || previous?.hasValue == true) return null;

    final currentRef = ref;
    state = state.copyWith(
      submissions: {
        ...state.submissions,
        companionId: const AsyncLoading<void>(),
      },
    );
    final server = currentRef.read(activityInviteRepositoryProvider);
    var result = await AsyncValue.guard<void>(() async {
      await currentRef
          .read(messagesRepositoryProvider)
          .save(currentRef.read(messagesProvider));
      await server.submit(
        ActivityInviteRequestModel(companionId: companionId, draft: draft),
      );
    });
    if (currentRef.mounted) {
      try {
        await currentRef.read(messagesProvider.notifier).reload();
      } catch (error, stack) {
        result = AsyncError<void>(error, stack);
      }
      state = state.copyWith(
        submissions: {...state.submissions, companionId: result},
      );
    }
    return !result.hasError;
  }
}
