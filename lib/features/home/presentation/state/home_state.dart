import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/model/home_model.dart';
import '../enum/home_feed_kind_enum.dart';

class HomeState {
  const HomeState({
    this.city = '深圳',
    this.kind = HomeFeedKindEnum.companions,
    this.query = '',
    this.feed = const AsyncLoading(),
  });

  final String city;
  final HomeFeedKindEnum kind;
  final String query;
  final AsyncValue<HomeModel> feed;

  List<HomeCompanionModel> get visibleCompanions =>
      feed.value?.companions
          .where((person) => _matches(person.name))
          .toList() ??
      [];

  List<HomeActivityModel> get visibleActivities =>
      feed.value?.activities.where((event) => _matches(event.title)).toList() ??
      [];

  bool _matches(String text) =>
      text.toLowerCase().contains(query.toLowerCase());

  HomeState copyWith({
    String? city,
    HomeFeedKindEnum? kind,
    String? query,
    AsyncValue<HomeModel>? feed,
  }) => HomeState(
    city: city ?? this.city,
    kind: kind ?? this.kind,
    query: query ?? this.query,
    feed: feed ?? this.feed,
  );
}
