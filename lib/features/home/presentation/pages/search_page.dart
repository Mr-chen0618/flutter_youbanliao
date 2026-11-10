import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../providers/home_provider.dart';
import '../widgets/home_activity_card_widget.dart';
import '../widgets/home_companion_item_widget.dart';

/// 搜索当前城市的活动和搭子，并连接已有详情入口。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.initial = ''});
  final String initial;
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final _controller = TextEditingController(text: widget.initial);
  late String _query = widget.initial;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(homeProvider).feed.value;
    final query = _query.trim().toLowerCase();
    final people =
        feed?.companions
            .where(
              (person) =>
                  query.isNotEmpty &&
                  ('${person.name} ${person.city} ${person.interests.join(' ')}')
                      .toLowerCase()
                      .contains(query),
            )
            .toList() ??
        [];
    final events =
        feed?.activities
            .where(
              (event) =>
                  query.isNotEmpty &&
                  ('${event.title} ${event.category} ${event.location}')
                      .toLowerCase()
                      .contains(query),
            )
            .toList() ??
        [];
    return CompanionPageSurface(
      title: '搜索',
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: '搜索活动、用户',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _query = _controller.text),
                  child: const Text('搜索'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(homeProvider.notifier).loadHome(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  for (final person in people)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: HomeCompanionItemWidget(person: person),
                    ),
                  for (final event in events)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: HomeActivityCardWidget(
                        activity: event,
                        onTap: () => AppNavigator.pushNamed(
                          context,
                          RouteNames.activityDetail(event.id),
                          arguments: event.id,
                        ),
                      ),
                    ),
                  Center(
                    child: Text(
                      query.isEmpty ? '输入关键词搜索' : '已展示全部相关结果',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
