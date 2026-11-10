import '../enum/chat_entry_kind.dart';
import 'chat_entry.dart';

class MessageThread {
  const MessageThread({
    required this.id,
    required this.name,
    required this.avatar,
    required this.entries,
    this.unread = 0,
    this.time = '12:12',
    this.chatAvatar,
    this.historyLabel,
    this.initialPreview,
    this.peerId,
  });

  final String id;
  final String? peerId;
  final String name;
  final String avatar;
  final List<ChatEntry> entries;
  final int unread;
  final String time;
  final String? chatAvatar;
  final String? historyLabel;
  final String? initialPreview;

  String get preview {
    if (initialPreview case final preview?) return preview;
    if (entries.isEmpty) return '打个招呼，开启聊天吧';
    final last = entries.last;
    return switch (last.kind) {
      ChatEntryKind.text => last.content,
      ChatEntryKind.photo => '[图片]',
      ChatEntryKind.invitation => '[活动邀约]',
    };
  }

  MessageThread copyWith({
    List<ChatEntry>? entries,
    int? unread,
    String? time,
  }) => MessageThread(
    id: id,
    peerId: peerId,
    name: name,
    avatar: avatar,
    entries: entries ?? this.entries,
    unread: unread ?? this.unread,
    time: time ?? this.time,
    chatAvatar: chatAvatar,
    historyLabel: historyLabel,
    initialPreview: entries == null ? initialPreview : null,
  );
  factory MessageThread.fromJson(Map<String, dynamic> json) => MessageThread(
    id: json['id'] as String,
    peerId: json['peerId'] as String?,
    name: json['name'] as String,
    avatar: json['avatar'] as String,
    entries: List.unmodifiable(
      (json['entries'] as List? ?? const []).map(
        (item) => ChatEntry.fromJson(item as Map<String, dynamic>),
      ),
    ),
    unread: json['unread'] as int? ?? 0,
    time: json['time'] as String? ?? '12:12',
    chatAvatar: json['chatAvatar'] as String?,
    historyLabel: json['historyLabel'] as String?,
    initialPreview: json['initialPreview'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'peerId': peerId,
    'name': name,
    'avatar': avatar,
    'entries': entries.map((item) => item.toJson()).toList(),
    'unread': unread,
    'time': time,
    'chatAvatar': chatAvatar,
    'historyLabel': historyLabel,
    'initialPreview': initialPreview,
  };
}
