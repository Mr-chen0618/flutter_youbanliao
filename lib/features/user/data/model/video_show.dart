/// 应用目录中的本地视频；审核未接入前始终为待审核。
class VideoShow {
  const VideoShow({required this.path});
  final String path;
  factory VideoShow.fromJson(Object value) => VideoShow(
    path: value is String ? value : (value as Map)['path'] as String,
  );
  Map<String, dynamic> toJson() => {'path': path, 'status': 'pending'};
}
