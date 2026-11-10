import '../enum/chat_entry_kind.dart';
import 'chat_invitation.dart';

class ChatEntry {
  const ChatEntry(
    this.content, {
    this.isMine = false,
    this.kind = ChatEntryKind.text,
    this.continuesGroup = false,
    this.showDelivery = false,
    this.invitation,
    this.idempotencyKey,
  });
  final String content;
  final String? idempotencyKey;
  final bool isMine;
  final ChatEntryKind kind;
  final bool continuesGroup;
  final bool showDelivery;
  final ChatInvitation? invitation;
  factory ChatEntry.fromJson(Map<String, dynamic> json) => ChatEntry(
    json['content'] as String,
    idempotencyKey: json['idempotencyKey'] as String?,
    isMine: json['isMine'] as bool? ?? false,
    continuesGroup: json['continuesGroup'] as bool? ?? false,
    showDelivery: json['showDelivery'] as bool? ?? false,
    kind: ChatEntryKind.values.asNameMap()[json['kind']] ?? ChatEntryKind.text,
    invitation: json['invitation'] == null
        ? null
        : ChatInvitation.fromJson(json['invitation'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'content': content,
    'idempotencyKey': idempotencyKey,
    'isMine': isMine,
    'continuesGroup': continuesGroup,
    'showDelivery': showDelivery,
    'kind': kind.name,
    'invitation': invitation?.toJson(),
  };
}
