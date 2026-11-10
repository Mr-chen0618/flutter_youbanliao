import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import '../../../activity/presentation/pages/activity_publish_page.dart';
import '../constant/home_assets_constant.dart';
import '../constant/home_style_constant.dart';
import '../enum/home_feed_kind_enum.dart';
import '../providers/home_provider.dart';
import '../widgets/home_activity_card_widget.dart';
import '../widgets/home_backdrop_widget.dart';
import '../widgets/home_category_strip_widget.dart';
import '../widgets/home_companion_item_widget.dart';
import '../widgets/home_feed_switch_widget.dart';
import '../widgets/home_header_widget.dart';
import 'search_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(homeProvider.notifier).loadHome();
    });
  }

  Future<void> _pickCity(BuildContext context, HomeNotifier model) async {
    final city = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final city in ['深圳', '广州', '上海'])
              ListTile(
                title: Text(city),
                onTap: () => Navigator.pop(context, city),
              ),
          ],
        ),
      ),
    );
    if (context.mounted && city != null) await model.changeCity(city);
  }

  Future<void> _search(
    BuildContext context,
    String query,
    HomeNotifier model,
  ) async {
    await AppNavigator.push(context, page: SearchPage(initial: query));
  }

  Future<void> _publish(BuildContext context, HomeNotifier model) async {
    final published = await AppNavigator.push<bool>(
      context,
      page: const ActivityPublishPage(),
    );
    if (!context.mounted || published != true) return;
    model.changeFeedKind(HomeFeedKindEnum.activities);
    await model.loadHome();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final model = ref.read(homeProvider.notifier);
    final feed = state.feed.value;
    final activities = state.kind == HomeFeedKindEnum.activities;
    final companions = state.visibleCompanions;
    final events = state.visibleActivities;
    final empty = activities ? events.isEmpty : companions.isEmpty;
    return Stack(
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: HomeBackdropWidget(),
        ),
        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: homeInk,
            onRefresh: model.loadHome,
            child: CustomScrollView(
              key: const PageStorageKey('home-feed'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: HomeHeaderWidget(
                    city: state.city,
                    query: state.query,
                    onCity: () => _pickCity(context, model),
                    onSearch: () => _search(context, state.query, model),
                  ),
                ),
                if (feed != null)
                  SliverToBoxAdapter(
                    child: HomeCategoryStripWidget(
                      categories: feed.categories,
                      onTap: (id) => AppNavigator.pushNamed<void>(
                        context,
                        RouteNames.companionList,
                        arguments: (city: state.city, categoryId: id),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: HomeFeedSwitchWidget(
                    selected: state.kind,
                    onChanged: model.changeFeedKind,
                  ),
                ),
                if (state.feed.isLoading && feed == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: homeYellow),
                    ),
                  )
                else if (state.feed.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          homeText('加载失败，请重试', 15),
                          TextButton(
                            onPressed: model.loadHome,
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (empty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: homeText(activities ? '暂无活动' : '暂无友伴', 15),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      12.w,
                      8.h,
                      12.w,
                      activities ? 62.h : 12.h,
                    ),
                    sliver: SliverList.builder(
                      itemCount: activities ? events.length : companions.length,
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: activities
                            ? HomeActivityCardWidget(
                                key: ValueKey(events[index].id),
                                activity: events[index],
                                onTap: () => AppNavigator.pushNamed<void>(
                                  context,
                                  RouteNames.activityDetail(events[index].id),
                                  arguments: events[index].id,
                                ),
                              )
                            : HomeCompanionItemWidget(
                                key: ValueKey(companions[index].id),
                                person: companions[index],
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (activities && feed != null)
          Positioned(
            right: 12.w,
            bottom: 12.h,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: homeYellow,
                foregroundColor: homeInk,
                side: const BorderSide(color: homeInk, width: 2),
              ),
              onPressed: () => _publish(context, model),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  homeAsset(HomeAssets.publishActivityIcon, 20),
                  SizedBox(width: 4.w),
                  homeText('发布活动', 14),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
