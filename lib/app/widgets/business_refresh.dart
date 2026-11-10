import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/messages/presentation/providers/messages_provider.dart';
import '../../features/user/presentation/providers/profile_provider.dart';
import '../../features/user/presentation/providers/user_detail_provider.dart';
import '../../features/activity/presentation/providers/activity_detail_provider.dart';
import '../../features/activity/presentation/providers/activity_reputation_provider.dart';
import '../../features/activity/presentation/providers/my_activities_provider.dart';
import '../../shared/widgets/feedback/app_toast.dart';

/// 业务列表刷新入口，失败使用统一提示，保留当前列表。
class BusinessRefresh extends ConsumerWidget {
  const BusinessRefresh({
    super.key,
    required this.scope,
    required this.child,
    this.id,
  });
  final String scope;
  final String? id;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    onRefresh: () async {
      try {
        switch (scope) {
          case 'messages':
            await ref.read(messagesProvider.notifier).reload();
          case 'profile':
            await ref.read(userBlocProvider).refresh();
          case 'user':
            ref.invalidate(userDetailProvider(id!));
            await ref.read(userDetailProvider(id!).future);
          case 'activity':
            ref.invalidate(activityDetailProvider(id!));
            await ref.read(activityDetailProvider(id!).future);
          case 'reputation':
            ref.invalidate(activityReputationProvider);
            await ref.read(activityReputationProvider.future);
          case 'teams':
            ref.invalidate(myActivitiesProvider);
            await ref.read(myActivitiesProvider(id == 'joined').future);
        }
      } catch (error) {
        AppToast.showError(error);
      }
    },
    child: child,
  );
}
