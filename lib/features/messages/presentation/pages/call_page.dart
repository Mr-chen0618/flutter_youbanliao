import '../../../teen/presentation/teen_mode_provider.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../activity/presentation/providers/activity_detail_provider.dart';
import '../../../user/presentation/providers/profile_provider.dart';
import '../../../user/presentation/providers/user_detail_provider.dart';
import '../../data/messages_repository.dart';
import '../providers/messages_provider.dart';

/// 呼叫音边界，便于平台播放与会话生命周期独立验证。
abstract class CallRingback {
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}

class _PlayerRingback implements CallRingback {
  final _player = AudioPlayer();
  @override
  Future<void> start() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('messages/messages_call_ringback.wav'));
  }

  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> dispose() => _player.dispose();
}

final callRingbackFactoryProvider = Provider<CallRingback Function()>(
  (ref) =>
      () => _PlayerRingback(),
);

final _callSessionProvider = Provider<_CallSession>((ref) {
  final session = _CallSession(ref.read(callRingbackFactoryProvider));
  ref.listen(teenModeProvider, (_, next) {
    if (next.value != false) session.finish('青少年模式限制通话');
  });
  ref.onDispose(session.dispose);
  return session;
});

enum _CallPhase { preparing, dialing, incoming, connected, ended }

/// 大窗、小窗共享同一通话状态，避免返回时计时或话单丢失。
class _CallSession extends ChangeNotifier with WidgetsBindingObserver {
  _CallSession(this._createRingback) {
    WidgetsBinding.instance.addObserver(this);
  }
  final CallRingback Function() _createRingback;
  CallRingback? _ring;
  Future<void> _audioWork = Future<void>.value();
  bool _disposed = false, _foreground = true;

  /// 串行同步声音，快速取消不会留下迟到的播放请求。
  void _syncRing() {
    _audioWork = _audioWork.then((_) async {
      final active =
          !_disposed &&
          _foreground &&
          (phase == _CallPhase.dialing || phase == _CallPhase.incoming);
      try {
        if (active) {
          final player = _ring ??= _createRingback();
          await player.start();
          if (_disposed ||
              !_foreground ||
              phase == _CallPhase.ended ||
              phase == _CallPhase.connected) {
            await player.stop();
          }
        } else {
          await _ring?.stop();
          if (_disposed) await _ring?.dispose();
        }
      } catch (_) {
        // 声音不可用时保留呼叫和取消操作。
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncRing();
  }

  _CallPhase phase = _CallPhase.ended;
  Timer? _timer;
  OverlayEntry? overlay;
  String name = '', avatar = '', selfAvatar = '', peerId = '', threadId = '';
  bool video = false,
      incoming = false,
      camera = true,
      microphone = true,
      speaker = true;
  bool fullScreen = false;
  DateTime? _connectedAt;
  int get elapsed => _connectedAt == null
      ? 0
      : DateTime.now().difference(_connectedAt!).inSeconds;
  String get duration =>
      '${(elapsed ~/ 60).toString().padLeft(2, '0')}:${(elapsed % 60).toString().padLeft(2, '0')}';
  void Function(ChatEntry)? save;

  void begin({required bool incoming}) {
    this.incoming = incoming;
    phase = incoming ? _CallPhase.incoming : _CallPhase.preparing;
    camera = microphone = speaker = true;
    _connectedAt = null;
    _timer?.cancel();
    _syncRing();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (phase == _CallPhase.ended) return;
      phase = incoming ? _CallPhase.incoming : _CallPhase.dialing;
      _syncRing();
      notifyListeners();
      _timer = Timer(
        const Duration(seconds: 25),
        () => finish(incoming ? '无应答' : '对方无应答'),
      );
    });
  }

  void connect() {
    if (phase != _CallPhase.incoming && phase != _CallPhase.dialing) return;
    phase = _CallPhase.connected;
    _syncRing();
    _connectedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
    notifyListeners();
  }

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  void finish([String? reason]) {
    if (phase == _CallPhase.ended) return;
    final connected = phase == _CallPhase.connected;
    final entry = ChatEntry(
      reason ??
          (connected
              ? '通话时长$duration'
              : incoming
              ? '已拒绝'
              : '已取消'),
      isMine: !incoming,
      kind: video ? ChatEntryKind.videoCall : ChatEntryKind.voiceCall,
      durationSeconds: connected ? elapsed : null,
    );
    _timer?.cancel();
    phase = _CallPhase.ended;
    _syncRing();
    removeOverlay();
    final write = save;
    save = null;
    write?.call(entry);
    notifyListeners();
  }

  void removeOverlay() {
    overlay?.remove();
    overlay?.dispose();
    overlay = null;
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _syncRing();
    removeOverlay();
    super.dispose();
  }
}

/// 通话交互使用本地会话演示，电话记录跟随聊天保存。
class CallPage extends ConsumerStatefulWidget {
  const CallPage._(this._session, this._ownerContext);
  final _CallSession _session;
  final BuildContext _ownerContext;

