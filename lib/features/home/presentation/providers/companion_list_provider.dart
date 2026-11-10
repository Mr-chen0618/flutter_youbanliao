import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/home_dependencies.dart';
import '../../data/model/home_model.dart';
import '../../data/request-model/home_list_request_model.dart';
import '../state/companion_list_state.dart';

typedef CompanionListArguments = ({String city, String categoryId});

final companionListProvider = NotifierProvider.autoDispose
    .family<CompanionListNotifier, CompanionListState, CompanionListArguments>(
      CompanionListNotifier.new,
    );

class CompanionListNotifier extends Notifier<CompanionListState> {
  CompanionListNotifier(this._arguments);

  final CompanionListArguments _arguments;
  int _request = 0;

  @override
  CompanionListState build() =>
      CompanionListState(categoryId: _arguments.categoryId);

  Future<void> loadCompanions() async {
    final currentRef = ref;
    final request = ++_request;
    if (!state.feed.hasValue) {
      state = state.copyWith(feed: const AsyncLoading());
    }
    final server = currentRef.read(homeServerProvider);
    final result = await AsyncValue.guard<HomeModel>(
      () => server.getHome(params: HomeListRequestModel(city: _arguments.city)),
    );
    if (currentRef.mounted && request == _request) {
      state = state.copyWith(feed: result);
    }
  }

  void changeCategory(String id) => state = state.copyWith(categoryId: id);
}
