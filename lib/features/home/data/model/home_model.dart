import 'home_category_model.dart';
import '../../../user/data/model/home_companion_model.dart';
import '../../../activity/data/model/home_activity_model.dart';

export 'home_category_model.dart';
export '../../../user/data/model/home_companion_model.dart';
export '../../../activity/data/model/home_activity_model.dart';

class HomeModel {
  HomeModel({
    List<HomeCategoryModel> categories = const [],
    List<HomeCompanionModel> companions = const [],
    List<HomeActivityModel> activities = const [],
  }) : categories = List.unmodifiable(categories),
       companions = List.unmodifiable(companions),
       activities = List.unmodifiable(activities);
  final List<HomeCategoryModel> categories;
  final List<HomeCompanionModel> companions;
  final List<HomeActivityModel> activities;
  factory HomeModel.fromJson(Map<String, dynamic> json) => HomeModel(
    categories: (json['categories'] as List<dynamic>)
        .map((item) => HomeCategoryModel.fromJson(item as Map<String, dynamic>))
        .toList(),
    companions: (json['companions'] as List<dynamic>)
        .map(
          (item) => HomeCompanionModel.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
    activities: (json['activities'] as List<dynamic>)
        .map((item) => HomeActivityModel.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
  Map<String, dynamic> toJson() => {
    'categories': categories.map((item) => item.toJson()).toList(),
    'companions': companions.map((item) => item.toJson()).toList(),
    'activities': activities.map((item) => item.toJson()).toList(),
  };
}
