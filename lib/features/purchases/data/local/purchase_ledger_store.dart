import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 支付专用账本，不使用会被账号 Mock 重置覆盖的样本文件。
/// 所有账号映射、交易和权益在同一份文件原子提交。
class PurchaseLedgerStore {
  PurchaseLedgerStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;
  Future<void> _queue = Future.value();

  Future<T> transaction<T>(T Function(Map<String, dynamic>) action) {
    final result = _queue.then((_) async {
      final directory = await _directory();
      final file = File('${directory.path}/purchases/apple_ledger.json');
      final Map<String, dynamic> ledger;
      if (await file.exists()) {
        // 损坏时停止发放，不静默重置，否则会丢失余额和重复发放。
        ledger = (jsonDecode(await file.readAsString()) as Map)
            .cast<String, dynamic>();
        if (ledger['version'] != 1 ||
            ledger['accounts'] is! Map ||
            ledger['transactions'] is! Map) {
          throw const FormatException('支付记录无法读取，请联系客服');
        }
      } else {
        ledger = {
          'version': 1,
          'accounts': <String, dynamic>{},
          'transactions': <String, dynamic>{},
        };
      }
      final value = action(ledger);
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(jsonEncode(ledger), flush: true);
      await temporary.rename(file.path);
      return value;
    });
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
