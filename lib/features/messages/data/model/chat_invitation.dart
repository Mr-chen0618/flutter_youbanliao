class ChatInvitation {
  const ChatInvitation({
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.time,
    required this.district,
    required this.meetingPoint,
    this.activityId,
  });

  final String title;
  final String description;
  final String category;
  final String date;
  final String time;
  final String district;
  final String meetingPoint;
  final String? activityId;
  factory ChatInvitation.fromJson(Map<String, dynamic> json) => ChatInvitation(
    activityId: json['activityId'] as String?,
    title: json['title'] as String,
    description: json['description'] as String,
    category: json['category'] as String,
    date: json['date'] as String,
    time: json['time'] as String,
    district: json['district'] as String,
    meetingPoint: json['meetingPoint'] as String,
  );

  Map<String, dynamic> toJson() => {
    if (activityId != null) 'activityId': activityId,
    'title': title,
    'description': description,
    'category': category,
    'date': date,
    'time': time,
    'district': district,
    'meetingPoint': meetingPoint,
  };
}
