import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityInviteState {
  const ActivityInviteState() : submissions = const {};
  ActivityInviteState._(Map<String, AsyncValue<void>> submissions)
    : submissions = Map.unmodifiable(submissions);

  final Map<String, AsyncValue<void>> submissions;

  ActivityInviteState copyWith({
    required Map<String, AsyncValue<void>> submissions,
  }) => ActivityInviteState._(submissions);
}