  /// 私信、他人详情等入口通过对端 ID 显示同一通话流程。
  static Future<void> open(
    BuildContext context, {
    required String peerId,
    required String name,
    required String avatar,
    bool video = false,
    String? threadId,
    bool incoming = false,
  }) async {
    final container = ProviderScope.containerOf(context);
    final navigator = Navigator.of(context);
    // 首次读取是AsyncLoading，先等待设备设置，不能把未知误报为已开启。
    final bool teenEnabled;
    try {
      teenEnabled = await container.read(teenModeProvider.future);
    } catch (_) {
      if (context.mounted) AppToast.show('青少年模式设置读取失败，请稍后重试');
      return;
    }
    if (!context.mounted) return;
    if (teenEnabled) {
      AppToast.show('青少年模式下暂不可通话');
      return;
    }
    final session = container.read(_callSessionProvider);
    if (session.phase != _CallPhase.ended) {
      AppToast.show('正在通话中');
      return;
    }
    final messages = container.read(messagesProvider.notifier);
    if (messages.isBlocked(peerId) ||
        (threadId != null && messages.isBlocked(threadId))) {
      AppToast.show('对方已被你拉黑，无法拨打');
      return;
    }
    final peer = container.read(userDetailProvider(peerId)).value;
    if (peer?.blockedByPeer == true) {
      AppToast.show('你已被对方拉黑，无法拨打');
      return;
    }
    final id = threadId ?? messages.openConversation(peerId, name, avatar);
    if (id == null) return;
    session
      ..peerId = peerId
      ..threadId = id
      ..name = name
      ..avatar = avatar
      ..selfAvatar = container.read(userBlocProvider).state.profile.avatar
      ..video = video
      ..save = ((entry) => messages.send(id, entry))
      ..begin(incoming: incoming);
    if (!navigator.mounted) return;
    await _present(navigator.context, session);
  }

  static Future<void> _present(
    BuildContext context,
    _CallSession session,
  ) async {
    if (!context.mounted ||
        session.fullScreen ||
        session.phase == _CallPhase.ended) {
      return;
    }
    session.removeOverlay();
    session.fullScreen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'conversation-call'),
          builder: (_) => CallPage._(session, context),
        ),
      );
    } finally {
      session.fullScreen = false;
    }
  }

  @override
  ConsumerState<CallPage> createState() => _CallPageState();
}

class _CallPageState extends ConsumerState<CallPage> {
  _CallSession get session => widget._session;
  bool _confirming = false, _closing = false, _following = false;

  @override
  void initState() {
    super.initState();
    session.addListener(_changed);
  }

  @override
  void dispose() {
    session.removeListener(_changed);
    if (!_closing) session.finish();
    super.dispose();
  }

  void _changed() {
    if (session.phase == _CallPhase.ended && mounted && !_closing) {
      _closing = true;
      Navigator.of(context).pop();
    }
  }

