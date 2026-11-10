import '../model/messages_state.dart';

abstract interface class MessagesRepository {
  Future<MessagesState> load();
  Future<void> save(MessagesState data);
}
