import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../app/widgets/business_refresh.dart';
import '../../../../core/media/app_media_picker.dart';
import '../../../../app/navigation/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/feedback/app_action_sheet.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../../../user/presentation/providers/profile_provider.dart';
import '../../data/messages_repository.dart';
import '../../../report/presentation/pages/report_page.dart';
import '../providers/messages_provider.dart';
import '../widgets/chat_message_row.dart';

enum _ChatAction { block, report }

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.threadId});
  final String threadId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(ChatEntry entry) {
    if (entry.content.trim().isEmpty) return;
    ref.read(messagesProvider.notifier).send(widget.threadId, entry);
    if (entry.kind == ChatEntryKind.text) _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref
        .watch(messagesProvider)
        .threads
        .where((item) => item.id == widget.threadId)
        .firstOrNull;
    if (thread == null) {
      return const CompanionPageSurface(
        title: '聊天',
        child: Center(child: Text('当前会话不可用')),
      );
    }
    final myAvatar =
        (ref.watch(profileProvider).value ?? ref.read(userBlocProvider).state)
            .profile
            .avatar;
    return CompanionPageSurface(
      title: thread.name,
      titleStyle: TextStyle(
        color: const Color(0xFF333333),
        fontSize: 17.sp,
        fontWeight: FontWeight.w600,
      ),
      backButton: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.maybePop(context),
        icon: _icon('back'),
      ),
      actions: [
        IconButton(
          tooltip: '更多操作',
          icon: _icon('more'),
          onPressed: () => _showActions(thread),
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: BusinessRefresh(
              scope: 'messages',
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
                itemCount: thread.entries.length + 1,
                itemBuilder: (_, index) {
                  if (index == 0) {
                    return thread.historyLabel == null
                        ? const SizedBox.shrink()
                        : Center(
                            child: Text(
                              thread.historyLabel!,
                              style: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: 11.sp,
                              ),
                            ),
                          );
                  }
                  final entry = thread.entries[index - 1];
                  return ChatMessageRow(
                    entry: entry,
                    avatar: entry.isMine
                        ? myAvatar
                        : thread.chatAvatar ?? thread.avatar,
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFECEDEF)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              children: [
                IconButton(
                  tooltip: '添加图片',
                  constraints: BoxConstraints(minWidth: 24.w, minHeight: 42.h),
                  padding: EdgeInsets.zero,
                  onPressed: _choosePhoto,
                  icon: _icon('image'),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendText,
                    style: TextStyle(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: '输入消息…',
                      hintStyle: const TextStyle(color: Color(0xFF999999)),
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      isDense: true,
                      constraints: BoxConstraints(minHeight: 42.h),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: Size(64.w, 42.h),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    backgroundColor: const Color(0xFFFFD152),
                    foregroundColor: const Color(0xFF333333),
                  ),
                  onPressed: () => _sendText(_input.text),
                  child: const Text('发送'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _icon(String name) => AppImage(
    src: messagesAsset('chat_${name}_icon'),
    width: 24.r,
    height: 24.r,
    fit: BoxFit.contain,
  );

  void _sendText(String text) => _send(ChatEntry(text.trim(), isMine: true));

  Future<void> _choosePhoto() async {
    final photo = await AppMediaPicker.pickImage();
    if (!mounted || photo == null) return;
    _send(
      ChatEntry(
        photo,
        isMine: true,
        kind: ChatEntryKind.photo,
        showDelivery: true,
      ),
    );
  }

  Future<void> _showActions(MessageThread thread) async {
    final action = await showAppActionSheet<_ChatAction>(
      context,
      actions: const [
        AppSheetAction(
          value: _ChatAction.block,
          label: '拉黑',
          isDestructive: true,
        ),
        AppSheetAction(value: _ChatAction.report, label: '举报'),
      ],
    );
    if (!mounted || action == null) return;
    await _handleAction(thread, action);
  }

  Future<void> _handleAction(MessageThread thread, _ChatAction action) async {
    if (action == _ChatAction.report) {
      await AppNavigator.push(
        context,
        page: ReportPage(
          targetId: thread.id,
          targetType: 'chat',
          targetName: thread.name,
        ),
      );
      return;
    }
    final options = action == _ChatAction.block
        ? ['确认加入黑名单']
        : ['垃圾广告', '骚扰辱骂', '不当内容', '其他'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              ListTile(
                title: Text(option),
                onTap: () => Navigator.pop(sheet, option),
              ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    if (action == _ChatAction.block) {
      ref.read(messagesProvider.notifier).block(thread);
      Navigator.pop(context);
    } else {
      ref.read(messagesProvider.notifier).report(thread.id, selected);
      AppToast.show('举报已提交');
    }
  }
}
