/// 发布和发起邀约使用的活动表单数据。
class ActivityDraft {
  const ActivityDraft({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.category,
    required this.eventTime,
    required this.location,
    this.gender = '不限',
    this.photos = const [],
  });

  final String title, description, categoryId, category, location, gender;
  final DateTime eventTime;
  final List<String> photos;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'categoryId': categoryId,
    'category': category,
    'eventTime': eventTime.toIso8601String(),
    'location': location,
    'gender': gender,
    'photos': photos,
  };
}
