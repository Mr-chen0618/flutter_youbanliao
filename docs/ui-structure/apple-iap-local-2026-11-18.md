# 2026-11-18 苹果本机支付实现

## 范围和决策

用户明确选择不接业务后端，并授权实现前端，本记录覆盖 [上轮客户端](apple-iap-2026-11-18.md) 中“后端未配置所以禁用购买”的默认约定。六个商品与价格查询、原页面结构不变；当前默认 iOS 使用本机验证和本地权益账本，登录且 Apple 商品可用时允许购买。无需 .p8、Issuer ID、Key ID；仍需正确的 App 签名、Bundle ID 和 App Store Connect 商品配置。

## 已实现

- `ios/Runner/AppDelegate.swift`：随 Scene 引擎注册 `youbanliao/apple_purchase_verification` 桥接。以交易 ID 查询 StoreKit 2 unfinished/all；仅在 `.verified` 后检查 productId、Consumable 类型、数量 1、未撤销、appAccountToken 和签名数据的 bundle/environment。未验证或找不到交易返回失败，不发放。`unsafePayloadValue` 只用于查找 ID，不能绕过后面的 verified 判断。
- `purchases/data/server/local_apple_transaction_verifier.dart`：调用上述原生桥接，返回本机验证后的交易；Dart 的 purchased 状态、解码 JSON 或手写本地成功标志不能发放。
- `purchases/data/local/purchase_ledger_store.dart`：应用支持目录 `purchases/apple_ledger.json`，串行修改、临时文件 flush 后 rename；账本损坏时停止，不静默重置。账号映射、权益和交易记录一起提交，不使用 Mock 样本/账号快照文件。
- `purchases/data/repository/local_purchase_fulfillment_repository.dart`：每个账号持久化随机 UUID v4，按验证后的 token 查归属，不将未知历史 token 绑定给当前登录账号。按 environment+transactionId 去重并原子发放六个白名单商品。保存成功后控制器才允许 finish，失败可补单。
- `purchases/presentation/providers/apple_purchase_provider.dart`：iOS 默认注入本地实现，其他平台维持不可购买；现有后端扩展契约仍保留。
- 控制器内存缓存区分签名交易内容；迟到回调只更新原账号并提示“购买已保存至原账号”。账本分 Production/Sandbox/Xcode 存余额，活动环境采用最近发放环境，不相互累加。页面测试环境的金币和会员标题标“测试”。

复用：Riverpod 账号与状态流、现有购买网关和应用级监听/启动补单、原页面 ShopHero/OptionTile/Footer、AppImage/AppToast、path_provider 应用支持目录。未新增依赖。原 MockJsonStore 带样本初始化语义和账号清理约定，不用于付费账本；新 store 只负责支付文件。

## 数据与会员规则

账本 version=1，包含 accounts（稳定账号ID→token/activeEnvironment/environments）及 transactions（environment:transactionId→账号、商品、购买及发放时间、金币或月数）。没有预置付费余额，不复制种子。只保存本地发放所需字段，不保存 Apple 密钥或完整交易 JWS。事务和钱包同次写入，重复购买同一商品使用新的交易号可再次发放，同一交易重放不增加权益。

会员从 max(本机当前 UTC 时间, 当前有效到期时间) 起算，增加 1/3/12 个日历月，月末截断至目标月最后一天，保留时分秒。过期后新购从当前时间起算，不自动续费。余额/有效期在当前账号的金币/会员页面更新，重启后读取本机账本。

本机方案限制：账本与账号 token 依赖设备数据，卸载/换机/丢失账本不能承诺恢复已消费商品；没有线上账户同步或防篡改账本，会员时间依赖设备时钟。原生验证拒绝已撤销的待处理交易，但没有实现已经发放权益的自动退款冲正和离线退款同步。删除账号后不将原交易转移到新账号；交易去重账本与原账号绑定保留以避免再次发放。上述能力不能称为后端已实现。

## 验证与下一步

本机持久化/状态/页面测试、静态分析及 iOS 编译结果和限制见 [本轮验证报告](../testing/apple-iap-local-2026-11-18.md)。原生验证桥接的编译与 Dart fake 测试不等于实际 StoreKit 验证成功。

已完成本机实现；未执行真实 Apple 商品查询、沙盒付款、签名真机安装或原生桥接运行验收。下一步按 [沙盒操作步骤](../testing/apple-iap-local-2026-11-18.md#沙盒操作步骤) 在用户设备逐档购买、取消、重启与补单。正式协议仍沿用原占位，待提供链接。

来源：[StoreKit verification](https://developer.apple.com/documentation/storekit/verificationresult)、[交易历史及消耗型限制](https://developer.apple.com/documentation/storekit/transaction/all)。

## 2026-11-18 提审检查后收窄：购买页加载与发起

用户后续将本轮验收收窄为进入金币/会员页能读取 Apple 商品并拉起系统支付。已修正启动阶段查询失败后进页不自动刷新的缺口：页面首次呈现和恢复前台时刷新，付款处理中/已有查询时跳过；补单查询失败时先尝试恢复。保留手动刷新入口，不做无界自动循环。

商品查询对临时异常/空响应最多尝试 3 次，500/1000ms 间隔，单次 12 秒超时。只在有效查询结果返回后替换缓存；刷新暂时失败保留本次启动已经从 Apple 返回的 ProductDetails，冷启动从未获取商品则仍禁止付款，不构造本地假商品发起购买。查询成功的部分商品可以购买，未返回或类型错误商品不能购买。isAvailable 明确 false 时仍禁止付款。

变更文件：apple_purchase_controller.dart、profile_shop_page.dart、test/apple_purchase_test.dart。tester 独立定向回归 29/29、定向静态分析无问题，证据与原生补测边界见 [本轮提审审计](../testing/submission-audit-2026-11-18.md)。进页恰逢启动查询时复用该查询及其有限重试，全部失败后显示重试入口，不保证外部商店始终可用。真实 ASC 商品、正式团队签名与审核环境仍未取得执行证据，不可把 fake 查询或本地 StoreKitTest 当成审核员支付面板已验证。
