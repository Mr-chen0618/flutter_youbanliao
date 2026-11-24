# 2026-11-19 聊天礼物验证

范围：礼物目录、扣款、幂等恢复、既有消息和Apple支付回归。实现见 [UI与数据决策](../ui-structure/chat-gifts-2026-11-19.md)。环境为本机Flutter测试和iOS无签名构建；没有执行模拟器或真机操作。

已完成：新增4项测试，覆盖8款名称/非空素材、扣款与消息快照JSON往返、账号及支付环境隔离、幂等请求、重启合并且不重复、余额不足和无效数量无修改、并发不能超扣。与消息、支付及应用smoke共39项通过。

命令：`flutter test --no-pub test/chat_gift_test.dart test/messages_conversation_test.dart test/apple_purchase_test.dart test/local_purchase_fulfillment_test.dart test/widget_test.dart`；证据 [tests.log](chat-gifts-2026-11-19/tests.log)。

静态检查：`flutter analyze --no-pub lib/features/messages test/chat_gift_test.dart`，见 [analyze.log](chat-gifts-2026-11-19/analyze.log)。iOS：`flutter build ios --release --no-codesign --no-pub`，见 [build-ios.log](chat-gifts-2026-11-19/build-ios.log)，构建成功，产物 `build/ios/iphoneos/Runner.app`。定向静态分析零问题。8张PNG另做SHA-256对照，与用户原文件逐字节一致。

未完成/未验证：真实远端礼物投递、对端收益服务未实现；设备视觉、键盘安全区、真实Apple充值后赠送未执行。历史支付测试通过不替代沙盒面板与支付验证。下一步按UI记录中的设备路径验收，再接服务端赠送事务与远端消息。

## 2026-11-19 默认金币增量

默认赠送10000，追加一次且消费后不补满。支付本地账本+礼物共17项通过，新增默认额度、旧账号保留余额和重启幂等断言；设备余额展示未验证。本轮仅执行Dart测试和定向分析，未重复iOS构建。证据 default-coins-tests.log / default-coins-analyze.log（本目录）。下一步更新设备应用后打开礼物面板确认。
