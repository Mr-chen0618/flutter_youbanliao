import '../../../home/presentation/pages/companion_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import '../../../../core/storage/mock_json_store.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../../../shared/widgets/layout/app_empty_state.dart';
import '../../../activity/presentation/providers/activity_detail_provider.dart';
import '../../../messages/presentation/providers/messages_provider.dart';
import '../../data/model/home_companion_model.dart';
import '../providers/profile_provider.dart';

final _relationshipDirectoryProvider =
    FutureProvider.autoDispose<List<HomeCompanionModel>>(
      (ref) => ref
          .watch(mockJsonStoreProvider)
          .seed(
            'home/catalog',
            (json) => ((json as Map)['companions'] as List)
                .map(
                  (record) => HomeCompanionModel.fromJson(
                    record as Map<String, dynamic>,
                  ),
                )
                .toList(),
          ),
    );

/// 同一关系页切换关注、粉丝和好友，并遵循现有黑名单。
class ProfileRelationshipsPage extends ConsumerStatefulWidget {
  const ProfileRelationshipsPage({super.key, required this.initial});
  final int initial;
  @override
  ConsumerState<ProfileRelationshipsPage> createState() =>
      _ProfileRelationshipsPageState();
}

class _ProfileRelationshipsPageState
    extends ConsumerState<ProfileRelationshipsPage> {
  static const _labels = ['关注', '粉丝', '好友'];
  late int _selected = widget.initial;
  @override
  Widget build(BuildContext context) {
    final follow = ref.watch(followedActivityPublisherIdsProvider);
    final directory = ref.watch(_relationshipDirectoryProvider);
    final profile =
        (ref.watch(profileProvider).value ?? ref.read(userBlocProvider).state)
            .profile;
    final blocked = ref.watch(messagesProvider).blocked.values;
    final ids = switch (_selected) {
      0 => follow.value ?? const <String>{},
      1 => profile.followerIds.toSet(),
      _ => profile.friendIds.toSet(),
    };
    final people = (directory.value ?? const <HomeCompanionModel>[])
        .where(
          (person) =>
              ids.contains(person.id) &&
              !blocked.any(
                (item) =>
                    item.peerId == person.id ||
                    item.id == person.id ||
                    (item.peerId == null && item.name == person.name),
              ),
        )
        .toList();
    final loading = directory.isLoading || (_selected == 0 && follow.isLoading);
    final failed = directory.hasError || (_selected == 0 && follow.hasError);
    Future<void> refresh() async {
      try {
        await Future.wait([
          ref.refresh(_relationshipDirectoryProvider.future),
          if (_selected == 0)
            ref.refresh(followedActivityPublisherIdsProvider.future),
        ]);
      } catch (_) {
        // 刷新失败由对应关系页的错误状态展示。
      }
    }

    const background = Color(0xFFF8F8F8);
    return AppScaffold(
      navigatorTitle: people.isEmpty
          ? '关注'
          : '${_labels[_selected]} (${people.length})',
      navigatorBackWidget: const BackButton(),
      navigatorColor: background,
      backgroundColor: background,
      body: Column(
        children: [
          SizedBox(
            height: 48.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (index, label) in _labels.indexed)
                  Semantics(
                    selected: index == _selected,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: Size(62.w, 48.h),
                        padding: EdgeInsets.zero,
                        foregroundColor: index == _selected
                            ? const Color(0xFF333333)
                            : const Color(0xFF999999),
                        textStyle: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: index == _selected
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                      onPressed: () => setState(() => _selected = index),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label),
                          SizedBox(height: 3.h),
                          SizedBox(
                            width: 21.w,
                            height: 7.h,
                            child: index == _selected
                                ? const AppImage(
                                    src:
                                        'assets/profile/profile_relationship_tab_indicator.svg',
                                    fit: BoxFit.contain,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: loading && people.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: refresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (failed && people.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: TextButton(
                                onPressed: refresh,
                                child: const Text('加载失败，点击重试'),
                              ),
                            ),
                          )
                        else if (people.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Align(
                              alignment: const Alignment(0, -.44),
                              child: AppEmptyState(
                                message: const [
                                  '你还没有关注的人哦',
                                  '你还没有粉丝哦',
                                  '你还没有好友哦',
                                ][_selected],
                                action: FilledButton(
                                  style: FilledButton.styleFrom(
                                    fixedSize: Size(157.w, 40.h),
                                    padding: EdgeInsets.zero,
                                    backgroundColor: const Color(0xFFFFD152),
                                    foregroundColor: const Color(0xFF333333),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onPressed: () => AppNavigator.push<void>(
                                    context,
                                    page: CompanionListPage(
                                      arguments: (
                                        city: profile.city.isEmpty
                                            ? '深圳'
                                            : profile.city,
                                        categoryId: 'outdoors',
                                      ),
                                    ),
                                  ),
                                  child: const Text('找人聊聊'),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverList.builder(
                            itemCount: people.length,
                            itemBuilder: (_, index) =>
                                _RelationshipRow(person: people[index]),
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

/// 关系条目展示业务头像和城市、年龄，并沿用用户详情入口。
class _RelationshipRow extends StatelessWidget {
  const _RelationshipRow({required this.person});
  final HomeCompanionModel person;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => AppNavigator.pushNamed<void>(
      context,
      RouteNames.userDetail(person.id),
      arguments: person.id,
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: 72.h),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            AppImage(
              src: person.avatar,
              width: 48.r,
              height: 48.r,
              radius: 24.r,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    [
                      if (person.city.isNotEmpty) person.city,
                      if (person.age > 0) '${person.age}岁',
                      '找搭子',
                    ].join('｜'),
                    style: TextStyle(
                      color: const Color(0xFF999999),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
