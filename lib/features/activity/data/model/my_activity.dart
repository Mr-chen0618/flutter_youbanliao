import '../enum/activity_status.dart';

typedef MyActivity = ({
  String id,
  String title,
  String cover,
  ActivityStatus status,
  String category,
  bool joined,
  String time,
  String location,
  String description,
});
