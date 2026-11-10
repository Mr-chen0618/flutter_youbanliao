import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/mock_json_store.dart';
import '../../../user/presentation/providers/profile_provider.dart';
import '../../data/mock/activity_publication_mock_repository.dart';
import '../../data/repository/activity_publication_repository.dart';
import '../../data/request-model/activity_draft.dart';

final activityPublicationRepositoryProvider =
    Provider<ActivityPublicationRepository>(
      (ref) =>
          ActivityPublicationMockRepository(ref.watch(mockJsonStoreProvider)),
    );

final publishActivityProvider = Provider<Future<void> Function(ActivityDraft)>((
  ref,
) {
  return (draft) {
    final account = ref.read(userBlocProvider).state;
    if (!account.isSignedIn) throw StateError('Sign in required');
    return ref
        .read(activityPublicationRepositoryProvider)
        .publish(draft, account.profile.id);
  };
});