  void _minimize() {
    final context = widget._ownerContext;
    if (!context.mounted) return;
    final overlay = Navigator.of(context).overlay;
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => ListenableBuilder(
        listenable: session,
        builder: (_, _) => Positioned(
          right: 8.w,
          top: MediaQuery.paddingOf(context).top + 48.h,
          child: Material(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(16.r),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => CallPage._present(context, session),
              child: SizedBox(
                width: 88.w,
                height: 108.h,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (session.video && session.avatar.isNotEmpty)
                      AppImage(src: session.avatar, fit: BoxFit.cover)
                    else
                      const Align(
                        alignment: Alignment(0, -.3),
                        child: Icon(
                          Icons.phone_in_talk_outlined,
                          color: Colors.white,
                        ),
                      ),
                    const ColoredBox(color: Color(0x44000000)),
                    Align(
                      alignment: const Alignment(0, .8),
                      child: Text(
                        session.phase == _CallPhase.connected
                            ? session.duration
                            : '待接通',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    session.overlay = entry;
    overlay.insert(entry);
    _closing = true;
    Navigator.pop(this.context);
  }

  Future<void> _end() async {
    if (_confirming || _closing) return;
    if (session.phase != _CallPhase.connected) {
      session.finish();
      return;
    }
    _confirming = true;
    final end = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确定要结束通话吗？', textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('结束通话'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFD152),
              foregroundColor: Colors.black87,
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续聊'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _confirming = false;
    if (end == true) session.finish();
  }

  void _toggleMicrophone() {
    session.update(() => session.microphone = !session.microphone);
    AppToast.show(session.microphone ? '麦克风已开启' : '麦克风已关闭');
  }

  void _toggleSpeaker() {
    session.update(() => session.speaker = !session.speaker);
    AppToast.show(session.speaker ? '免提已开启' : '免提已关闭');
  }

  Future<void> _toggleFollow(bool current) async {
    if (_following) return;
    _following = true;
    try {
      await ref
          .read(activityDetailRepositoryProvider)
          .follow(session.peerId, !current);
      if (mounted) ref.invalidate(followedActivityPublisherIdsProvider);
    } catch (_) {
      if (mounted) AppToast.show('操作失败，请重试');
    } finally {
      _following = false;
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_closing) _end();
    },
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF191919),
        body: ListenableBuilder(
          listenable: session,
          builder: (_, _) {
            final connected = session.phase == _CallPhase.connected;
            final incoming = session.phase == _CallPhase.incoming;
            final person = ref
                .watch(userDetailProvider(session.peerId))
                .value
                ?.person;
            final portrait = person?.photos.firstOrNull ?? session.avatar;
            final summary = [
              if (person != null && person.age > 0) '${person.age}岁',
              if (person != null && person.heightCm > 0) '${person.heightCm}cm',
              if (person != null && person.weightKg > 0) '${person.weightKg}kg',
            ].join(' | ');
            final followed =
                ref
                    .watch(followedActivityPublisherIdsProvider)
                    .value
                    ?.contains(session.peerId) ??
                false;
            return Stack(
              fit: StackFit.expand,
              children: [
                AppImage(
                  src: session.video
                      ? portrait
                      : 'assets/messages/messages_voice_call_background.png',
                  fit: BoxFit.cover,
                ),
                if (session.video)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x88000000),
                          Colors.transparent,
                          Color(0x66000000),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        child: Row(
                          children: [
                            if (!session.video || connected)
                              _iconButton(
                                'messages_call_minimize',
                                '切换小窗',
                                _minimize,
                              ),
                            if (session.video && !connected) ...[
                              AppImage(
                                src: session.avatar,
                                width: 44.r,
                                height: 44.r,
                                radius: 22.r,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  session.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              _iconButton(
                                'messages_call_minimize',
                                '切换小窗',
                                _minimize,
                              ),
                            ] else
                              Expanded(
                                child: Center(
                                  child: Text(
                                    connected ? session.duration : '',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            if (session.video && connected)
                              _iconButton('messages_video_end', '挂断', _end)
                            else if (!session.video)
                              SizedBox(width: 44.w),
                          ],
                        ),
                      ),
                      if (!session.video) ...[
                        SizedBox(height: 32.h),
                        AppImage(
                          src: session.avatar,
                          width: 143.r,
                          height: 143.r,
                          radius: 72.r,
                        ),
                        if (incoming || connected)
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD152),
                              foregroundColor: Colors.black87,
                            ),
                            onPressed: () => _toggleFollow(followed),
                            child: Text(followed ? '已关注' : '＋ 关注'),
                          )
                        else
                          SizedBox(height: 12.h),
                        Text(
                          session.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (connected && session.video)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 14.w, top: 12.h),
                            child: session.camera
                                ? AppImage(
                                    src: session.selfAvatar,
                                    width: 90.w,
                                    height: 118.h,
                                    radius: 12.r,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 90.w,
                                    height: 118.h,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF333333),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: const Icon(
                                      Icons.videocam_off_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      if (!session.video) ...[
                        _status(incoming, connected),
                        if (summary.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 20.h),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              'Ta的资料 · $summary',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                      ],
                      const Spacer(),
                      if (session.video && !connected)
                        _status(incoming, connected),
                      if (connected && session.video)
                        Padding(
                          padding: EdgeInsets.only(right: 12.w, bottom: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _iconButton(
                                'messages_video_speaker',
                                session.speaker ? '免提已开启' : '免提已关闭',
                                _toggleSpeaker,
                                enabled: session.speaker,
                              ),
                              _iconButton(
                                'messages_video_microphone',
                                session.microphone ? '麦克风已开启' : '麦克风已关闭',
                                _toggleMicrophone,
                                enabled: session.microphone,
                              ),
                              _iconButton(
                                'messages_video_camera',
                                session.camera ? '关闭摄像头' : '开启摄像头',
                                () => session.update(
                                  () => session.camera = !session.camera,
                                ),
                                enabled: session.camera,
                              ),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(bottom: 38.h, top: 14.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (connected)
                                _action(
                                  session.microphone
                                      ? 'messages_call_microphone_on'
                                      : 'messages_call_microphone_off',
                                  session.microphone ? '麦克风已开启' : '麦克风已关闭',
                                  _toggleMicrophone,
                                ),
                              _action('messages_call_hangup', '挂断', _end),
                              if (incoming)
                                _action(
                                  'messages_call_answer',
                                  '接听',
                                  session.connect,
                                ),
                              if (connected)
                                _action(
                                  session.speaker
                                      ? 'messages_call_speaker_on'
                                      : 'messages_call_speaker_off',
                                  session.speaker ? '免提已开启' : '免提已关闭',
                                  _toggleSpeaker,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _status(bool incoming, bool connected) => Padding(
    padding: EdgeInsets.only(top: 8.h),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (session.phase == _CallPhase.preparing)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
          ),
        Text(
          connected
              ? ''
              : incoming
              ? '对方邀请你进行${session.video ? '视频' : '语音'}通话…'
              : session.phase == _CallPhase.preparing
              ? '正在发起呼叫…'
              : '等待对方接受邀请…',
          style: TextStyle(color: Colors.white70, fontSize: 13.sp),
        ),
      ],
    ),
  );

  Widget _iconButton(
    String asset,
    String label,
    VoidCallback onPressed, {
    bool enabled = true,
  }) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    icon: Opacity(
      opacity: enabled ? 1 : .5,
      child: AppImage(
        src: 'assets/messages/$asset.svg',
        width: 32.r,
        height: 32.r,
        fit: BoxFit.contain,
      ),
    ),
  );

  Widget _action(String asset, String label, VoidCallback onTap) => Semantics(
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppImage(
            src: 'assets/messages/$asset.svg',
            width: 78.r,
            height: 78.r,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 5.h),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 11.sp),
          ),
        ],
      ),
    ),
  );
}
