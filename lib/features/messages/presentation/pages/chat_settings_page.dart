import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../user/presentation/providers/user_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/feedback/app_action_sheet.dart';
import '../../../activity/presentation/providers/activity_detail_provider.dart';
import '../../../report/presentation/pages/report_page.dart';
import '../providers/messages_provider.dart';

/// 会话设置复用关注、举报和黑名单的业务所有者；备注随会话保存。
class ChatSettingsPage extends ConsumerWidget {
  const ChatSettingsPage({super.key, required this.threadId});
  final String threadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thread = ref
        .watch(messagesProvider)
        .threads
        .where((t) => t.id == threadId)
        .firstOrNull;
    if (thread == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('聊天设置')),
        body: const Center(child: Text('当前会话不可用')),
      );
    }
    final peerId = thread.peerId;
    final person = peerId == null
        ? null
        : ref.watch(userDetailProvider(peerId)).value?.person;
    final following =
        peerId != null &&
        (ref
                .watch(followedActivityPublisherIdsProvider)
                .value
                ?.contains(peerId) ??
            false);
    void profile() {
      if (peerId != null) {
        AppNavigator.pushNamed(
          context,
          RouteNames.userDetail(peerId),
          arguments: peerId,
        );
      }
    }

    Widget divider() => Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
    );
    Widget group(List<Widget> rows) => Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) divider(),
            rows[i],
          ],
        ],
      ),
    );
    Widget row(String title, VoidCallback? action, {Widget? trailing}) =>
        InkWell(
          onTap: action,
          child: SizedBox(
            height: 53.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),
                  ?trailing,
                  SizedBox(width: 8.w),
                  Text(
                    '›',
                    style: TextStyle(
                      fontSize: 21.sp,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        toolbarHeight: 48.h,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '聊天设置',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        children: [
          group([
            InkWell(
              key: const ValueKey('chat-settings-profile'),
              onTap: peerId == null ? null : profile,
              child: SizedBox(
                height: 84.h,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      AppImage(
                        src: thread.avatar,
                        width: 56.r,
                        height: 56.r,
                        radius: 28.r,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thread.displayName,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF333333),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              person == null
                                  ? thread.name
                                  : '${person.age}岁｜${person.heightCm}cm｜${person.interests.take(1).join()}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF999999),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '›',
                        style: TextStyle(
                          fontSize: 21.sp,
                          color: const Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
          group([
            row('查看主页', peerId == null ? null : profile),
            row(
              '关注',
              peerId == null
                  ? null
                  : () async {
                      await ref
                          .read(activityDetailRepositoryProvider)
                          .follow(peerId, !following);
                      ref.invalidate(followedActivityPublisherIdsProvider);
                    },
              trailing: Container(
                width: 62.w,
                height: 30.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD14A),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Text(
                  following ? '已关注' : '+ 关注',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
            ),
            row(
              '设置备注',
              () async {
                final controller = TextEditingController(text: thread.remark);
                final result = await showDialog<String>(
                  context: context,
                  builder: (dialog) => AlertDialog(
                    title: const Text('设置备注'),
                    content: TextField(
                      controller: controller,
                      maxLength: 20,
                      autofocus: true,
                      decoration: const InputDecoration(hintText: '添加备注'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialog),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialog, controller.text),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                );
                // 弹窗退出动画结束后才释放仍在树中的输入控制器。
                await Future<void>.delayed(const Duration(milliseconds: 300));
                controller.dispose();
                if (result != null && ref.context.mounted) {
                  ref
                      .read(messagesProvider.notifier)
                      .setRemark(threadId, result);
                }
              },
              trailing: Text(
                thread.remark.isEmpty ? '添加' : thread.remark,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF999999),
                ),
              ),
            ),
          ]),
          group([
            row(
              '举报',
              () => AppNavigator.push(
                context,
                page: ReportPage(
                  targetId: peerId ?? thread.id,
                  targetType: 'chat',
                  targetName: thread.name,
                  targetAvatar: thread.avatar,
                  targetSummary: thread.preview,
                ),
              ),
            ),
            row('拉黑', () async {
              final confirmed = await showAppActionSheet<bool>(
                context,
                actions: const [
                  AppSheetAction(
                    value: true,
                    label: '确认加入黑名单',
                    isDestructive: true,
                  ),
                ],
              );
              if (confirmed == true && context.mounted) {
                ref.read(messagesProvider.notifier).block(thread);
                Navigator.pop(context);
              }
            }),
          ]),
        ],
      ),
    );
  }
}
