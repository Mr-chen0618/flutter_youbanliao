import 'dart:async';

import 'package:dio/dio.dart';

import '../../logger/app_logger.dart';
import '../connectivity/network_monitor.dart';
import 'offline_queue_state.dart';
import 'offline_queue_storage.dart';
import 'offline_request.dart';

/// 离线队列管理器
class OfflineQueueManager {
  /// Dio
  final Dio dio;

  /// 网络监控
  final NetworkMonitor monitor;

  /// 离线队列存储
  final OfflineQueueStorage storage;

  /// 离线队列
  final _queue = <OfflineRequest>[];

  /// 死亡队列
  final _dead = <OfflineRequest>[];

  /// 状态控制器
  final _stateCtrl = StreamController<OfflineQueueState>.broadcast();

  /// 状态流
  Stream<OfflineQueueState> get stateStream => _stateCtrl.stream;

  /// 重放防抖定时器
  Timer? _replayDebounceTimer;

  /// 网络变化监听
  StreamSubscription? _netSub;

  /// 重放中
  bool _replaying = false;

  /// 最后重放时间

  /// 初始化
  OfflineQueueManager({
    required this.dio,
    required this.monitor,
    required this.storage,
  });

  /// 初始化
  Future<void> init() async {
    AppLogger.info('[Queue] manager init');
    _queue.addAll(await storage.loadQueue());
    _dead.addAll(await storage.loadDead());
    if (_stateCtrl.isClosed) return;
    _sort();
    _emit();

    // 监听网络变化：在线 debounce 后 replay；离线则取消 debounce
    _netSub = monitor.stream.listen((state) {
      AppLogger.info('[Queue] net change: ${state.internet}');

      if (state.isOffline) {
        _replayDebounceTimer?.cancel();
        return;
      }

      if (state.isOnline) {
        _replayDebounceTimer?.cancel();
        _replayDebounceTimer = Timer(const Duration(seconds: 2), () {
          if (monitor.current.isOnline) {
            replay();
          }
        });
      }
    });
  }

  /// 入队
  Future<void> enqueue(OfflineRequest req) async {
    if (_isDuplicate(req)) {
      AppLogger.info('[Queue] skip duplicate ${req.method} ${req.path}');
      return;
    }

    _queue.add(req);
    _sort();
    await storage.saveQueue(_queue);
    _emit();
  }

  /// 判断是否重复
  bool _isDuplicate(OfflineRequest req) {
    return _queue.any(
      (e) =>
          (req.idempotencyKey.isNotEmpty &&
              e.idempotencyKey == req.idempotencyKey) ||
          (e.method == req.method && e.path == req.path),
    );
  }

  /// 排序
  void _sort() {
    _queue.sort((a, b) {
      final p = a.priority.index.compareTo(b.priority.index);
      return p != 0 ? p : a.category.index.compareTo(b.category.index);
    });
  }

  /// 重放
  Future<void> replay() async {
    AppLogger.info(
      '[Queue] replay() pending=${_queue.length} replaying=$_replaying '
      'net=${monitor.current.internet}',
    );

    // 离线/unknown 不重放
    if (!monitor.current.isOnline) return;

    if (_replaying || _queue.isEmpty) return;

    _replaying = true;

    _emit();

    try {
      while (_queue.isNotEmpty && monitor.current.isOnline) {
        final req = _queue.first;

        try {
          await dio.request(
            req.path,
            data: req.body,
            queryParameters: req.query,
            options: Options(
              method: req.method,
              headers: req.headers,
              extra: const {
                'replay': true, //  避免 interceptor 再次入队
                'offline': false, //  明确不是离线入队请求
              },
            ),
          );

          /// 移除第一个请求
          _queue.removeAt(0);

          /// 保存队列
          await storage.saveQueue(_queue);

          /// 触发状态更新
          _emit();

          AppLogger.info(
            '[Queue] replay success ${req.method} ${req.path} '
            'left=${_queue.length}',
          );
        } catch (e) {
          AppLogger.error(
            '[Queue] replay fail ${req.method} ${req.path} err=$e',
          );

          /// 更新请求
          final updated = req.copyWith(retryCount: req.retryCount + 1);

          /// 移除第一个请求
          _queue.removeAt(0);

          /// 如果请求已死亡，则添加到死亡队列
          if (updated.isDead) {
            /// 添加到死亡队列
            _dead.add(updated);

            /// 保存死亡队列
            await storage.saveDead(_dead);
          } else {
            /// 添加到队列
            _queue.add(updated);

            /// 排序
            _sort();
          }

          /// 保存队列
          await storage.saveQueue(_queue);

          /// 触发状态更新
          _emit();

          // 失败就停，等待下一次联网/稳定后再重放
          break;
        }
      }
    } finally {
      /// 重放结束
      _replaying = false;

      /// 触发状态更新
      _emit();

      AppLogger.info('[Queue] replay end pending=${_queue.length}');
    }
  }

  /// 触发状态更新
  void _emit() {
    _stateCtrl.add(
      OfflineQueueState(
        pending: _queue.length,
        dead: _dead.length,
        replaying: _replaying,
      ),
    );
  }

  /// 释放资源
  void dispose() {
    _replayDebounceTimer?.cancel();
    _netSub?.cancel();
    _stateCtrl.close();
  }
}
