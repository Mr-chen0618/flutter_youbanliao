import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/profile_repository.dart';
import 'user_event.dart';

/// 接收个人中心事件并更新资料和账号状态。
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc(this.repository, UserState initial) : super(initial) {
    on<UserEvent>((event, emit) async {
      switch (event) {
        case UserStateReloaded(:final value):
          emit(value);
        case UserProfileEdited(:final update):
          final edited = update(state.profile);
          emit(
            state.copyWith(
              profile: state.profileCompleted
                  ? edited.copyWith(gender: state.profile.gender)
                  : edited,
            ),
          );
        case UserSignedIn():
          emit(state.copyWith(isSignedIn: true));
        case UserSignedOut():
          emit(state.copyWith(isSignedIn: false));
        case UserAccountDeleted():
          emit(state.copyWith(isSignedIn: false, isDeleted: true));
        case UserVerified():
          emit(state.copyWith(isVerified: true));
        case UserFeedbackSubmitted(:final text, :final contact, :final photos):
          final feedback = text.trim();
          if (feedback.isNotEmpty) {
            emit(
              state.copyWith(
                feedback: List.unmodifiable([
                  ...state.feedback,
                  (
                    text: feedback,
                    contact: contact,
                    photos: List.unmodifiable(photos),
                  ),
                ]),
              ),
            );
          }
      }
    }, transformer: (events, mapper) => events.asyncExpand(mapper));
  }
  final ProfileRepository repository;
  Future<void> refresh() async {
    final loaded = await repository.load();
    if (!isClosed) add(UserStateReloaded(loaded));
  }
}
