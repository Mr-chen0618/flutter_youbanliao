typedef ActivityPublisher = ({String id, String name, String avatar});

/// 目录中的活动详情及当前账号的本地互动状态。
class ActivityDetail {
  ActivityDetail(
    Map<String, dynamic> json, {
    required this.publisher,
    required this.viewer,
    required this.joined,
    required this.followed,
    this.viewerGender,
  }) : title = json['title'] as String,
       cover = json['image'] as String,
       publishedAt = json['time'] as String,
       location = json['location'] as String,
       description = json['description'] as String,
       category = json['category'] as String? ?? '',
       eventTime = DateTime.tryParse(json['eventTime'] as String? ?? ''),
       ownerId = json['ownerId'] as String?,
       gender = json['gender'] as String?,
       photos = List<String>.from(json['photos'] as List? ?? const []);

  final String title, cover, publishedAt, location, description, category;
  final List<String> photos;
  final DateTime? eventTime;
  final String? gender;
  final String? viewerGender, ownerId;
  final ActivityPublisher? publisher;
  final ActivityPublisher viewer;
  final bool joined, followed;

  bool get isOwn => ownerId == viewer.id || publisher?.id == viewer.id;
  String? get joinBlockedReason {
    if (isOwn) return '不能报名自己发布的活动';
    if (joined) return '已报名';
    final requiredGender = switch (gender) {
      '男' || '男生' || '仅限男生' || '仅男生' || '限男' => '男',
      '女' || '女生' || '仅限女生' || '仅女生' || '限女' => '女',
      _ => null,
    };
    if (requiredGender != null && viewerGender != requiredGender) {
      return '本活动仅限$requiredGender生报名';
    }
    return null;
  }
}
