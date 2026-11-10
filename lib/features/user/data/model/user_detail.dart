import '../../../home/data/model/home_category_model.dart';
import '../../../activity/data/model/home_activity_model.dart';
import 'home_companion_model.dart';

/// 用户目录资料及用户发布的活动。
class UserDetail {
  const UserDetail({
    required this.person,
    required this.activities,
    required this.signature,
    required this.tags,
    required this.categories,
    required this.isSelf,
    required this.isInvited,
  });

  final HomeCompanionModel person;
  final List<HomeActivityModel> activities;
  final String signature;
  final List<String> tags;
  final List<HomeCategoryModel> categories;
  final bool isSelf, isInvited;
}
