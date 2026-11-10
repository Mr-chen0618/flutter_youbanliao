import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import '../../../../shared/widgets/feedback/app_action_sheet.dart';
import '../../../messages/presentation/providers/messages_provider.dart';
import '../../data/square_repository.dart';
import '../../../report/presentation/pages/report_page.dart';
import '../providers/square_provider.dart';
import 'square_post_card_widget.dart';
import '../pages/square_detail_page.dart';

SquarePostCardWidget buildSquarePostCard(
  BuildContext context,
  WidgetRef ref,
  SquareState state,
  SquarePost post, {
  bool isDetail = false,
  VoidCallback? onDetailComment,
}) {
  final notifier = ref.read(squareProvider.notifier);
  return SquarePostCardWidget(
    key: ValueKey(post.id),
    showMore: !isDetail,
    onDetail: isDetail
        ? null
        : () => AppNavigator.push(
            context,
            page: SquareDetailPage(postId: post.id),
          ),
    post: post,
    onProfile: post.authorId == null
        ? null
        : () => AppNavigator.pushNamed<void>(
            context,
            RouteNames.userDetail(post.authorId!),
            arguments: post.authorId!,
          ),
    onActivity: post.activityId == null
        ? null
        : () => AppNavigator.pushNamed<void>(
            context,
            RouteNames.activityDetail(post.activityId!),
            arguments: post.activityId!,
          ),
    isLiked: state.likes.contains(post.id),
    commentCount: post.commentCount + (state.comments[post.id]?.length ?? 0),
    onLike: () => notifier.toggleLike(post.id),
    onComment: isDetail
        ? onDetailComment
        : () => AppNavigator.push(
            context,
            page: SquareDetailPage(postId: post.id),
          ),
    onMore: () async {
      final confirmed = await showAppActionSheet<String>(
        context,
        actions: [
          const AppSheetAction(
            value: 'block',
            label: '拉黑',
            isDestructive: true,
          ),
          const AppSheetAction(value: 'report', label: '举报'),
        ],
      );
      if (!context.mounted || confirmed == null) return;
      if (confirmed == 'block') {
        ref
            .read(messagesProvider.notifier)
            .blockAuthor(
              post.authorId ?? post.author,
              post.author,
              post.avatar,
            );
        return;
      }
      if (confirmed == 'report') {
        AppNavigator.push(
          context,
          page: ReportPage(
            targetId: post.id,
            targetType: 'post',
            targetName: post.author,
          ),
        );
        return;
      }
    },
    onGreet: post.isMine
        ? null
        : () {
            final id = ref
                .read(messagesProvider.notifier)
                .greet(post.author, post.avatar);
            AppNavigator.pushNamed<void>(
              context,
              RouteNames.chat(id),
              arguments: id,
            );
          },
  );
}
