import 'member_profile.dart';
import 'user_feedback.dart';

/// 个人资料和账号状态。
class UserState {
  const UserState(
    this.profile, {
    this.isSignedIn = true,
    this.profileCompleted = true,
    this.isDeleted = false,
    this.feedback = const [],
    this.isVerified = false,
  });

  final MemberProfile profile;
  final bool isSignedIn;
  final bool profileCompleted;
  final bool isDeleted;
  final List<UserFeedback> feedback;
  final bool isVerified;

  UserState copyWith({
    MemberProfile? profile,
    bool? isSignedIn,
    bool? profileCompleted,
    bool? isDeleted,
    List<UserFeedback>? feedback,
    bool? isVerified,
  }) => UserState(
    profile ?? this.profile,
    isSignedIn: isSignedIn ?? this.isSignedIn,
    profileCompleted: profileCompleted ?? this.profileCompleted,
    isDeleted: isDeleted ?? this.isDeleted,
    feedback: feedback ?? this.feedback,
    isVerified: isVerified ?? this.isVerified,
  );
  factory UserState.fromJson(Map<String, dynamic> json) => UserState(
    MemberProfile.fromJson(json['profile'] as Map<String, dynamic>),
    isSignedIn: json['isSignedIn'] as bool? ?? true,
    profileCompleted: json['profileCompleted'] as bool? ?? true,
    isDeleted: json['isDeleted'] as bool? ?? false,
    isVerified: json['isVerified'] as bool? ?? false,
    feedback: List.unmodifiable(
      (json['feedback'] as List? ?? const []).map(
        (entry) => (
          text: entry['text'] as String,
          contact: entry['contact'] as String,
          photos: List<String>.unmodifiable(
            entry['photos'] as List? ?? const [],
          ),
        ),
      ),
    ),
  );

  Map<String, dynamic> toJson() => {
    'profile': profile.toJson(),
    'isSignedIn': isSignedIn,
    'profileCompleted': profileCompleted,
    'isDeleted': isDeleted,
    'isVerified': isVerified,
    'feedback': feedback
        .map(
          (item) => {
            'text': item.text,
            'contact': item.contact,
            'photos': item.photos,
          },
        )
        .toList(),
  };
}
