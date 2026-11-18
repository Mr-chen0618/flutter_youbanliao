import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/images/app_image.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.voiceMode,
    required this.onToggleMode,
    required this.onSend,
    required this.onPhoto,
    required this.onVoiceCall,
    required this.onVideoCall,
    required this.onEmoji,
    required this.onRecordStart,
    required this.onRecordMove,
    required this.onRecordEnd,
    required this.onRecordCancel,
  });

  final TextEditingController controller;
  final bool voiceMode;
  final VoidCallback onToggleMode, onPhoto, onVoiceCall, onVideoCall, onEmoji;
  final ValueChanged<String> onSend;
  final ValueChanged<LongPressStartDetails> onRecordStart;
  final ValueChanged<LongPressMoveUpdateDetails> onRecordMove;
  final ValueChanged<LongPressEndDetails> onRecordEnd;
  final VoidCallback onRecordCancel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(10.w, 6.h, 16.w, 6.h),
    child: Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: voiceMode ? '切换到键盘' : '切换到语音',
              onPressed: onToggleMode,
              icon: voiceMode
                  ? const Icon(Icons.keyboard_alt_outlined)
                  : _asset('voice_mode'),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: voiceMode
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPressStart: onRecordStart,
                      onLongPressMoveUpdate: onRecordMove,
                      onLongPressEnd: onRecordEnd,
                      onLongPressCancel: onRecordCancel,
                      child: Container(
                        height: 45.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          color: const Color(0xFFF6F6F6),
                        ),
                        child: const Text('按住说话'),
                      ),
                    )
                  : TextField(
                      controller: controller,
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      textInputAction: TextInputAction.send,
                      onSubmitted: onSend,
                      decoration: InputDecoration(
                        hintText: '输入内容...',
                        hintStyle: const TextStyle(color: Color(0xFFACACAC)),
                        filled: true,
                        fillColor: const Color(0xFFF6F6F6),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: controller,
                          builder: (_, value, child) =>
                              value.text.trim().isEmpty
                              ? const SizedBox.shrink()
                              : TextButton(
                                  onPressed: () => onSend(value.text),
                                  child: const Text('发送'),
                                ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _action('photo', '添加图片', onPhoto),
            _action('voice_call', '语音通话', onVoiceCall),
            _action('video_call', '视频通话', onVideoCall),
            _action('emoji', '表情', onEmoji),
          ],
        ),
      ],
    ),
  );

  Widget _action(String glyph, String label, VoidCallback onPressed) =>
      IconButton(
        tooltip: label,
        icon: _asset(glyph, size: 28),
        onPressed: onPressed,
      );

  Widget _asset(String glyph, {double size = 24}) => AppImage(
    src: 'assets/messages/messages_chat_$glyph.svg',
    width: size.r,
    height: size.r,
    fit: BoxFit.contain,
  );
}

class ChatRecordingFeedback extends StatelessWidget {
  const ChatRecordingFeedback({super.key, required this.cancel});
  final bool cancel;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ColoredBox(
      color: Colors.black38,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: const Alignment(0, .32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 145.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    color: cancel
                        ? const Color(0xFFEF175B)
                        : const Color(0xFFFFD152),
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    size: 40.r,
                    color: cancel ? Colors.white : const Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  cancel ? '松手 取消发送' : '松手 发送，上滑取消',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: 112.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(240.w, 46.h),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF666666), Color(0xFF999999)],
                ),
              ),
              child: Icon(Icons.mic_rounded, size: 34.r),
            ),
          ),
        ],
      ),
    ),
  );
}
