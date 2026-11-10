import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../constant/home_assets_constant.dart';
import '../constant/home_style_constant.dart';
import '../providers/companion_list_provider.dart';
import '../widgets/companion_category_chips_widget.dart';
import '../widgets/home_backdrop_widget.dart';
import '../widgets/home_companion_item_widget.dart';

class CompanionListPage extends ConsumerStatefulWidget {
  const CompanionListPage({super.key, required this.arguments});

  final CompanionListArguments arguments;

  @override
  ConsumerState<CompanionListPage> createState() => _CompanionListPageState();
}

class _CompanionListPageState extends ConsumerState<CompanionListPage> {
  final _selectedChip = GlobalKey();
  final _listController = ScrollController();
  bool _hasRevealedInitialCategory = false;

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        ref
            .read(companionListProvider(widget.arguments).notifier)
            .loadCompanions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = companionListProvider(widget.arguments);
    final state = ref.watch(provider);
    final model = ref.read(provider.notifier);
    final feed = state.feed.value;
    final people = state.visibleCompanions;
    ref.listen(provider, (_, next) {
      if (_hasRevealedInitialCategory || !next.feed.hasValue) return;
      _hasRevealedInitialCategory = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final chip = _selectedChip.currentContext;
        if (mounted && chip != null) Scrollable.ensureVisible(chip);
      });
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AppScaffold(
        isAppBar: false,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: HomeBackdropWidget(),
            ),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 48.h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: homeText('找搭子', 16, weight: FontWeight.w600),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: '返回',
                            onPressed: () => Navigator.maybePop(context),
                            icon: homeAsset(HomeAssets.companionBackIcon, 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (feed != null && feed.categories.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h, bottom: 12.h),
                      child: CompanionCategoryChipsWidget(
                        categories: feed.categories,
                        selectedId: state.categoryId,
                        selectedChip: _selectedChip,
                        onSelected: (id) {
                          if (id == state.categoryId) return;
                          model.changeCategory(id);
                          if (_listController.hasClients)
                            _listController.jumpTo(0);
                        },
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: model.loadCompanions,
                      child: CustomScrollView(
                        controller: _listController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          if (state.feed.hasError)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    homeText('加载失败，请重试', 15),
                                    TextButton(
                                      onPressed: model.loadCompanions,
                                      child: const Text('重试'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (state.feed.isLoading && feed == null)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: homeYellow,
                                ),
                              ),
                            )
                          else if (people.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(child: homeText('暂无该分类的搭子', 15)),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              sliver: SliverList.builder(
                                itemCount: people.length,
                                itemBuilder: (_, index) => Padding(
                                  padding: EdgeInsets.only(bottom: 8.h),
                                  child: HomeCompanionItemWidget(
                                    key: ValueKey(people[index].id),
                                    person: people[index],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
