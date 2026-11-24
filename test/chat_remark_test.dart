import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_framework/features/messages/data/model/message_thread.dart';

void main() {
  test('备注兼容旧记录、清空及消息更新后持久化', () {
    final old = MessageThread.fromJson({
      'id': 'peer-1',
      'name': '原昵称',
      'avatar': '',
      'entries': [],
    });
    expect(old.displayName, '原昵称');
    final renamed = old.copyWith(remark: '好友备注');
    final restored = MessageThread.fromJson(
      renamed.copyWith(unread: 0).toJson(),
    );
    expect(restored.displayName, '好友备注');
    expect(restored.name, '原昵称');
    expect(restored.copyWith(remark: '').displayName, '原昵称');
  });
}
