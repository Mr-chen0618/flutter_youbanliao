import '../../data/profile_repository.dart';

/// 个人中心接收的业务操作。
sealed class UserEvent {
  const UserEvent();
}

final class UserProfileEdited extends UserEvent {
  const UserProfileEdited(this.update);
  final MemberProfile Function(MemberProfile) update;
}

final class UserSignedIn extends UserEvent {
  const UserSignedIn();
}

final class UserSignedOut extends UserEvent {
  const UserSignedOut();
}

final class UserAccountDeleted extends UserEvent {
  const UserAccountDeleted();
}

final class UserVerified extends UserEvent {
  const UserVerified();
}

final class UserFeedbackSubmitted extends UserEvent {
  const UserFeedbackSubmitted(
    this.text, {
    required this.contact,
    this.photos = const [],
  });
  final String text;
  final String contact;
  final List<String> photos;
}

final class UserStateReloaded extends UserEvent {
  const UserStateReloaded(this.value);
  final UserState value;
}
