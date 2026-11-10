import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../providers/square_provider.dart';
import '../../../user/presentation/providers/profile_provider.dart';
import '../widgets/square_comment_tile.dart';
import '../widgets/square_post_actions_widget.dart';

/// 动态详情沿用设计中的动态卡片，并展示持久化评论。
class SquareDetailPage extends ConsumerStatefulWidget {
  const SquareDetailPage({super.key, required this.postId});
  final String postId;
  @override
  ConsumerState<SquareDetailPage> createState() => _SquareDetailPageState();
}

class _SquareDetailPageState extends ConsumerState<SquareDetailPage> {
  final _comment = TextEditingController();
  final _commentFocus = FocusNode();
  @override
  void dispose() {
    _commentFocus.dispose();
    _comment.dispose();
    super.dispose();
  }

  void _send() {
    if (_comment.text.trim().isEmpty) return;
    ref
        .read(squareProvider.notifier)
        .comment(
          widget.postId,
          _comment.text,
          profile: ref.read(userBlocProvider).state.profile,
        );
    _comment.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(squareProvider);
    final post = state.posts
        .where((item) => item.id == widget.postId)
        .firstOrNull;
    final actions = post == null
        ? null
        : buildSquarePostCard(
            context,
            ref,
            state,
            post,
            isDetail: true,
            onDetailComment: () => _commentFocus.requestFocus(),
          );
    return AppScaffold(
      navigatorTitle: '动态详情',
      navigatorColor: Colors.white,
      backgroundColor: Colors.white,
      navigatorBackWidget: const BackButton(),
      navigatorActionWidget: [
        if (actions != null)
          IconButton(
            tooltip: '更多操作',
            onPressed: actions.onMore,
            icon: const Icon(Icons.more_horiz),
          ),
      ],
      body: SafeArea(
        top: false,
        child: post == null
            ? const Center(child: Text('动态已删除'))
            : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: ref.read(squareProvider.notifier).refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(16.w),
                        children: [
                          actions!,
                          SizedBox(height: 16.h),
                          Text(
                            '评论  ${post.commentCount + (state.comments[post.id]?.length ?? 0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          for (final comment in state.comments[post.id] ?? [])
                            SquareCommentTile(comment: comment),
                          if ((state.comments[post.id] ?? []).isEmpty)
                            const ListTile(title: Text('还没有评论')),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 6.h,
                    ),
                    child: SizedBox(
                      height: 36.h,
                      child: TextField(
                        focusNode: _commentFocus,
                        controller: _comment,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: '说点什么…',
                          filled: true,
                          fillColor: const Color(0xFFF7F7F7),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          suffixIcon: IconButton(
                            tooltip: '发送评论',
                            onPressed: _send,
                            icon: const Icon(Icons.send_outlined, size: 18),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
