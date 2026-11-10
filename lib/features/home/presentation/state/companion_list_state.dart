import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/model/home_model.dart';

class CompanionListState {
  const CompanionListState({
    required this.categoryId,
    this.feed = const AsyncLoading(),
  });

  final String categoryId;
  final AsyncValue<HomeModel> feed;

  List<HomeCompanionModel> get visibleCompanions =>
      feed.value?.companions
          .where((person) => person.categoryIds.contains(categoryId))
          .toList() ??
      [];

  CompanionListState copyWith({
    String? categoryId,
    AsyncValue<HomeModel>? feed,
  }) => CompanionListState(
    categoryId: categoryId ?? this.categoryId,
    feed: feed ?? this.feed,
  );
}
