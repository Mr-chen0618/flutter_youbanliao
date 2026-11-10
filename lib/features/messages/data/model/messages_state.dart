import '../enum/message_notice.dart';
import 'message_thread.dart';
import 'message_report.dart';

class MessagesState {
  const MessagesState(
    this.threads, {
    this.readNotices = const {},
    this.blocked = const {},
    this.notices = const {},
    this.noticeUnread = const {},
    this.reports = const [],
  });
  final List<MessageThread> threads;
  final Map<String, String> notices;
  final Map<String, int> noticeUnread;
  final List<MessageReport> reports;
  final Set<MessageNotice> readNotices;
  final Map<String, MessageThread> blocked;

  MessagesState copyWith({
    List<MessageThread>? threads,
    Set<MessageNotice>? readNotices,
    Map<String, MessageThread>? blocked,
    List<MessageReport>? reports,
    Map<String, int>? noticeUnread,
  }) => MessagesState(
    threads ?? this.threads,
    readNotices: readNotices ?? this.readNotices,
    blocked: blocked ?? this.blocked,
    notices: notices,
    noticeUnread: noticeUnread ?? this.noticeUnread,
    reports: reports ?? this.reports,
  );
  factory MessagesState.fromJson(Map<String, dynamic> json) => MessagesState(
    List.unmodifiable(
      (json['threads'] as List).map(
        (item) => MessageThread.fromJson(item as Map<String, dynamic>),
      ),
    ),
    noticeUnread: Map<String, int>.unmodifiable(
      (json['noticeUnread'] as Map? ?? const {}).map(
        (key, value) => MapEntry(key as String, value as int),
      ),
    ),
    readNotices: Set.unmodifiable(
      MessageNotice.values.where(
        (notice) =>
            (json['readNotices'] as List? ?? const []).contains(notice.name),
      ),
    ),
    blocked: Map.unmodifiable(
      (json['blocked'] as Map? ?? const {}).map(
        (key, value) => MapEntry(
          key as String,
          MessageThread.fromJson(value as Map<String, dynamic>),
        ),
      ),
    ),
    reports: List.unmodifiable(
      (json['reports'] as List? ?? const []).map(
        (item) => (
          threadId: item['threadId'] as String,
          reason: item['reason'] as String,
          submittedAt: item['submittedAt'] as String,
        ),
      ),
    ),
    notices: Map.unmodifiable(
      Map<String, String>.from(json['notices'] as Map? ?? const {}),
    ),
  );

  Map<String, dynamic> toJson() => {
    'threads': threads.map((thread) => thread.toJson()).toList(),
    'readNotices': readNotices.map((notice) => notice.name).toList(),
    'blocked': blocked.map((id, thread) => MapEntry(id, thread.toJson())),
    'notices': notices,
    'noticeUnread': noticeUnread,
    'reports': reports
        .map(
          (item) => {
            'threadId': item.threadId,
            'reason': item.reason,
            'submittedAt': item.submittedAt,
          },
        )
        .toList(),
  };
}
