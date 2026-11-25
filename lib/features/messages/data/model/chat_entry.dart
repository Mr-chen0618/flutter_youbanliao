import '../enum/chat_entry_kind.dart';
import 'chat_invitation.dart';
import 'chat_gift.dart';

class ChatEntry {
  const ChatEntry(
    this.content, {
    this.isMine = false,
    this.kind = ChatEntryKind.text,
    this.continuesGroup = false,
    this.showDelivery = false,
    this.invitation,
    this.idempotencyKey,
    this.durationSeconds,
    this.gift,
    this.giftQuantity = 1,
  });
  final ChatGift? gift;
  final int giftQuantity;
  final String content;
  final String? idempotencyKey;
  final int? durationSeconds;
  final bool isMine;
  final ChatEntryKind kind;
  final bool continuesGroup;
  final bool showDelivery;
  final ChatInvitation? invitation;
  factory ChatEntry.fromJson(Map<String, dynamic> json) => ChatEntry(
    json['content'] as String,
    gift: json['gift'] == null
        ? null
        : ChatGift.fromJson(json['gift'] as Map<String, dynamic>),
    giftQuantity: json['giftQuantity'] as int? ?? 1,
    idempotencyKey: json['idempotencyKey'] as String?,
    durationSeconds: json['durationSeconds'] as int?,
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
    if (gift != null) 'gift': gift!.toJson(),
    if (gift != null) 'giftQuantity': giftQuantity,
    'idempotencyKey': idempotencyKey,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    'isMine': isMine,
    'continuesGroup': continuesGroup,
    'showDelivery': showDelivery,
    'kind': kind.name,
    'invitation': invitation?.toJson(),
  };
}
