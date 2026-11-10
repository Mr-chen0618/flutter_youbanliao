import '../../../../core/storage/mock_json_store.dart';
import '../model/messages_state.dart';
import '../repository/messages_repository.dart';

class MessagesMockRepository implements MessagesRepository {
  const MessagesMockRepository(this.store);
  final MockJsonStore store;
  static const _path = 'messages/inbox';

  MessagesState _decode(Object? json) =>
      MessagesState.fromJson(json as Map<String, dynamic>);

  @override
  Future<MessagesState> load() => store.read(_path, _decode);

  @override
  Future<void> save(MessagesState data) => store.write(_path, data.toJson());
}
