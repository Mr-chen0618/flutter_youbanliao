import '../../../../core/storage/mock_json_store.dart';
import '../repository/activity_invite_repository.dart';
import '../request-model/activity_invite_request_model.dart';

/// 沿用已有邀约文件，保留之前保存的对象与草稿。
class ActivityInviteMockRepository implements ActivityInviteRepository {
  const ActivityInviteMockRepository(this.store);
  final MockJsonStore store;

  static const _path = 'home/invites';

  static Map<String, dynamic> _object(Object? json) =>
      json as Map<String, dynamic>;

  static Set<String> _ids(Map<String, dynamic> json) =>
      Set<String>.from(json['ids'] as List);

  @override
  Future<Set<String>> invitedIds() =>
      store.read(_path, (json) => _ids(_object(json)));

  @override
  Future<void> submit(ActivityInviteRequestModel request) async {
    final draft = request.draft;
    if (draft == null) throw StateError('请填写邀约内容');
    {
      final catalog = await store.seed('home/catalog', _object);
      final person = (catalog['companions'] as List)
          .cast<Map<String, dynamic>>()
          .where((p) => p['id'] == request.companionId)
          .firstOrNull;
      if (person == null) throw StateError('用户不存在');
      final key =
          'invite-${request.companionId}-${draft.eventTime.toIso8601String()}-${draft.title}';
      // 消息先落盘；后续邀约写失败时，以相同key重试不会重复发送。
      await store.update('messages/inbox', _object, (json) {
        final threads = (json['threads'] as List)
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();
        final blocked = (json['blocked'] as Map? ?? {}).values;
        if (blocked.any(
          (p) =>
              p['peerId'] == request.companionId ||
              p['id'] == request.companionId ||
              (p['peerId'] == null &&
                  p['name'] == person['name'] &&
                  (catalog['companions'] as List)
                          .where((c) => c['name'] == person['name'])
                          .length ==
                      1),
        ))
          throw StateError('请先解除黑名单');
        var index = threads.indexWhere(
          (p) => p['peerId'] == request.companionId,
        );
        if (index < 0) {
          final legacy = threads
              .where((p) => p['peerId'] == null && p['name'] == person['name'])
              .toList();
          if (legacy.length == 1) index = threads.indexOf(legacy.single);
        }
        final thread = index < 0
            ? <String, dynamic>{
                'id': 'peer-${request.companionId}',
                'name': person['name'],
                'avatar': person['avatar'],
                'entries': [],
                'unread': 0,
              }
            : threads.removeAt(index);
        final entries = List<dynamic>.from(thread['entries'] as List? ?? []);
        if (!entries.any((e) => e['idempotencyKey'] == key))
          entries.add({
            'content': draft.title,
            'isMine': true,
            'kind': 'invitation',
            'showDelivery': true,
            'idempotencyKey': key,
            'invitation': {
              'title': draft.title,
              'description': draft.description,
              'category': draft.category,
              'date':
                  '${draft.eventTime.year}年${draft.eventTime.month}月${draft.eventTime.day}日',
              'time':
                  '${draft.eventTime.hour.toString().padLeft(2, '0')}:${draft.eventTime.minute.toString().padLeft(2, '0')}',
              'district': draft.location,
              'meetingPoint': draft.location,
            },
          });
        threads.insert(0, {
          ...thread,
          'peerId': request.companionId,
          'entries': entries,
          'time': '刚刚',
          'initialPreview': null,
        });
        return {...json, 'threads': threads};
      });
    }
    await store.update(
      _path,
      _object,
      (json) => {
        ...json,
        'ids': {..._ids(json), request.companionId}.toList(),
        'drafts': {
          ...?json['drafts'] as Map<String, dynamic>?,
          request.companionId: draft.toJson(),
        },
      },
    );
  }
}
