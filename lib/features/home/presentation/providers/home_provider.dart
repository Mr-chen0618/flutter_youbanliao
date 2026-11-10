import '../../../../shared/widgets/feedback/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/home_dependencies.dart';
import '../../data/model/home_model.dart';
import '../../data/request-model/home_list_request_model.dart';
import '../enum/home_feed_kind_enum.dart';
import '../state/home_state.dart';

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);

class HomeNotifier extends Notifier<HomeState> {
  int _request = 0;

  @override
  HomeState build() => const HomeState();

  Future<void> loadHome() async {
    final currentRef = ref;
    final request = ++_request;
    final params = HomeListRequestModel(city: state.city);
    if (!state.feed.hasValue) {
      state = state.copyWith(feed: const AsyncLoading());
    }
    final server = currentRef.read(homeServerProvider);
    final result = await AsyncValue.guard<HomeModel>(
      () => server.getHome(params: params),
    );
    // A slower response for a previously selected city must not replace this feed.
    if (currentRef.mounted && request == _request) {
      if (result.hasError && state.feed.hasValue) {
        AppToast.showError(result.error!);
      } else {
        state = state.copyWith(feed: result);
      }
    }
  }

  Future<void> changeCity(String city) async {
    if (city == state.city) return;
    state = state.copyWith(city: city, feed: const AsyncLoading());
    await loadHome();
  }

  void changeFeedKind(HomeFeedKindEnum kind) =>
      state = state.copyWith(kind: kind);
  void searchHome(String query) => state = state.copyWith(query: query.trim());
}
