class HomeCompanionModel {
  HomeCompanionModel({
    required this.id,
    this.businessId,
    required this.name,
    required this.avatar,
    required List<String> photos,
    required this.isOnline,
    required this.isVerified,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.city,
    required List<String> interests,
    required List<String> categoryIds,
    this.isInvited = false,
    this.gender,
  }) : photos = List.unmodifiable(photos),
       interests = List.unmodifiable(interests),
       categoryIds = List.unmodifiable(categoryIds);
  final String id;
  final String? businessId;
  String get displayId => businessId ?? id;
  final String name;
  final String avatar;
  final List<String> photos;
  final bool isOnline;
  final bool isVerified;
  final int age;
  final int heightCm;
  final int weightKg;
  final String city;
  final List<String> interests;
  final List<String> categoryIds;
  final bool isInvited;
  final String? gender;
  factory HomeCompanionModel.fromJson(Map<String, dynamic> json) =>
      HomeCompanionModel(
        id: json['id'] as String,
        businessId: json['businessId'] as String?,
        name: json['name'] as String,
        avatar: json['avatar'] as String,
        photos: (json['photos'] as List<dynamic>).cast<String>(),
        isOnline: json['isOnline'] as bool? ?? false,
        isVerified: json['isVerified'] as bool? ?? false,
        age: json['age'] as int,
        heightCm: json['heightCm'] as int,
        weightKg: json['weightKg'] as int,
        city: json['city'] as String,
        interests: (json['interests'] as List<dynamic>).cast<String>(),
        categoryIds: (json['categoryIds'] as List<dynamic>).cast<String>(),
        isInvited: json['isInvited'] as bool? ?? false,
        gender: json['gender'] as String?,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    if (businessId != null) 'businessId': businessId,
    'name': name,
    'avatar': avatar,
    'photos': photos.toList(),
    'isOnline': isOnline,
    'isVerified': isVerified,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'city': city,
    'interests': interests.toList(),
    'categoryIds': categoryIds.toList(),
    'isInvited': isInvited,
    'gender': gender,
  };
  HomeCompanionModel copyWith({bool? isInvited}) => HomeCompanionModel(
    id: id,
    businessId: businessId,
    name: name,
    avatar: avatar,
    photos: photos,
    isOnline: isOnline,
    isVerified: isVerified,
    age: age,
    heightCm: heightCm,
    weightKg: weightKg,
    city: city,
    interests: interests,
    categoryIds: categoryIds,
    isInvited: isInvited ?? this.isInvited,
    gender: gender,
  );
}
