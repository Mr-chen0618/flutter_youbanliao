import '../../../user/presentation/providers/user_detail_provider.dart';
import 'chat_settings_page.dart';
import '../widgets/chat_gift_sheet.dart';
import '../../../../shared/widgets/layout/app_empty_state.dart';
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../app/widgets/business_refresh.dart';
import '../../../../core/media/app_media_picker.dart';
import '../../../../app/navigation/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../widgets/messages_page_surface.dart';
import '../../../user/presentation/providers/profile_provider.dart';
import '../../data/messages_repository.dart';
import '../providers/messages_provider.dart';
import '../widgets/chat_message_row.dart';
import '../widgets/chat_composer.dart';
import 'call_page.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.threadId});
  final String threadId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  AudioRecorder? _recorder;
  AudioPlayer? _player;
  Future<DateTime?>? _starting;
  bool _voiceMode = false;
  bool _holding = false;
  bool _cancelRecording = false;
  double _startY = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _holding) {
      unawaited(_finishRecording(cancel: true));
    }
    if (state != AppLifecycleState.resumed) {
      final player = _player;
      if (player != null) unawaited(player.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _input.dispose();
    _holding = false;
    final recorder = _recorder;
    if (recorder != null) unawaited(_disposeRecorder(recorder));
    final player = _player;
    if (player != null) unawaited(player.dispose());
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
      return const MessagesPageSurface(
        title: '聊天',
        child: Center(child: Text('当前会话不可用')),
      );
    }
    final myAvatar =
        (ref.watch(profileProvider).value ?? ref.read(userBlocProvider).state)
            .profile
            .avatar;
    return MessagesPageSurface(
      title: thread.displayName,
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
          tooltip: '热聊值',
          iconSize: 40.r,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          icon: SizedBox(
            width: 40.r,
            height: 40.r,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                  child: AppImage(
                    src: 'assets/messages/messages_chat_heat.png',
                    width: 24.r,
                    height: 24.r,
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  '${thread.heat}°C',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10.sp,
                    height: 1.1,
                    color: const Color(0xFFFF6B54),
                  ),
                ),
              ],
            ),
          ),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialog) => AlertDialog(
              title: const Text('热聊值'),
              content: Text('当前热聊值 ${thread.heat}°C\n每发送一条消息或赠送一次礼物，热聊值增加1度。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialog),
                  child: const Text('知道了'),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: '更多操作',
          icon: _icon('more'),
          onPressed: () => _showActions(thread),
        ),
      ],
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xB3FFFFFF),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Text(
                  '⚠ 聊天时请保护个人信息，谨慎转账；遇到可疑行为，请及时举报或拉黑。',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF958B6D),
                    fontSize: 12.sp,
                  ),
                ),
              ),
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
                        if (thread.peerId != null) {
                          return _profileCard(thread.peerId!);
                        }
                        if (thread.entries.isEmpty) {
                          return const AppEmptyState(
                            message: '暂无聊天记录',
                            compact: true,
                          );
                        }
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
                        onPlayVoice: entry.kind == ChatEntryKind.voice
                            ? () => _playVoice(entry.content)
                            : null,
                        avatar: entry.isMine
                            ? myAvatar
                            : thread.chatAvatar ?? thread.avatar,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 32.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  children: [
                    for (final text in [
                      '嗨，聊聊？',
                      '你在哪儿？',
                      '兴趣是啥？',
                      '周末有空吗？',
                      '一起搭子？',
                    ])
                      Padding(
                        padding: EdgeInsets.only(right: 6.w),
                        child: ActionChip(
                          label: Text(text),
                          onPressed: () => _sendText(text),
                        ),
                      ),
                  ],
                ),
              ),
              ChatComposer(
                controller: _input,
                voiceMode: _voiceMode,
                onToggleMode: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() => _voiceMode = !_voiceMode);
                },
                onSend: _sendText,
                onPhoto: _choosePhoto,
                onVoiceCall: () => _call(thread, video: false),
                onVideoCall: () => _call(thread, video: true),
                onEmoji: _chooseEmoji,
                onGift: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: const Color(0xFF232323),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20.r),
                      ),
                    ),
                    builder: (_) =>
                        ChatGiftSheet(threadId: widget.threadId, onSent: _send),
                  );
                },
                onRecordStart: _startRecording,
                onRecordMove: (details) {
                  final cancel = details.globalPosition.dy < _startY - 52.h;
                  if (_holding && cancel != _cancelRecording) {
                    setState(() => _cancelRecording = cancel);
                  }
                },
                onRecordEnd: (_) => _finishRecording(cancel: _cancelRecording),
                onRecordCancel: () => _finishRecording(cancel: true),
              ),
            ],
          ),
          if (_holding) ChatRecordingFeedback(cancel: _cancelRecording),
        ],
      ),
    );
  }

  Widget _profileCard(String peerId) {
    final detail = ref.watch(userDetailProvider(peerId)).value;
    if (detail == null) return const SizedBox.shrink();
    final person = detail.person;
    final photos = person.photos.isEmpty ? [person.avatar] : person.photos;
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(
            key: const ValueKey('chat-profile-avatar'),
            src: person.avatar,
            width: 40.r,
            height: 40.r,
            radius: 20.r,
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Container(
              key: const ValueKey('chat-profile-card'),
              width: 265.w,
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAF0),
                border: Border.all(color: const Color(0xFFFFDDA3)),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        AppImage(
                          src: photos.first,
                          width: 245.w,
                          height: 308.h,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(10.w),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (person.isVerified)
                                Container(
                                  key: const ValueKey(
                                    'chat-profile-real-person-badge',
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD6F3FF),
                                    borderRadius: BorderRadius.circular(19.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AppImage(
                                        src:
                                            'assets/messages/messages_chat_real_person.svg',
                                        width: 12.r,
                                        height: 12.r,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        '真人',
                                        style: TextStyle(
                                          color: const Color(0xFF007BFF),
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: 4.h),
                              Text(
                                '${person.age}岁  ${person.heightCm}cm  ${person.weightKg}kg\n${detail.signature}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Text('Ta的相册：', style: TextStyle(fontSize: 12.sp)),
                  ),
                  Row(
                    children: [
                      for (final photo in photos.take(4))
                        Padding(
                          padding: EdgeInsets.only(right: 5.w),
                          child: AppImage(
                            src: photo,
                            width: 55.w,
                            height: 73.h,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
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

  Future<void> _call(MessageThread thread, {required bool video}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await CallPage.open(
      context,
      peerId: thread.peerId ?? thread.id,
      name: thread.name,
      avatar: thread.chatAvatar ?? thread.avatar,
      video: video,
      threadId: thread.id,
    );
  }

  Future<void> _chooseEmoji() async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Wrap(
            children: [
              for (final emoji in [
                '😀',
                '😂',
                '🥰',
                '👏',
                '👍',
                '❤️',
                '🎉',
                '🤝',
              ])
                TextButton(
                  onPressed: () => Navigator.pop(sheet, emoji),
                  child: Text(emoji, style: TextStyle(fontSize: 22.sp)),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || emoji == null) return;
    final cursor = _input.selection.isValid
        ? _input.selection
        : TextSelection.collapsed(offset: _input.text.length);
    final text = _input.text.replaceRange(cursor.start, cursor.end, emoji);
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor.start + emoji.length),
    );
    setState(() => _voiceMode = false);
  }

  void _startRecording(LongPressStartDetails details) {
    if (_starting != null) return;
    _startY = details.globalPosition.dy;
    setState(() {
      _holding = true;
      _cancelRecording = false;
    });
    final recorder = _recorder ??= AudioRecorder();
    final accountId = ref.read(userBlocProvider).state.profile.id;
    _starting = _beginRecording(recorder, accountId);
  }

  Future<DateTime?> _beginRecording(
    AudioRecorder recorder,
    String accountId,
  ) async {
    try {
      if (!await recorder.hasPermission()) {
        if (mounted) AppToast.show('请开启麦克风权限');
        return null;
      }
      if (!_holding || !mounted) return null;
      final root = await getApplicationSupportDirectory();
      final key = Uri.encodeComponent('account-$accountId');
      final folder = await Directory(
        '${root.path}/chat-voice/$key',
      ).create(recursive: true);
      if (!_holding || !mounted) return null;
      final path =
          '${folder.path}/${DateTime.now().microsecondsSinceEpoch}.m4a';
      await _player?.stop();
      if (!_holding || !mounted) return null;
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      return DateTime.now();
    } catch (_) {
      if (mounted) AppToast.show('暂时无法录音，请重试');
      return null;
    }
  }

  Future<void> _finishRecording({required bool cancel}) async {
    if (!_holding) return;
    final releasedAt = DateTime.now();
    setState(() => _holding = false);
    try {
      final startedAt = await _starting;
      final recorder = _recorder;
      if (startedAt == null || recorder == null || !mounted) return;
      final seconds = releasedAt.difference(startedAt).inSeconds;
      if (cancel || seconds < 1) {
        await recorder.cancel();
        if (!cancel && mounted) AppToast.show('说话时间太短');
        return;
      }
      final path = await recorder.stop();
      if (path == null) return;
      if (!mounted ||
          !ref
              .read(messagesProvider)
              .threads
              .any((thread) => thread.id == widget.threadId)) {
        await File(path).delete();
        return;
      }
      _send(
        ChatEntry(
          path,
          isMine: true,
          kind: ChatEntryKind.voice,
          durationSeconds: seconds,
          showDelivery: true,
        ),
      );
    } catch (_) {
      if (mounted) AppToast.show('录音保存失败，请重试');
    } finally {
      _starting = null;
    }
  }

  Future<void> _disposeRecorder(AudioRecorder recorder) async {
    await _starting;
    try {
      if (await recorder.isRecording()) await recorder.cancel();
    } finally {
      await recorder.dispose();
    }
  }

  Future<void> _playVoice(String path) async {
    try {
      final player = _player ??= AudioPlayer();
      if (player.state == PlayerState.playing) {
        await player.stop();
        return;
      }
      if (!await File(path).exists()) {
        if (mounted) AppToast.show('语音文件已失效');
        return;
      }
      if (mounted) await player.play(DeviceFileSource(path));
    } catch (_) {
      if (mounted) AppToast.show('语音播放失败');
    }
  }

  Future<void> _showActions(MessageThread thread) async {
    await AppNavigator.push(
      context,
      page: ChatSettingsPage(threadId: thread.id),
    );
    if (mounted &&
        !ref.read(messagesProvider).threads.any((t) => t.id == thread.id)) {
      Navigator.pop(context);
    }
  }
}
