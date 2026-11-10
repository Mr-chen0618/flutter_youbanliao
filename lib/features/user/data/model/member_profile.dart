class MemberProfile {
  const MemberProfile({
    required this.name,
    required this.avatar,
    required this.signature,
    required this.gender,
    this.birthday,
    this.age,
    required this.city,
    required this.interests,
    required this.tags,
    this.companion = '',
    required this.id,
    this.businessId,
    required this.following,
    required this.followers,
    required this.friends,
  });

  final String id;
  final String? businessId;
  String get displayId => businessId ?? id;
  final int following;
  final int followers;
  final int friends;
  final String name;
  final String avatar;
  final String signature;
  final String gender;
  final DateTime? birthday;
  final int? age;
  final String city;
  final List<String> interests;
  final List<String> tags;
  final String companion;

  MemberProfile copyWith({
    String? businessId,
    String? name,
    String? avatar,
    String? signature,
    String? gender,
    DateTime? birthday,
    String? city,
    List<String>? interests,
    List<String>? tags,
    String? companion,
  }) => MemberProfile(
    id: id,
    businessId: businessId ?? this.businessId,
    following: following,
    followers: followers,
    friends: friends,
    name: name ?? this.name,
    avatar: avatar ?? this.avatar,
    signature: signature ?? this.signature,
    gender: gender ?? this.gender,
    birthday: birthday ?? this.birthday,
    age: age,
    city: city ?? this.city,
    interests: interests ?? this.interests,
    tags: tags ?? this.tags,
    companion: companion ?? this.companion,
  );
  factory MemberProfile.fromJson(Map<String, dynamic> json) => MemberProfile(
    id: json['id'] as String,
    businessId: json['businessId'] as String?,
    name: json['name'] as String,
    avatar: json['avatar'] as String,
    signature: json['signature'] as String,
    gender: json['gender'] as String,
    city: json['city'] as String,
    birthday: DateTime.tryParse(json['birthday'] as String? ?? ''),
    age: json['age'] as int?,
    interests: List<String>.unmodifiable(
      json['interests'] as List? ?? const [],
    ),
    tags: List<String>.unmodifiable(json['tags'] as List? ?? const []),
    companion: json['companion'] as String? ?? '',
    following: json['following'] as int? ?? 0,
    followers: json['followers'] as int? ?? 0,
    friends: json['friends'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (businessId != null) 'businessId': businessId,
    'name': name,
    'avatar': avatar,
    'signature': signature,
    'gender': gender,
    'city': city,
    'birthday': birthday?.toIso8601String(),
    'age': age,
    'interests': interests,
    'tags': tags,
    'companion': companion,
    'following': following,
    'followers': followers,
    'friends': friends,
  };
}
