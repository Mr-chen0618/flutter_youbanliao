import '../model/video_show.dart';
import '../../../../core/storage/mock_json_store.dart';
import '../../../purchases/data/local/purchase_ledger_store.dart';

/// 账号增长记录；奖励与金币使用支付模块同一原子账本。
class GrowthRepository {
  GrowthRepository(this.store, this.ledger, this.accountId);
  final MockJsonStore store;
  final PurchaseLedgerStore ledger;
  final String accountId;
  String get path => 'accounts/$accountId/user/growth';
  Future<Map<String, dynamic>> load() async {
    if (accountId.isEmpty) throw StateError('请先登录');
    await store.initialize(path, {
      'checks': <String>[],
      'video': null,
      'realPerson': false,
      'identityPending': false,
    });
    return store.read(path, (v) => Map<String, dynamic>.from(v as Map));
  }

  /// 每次打开可为未签到账号预留弹层；历史展示日期不再阻止提醒。
  Future<bool> reserveAutomaticSignIn(DateTime now, String token) async {
    await load();
    final day = now.toIso8601String().substring(0, 10);
    var accepted = false;
    await store.update<Map<String, dynamic>>(
      path,
      (v) => Map<String, dynamic>.from(v as Map),
      (value) {
        if (!(value['checks'] as List? ?? []).contains(day)) {
          value['automaticSignInToken'] = token;
          accepted = true;
        }
        return value;
      },
    );
    return accepted;
  }

  Future<bool> confirmAutomaticSignIn(DateTime now, String token) async {
    var accepted = false;
    final day = now.toIso8601String().substring(0, 10);
    await store.update<Map<String, dynamic>>(
      path,
      (v) => Map<String, dynamic>.from(v as Map),
      (value) {
        if (value['automaticSignInToken'] == token &&
            !(value['checks'] as List? ?? []).contains(day)) {
          accepted = true;
        }
        return value;
      },
    );
    return accepted;
  }

  Future<void> releaseAutomaticSignIn(String token) =>
      store.update<Map<String, dynamic>>(
        path,
        (v) => Map<String, dynamic>.from(v as Map),
        (value) {
          if (value['automaticSignInToken'] == token) {
            value.remove('automaticSignInToken');
          }
          return value;
        },
      );
  Future<bool> claimAutomaticSignIn(DateTime now) async {
    final token = 'claim:${DateTime.now().microsecondsSinceEpoch}';
    if (!await reserveAutomaticSignIn(now, token)) return false;
    return confirmAutomaticSignIn(now, token);
  }

  Future<void> claimDaily(String task, DateTime now) async {
    if (!const ['chat', 'discover', 'publish'].contains(task)) {
      throw StateError('未知任务');
    }
    final day = now.toIso8601String().substring(0, 10);
    final state = await load();
    if (state['${task}Day'] != day) throw StateError('请先完成任务');
    await grantReward('daily:$task:$day', 10);
    await set('${task}Claim', day);
  }

  Future<void> recordChat() =>
      set('chatDay', DateTime.now().toIso8601String().substring(0, 10));
  Future<void> recordDiscovery() =>
      set('discoverDay', DateTime.now().toIso8601String().substring(0, 10));
  Future<void> recordPublish() =>
      set('publishDay', DateTime.now().toIso8601String().substring(0, 10));
  Future<void> saveVideo(String path) =>
      set('video', VideoShow(path: path).toJson());
  Future<void> deleteVideo() => set('video', null);
  Future<void> submitRealPerson() => set('realPerson', true);
  Future<void> submitIdentity() => set('identityPending', true);
  Future<void> set(String key, Object? value) async {
    await load();
    await store.update<Map<String, dynamic>>(
      path,
      (v) => Map<String, dynamic>.from(v as Map),
      (v) => v..[key] = value,
    );
  }

  /// key 必须包含业务事件/日期；同账户同环境最多发放一次。
  Future<void> grantReward(String key, int coins) => ledger.transaction((root) {
    if (accountId.isEmpty || coins <= 0) throw StateError('无效奖励');
    final accounts = root['accounts'] as Map;
    // 由支付模块初始化 token 和首次赠币，避免制造不完整的支付账号。
    final account = accounts[accountId] as Map?;
    if (account == null) throw StateError('请先加载金币账户');
    final environment = account['activeEnvironment'] as String;
    final rewards =
        account.putIfAbsent('growthRewards', () => <String, dynamic>{}) as Map;
    final id = '$environment:$key';
    if (rewards.containsKey(id)) return;
    final wallets = account['environments'] as Map;
    final wallet =
        wallets.putIfAbsent(
              environment,
              () => {'coins': 0, 'vipExpiresAt': null},
            )
            as Map;
    wallet['coins'] = (wallet['coins'] as int? ?? 0) + coins;
    rewards[id] = coins;
  });
  Future<void> checkIn(DateTime now) async {
    final day = now.toIso8601String().substring(0, 10);
    await load();
    await grantReward('check:$day', 1);
    await store.update<Map<String, dynamic>>(
      path,
      (v) => Map<String, dynamic>.from(v as Map),
      (v) {
        final checks = List<String>.from(v['checks'] as List? ?? []);
        if (!checks.contains(day)) checks.add(day);
        return v..['checks'] = checks;
      },
    );
  }
}
