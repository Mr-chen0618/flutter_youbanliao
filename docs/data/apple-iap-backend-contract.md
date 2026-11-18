# 友伴聊苹果内购后端接入交接

日期：2026-11-18。范围：金币及固定月数会员，共六个消耗型商品。本文可交给后端开发。

**状态：客户端已有插件调用和抽象仓库，后端尚未实现。下列 HTTP 路径、JSON 和数据库结构是建议契约，不是已经存在的接口；后端确认后再接客户端 HTTP 适配。** 本轮仅整理交接文档，无业务代码变更。

## 1. 已确认信息

- App 名称：友伴聊。
- Bundle ID：`com.djhl.youbanliao`，已核对 iOS Runner 配置。
- 客户端：Flutter，`in_app_purchase 3.2.3` + `in_app_purchase_storekit 0.4.8+1`，使用 StoreKit 2。
- 六个商品全部为**消耗型 Consumable**。会员购买后增加固定月数，不自动续费；会员到期时间由业务后端管理。
- 客户端查询 Apple 商品价格、发起购买、监听结果、启动补查未结束交易；验证发放成功后才调用 `completePurchase`。
- 暂无真实后端，默认禁止发起付款。账号目前仍为本地 Mock；开放付款前必须接入可信的线上登录身份。

| 商品 | productId（精确匹配） | 内购商品 Apple ID | 发放内容 | 当前页面参考价 |
| --- | --- | --- | --- | --- |
| 友伴聊60金币 | `youbanliao.coins.60` | `6836163432` | 60 金币 | ¥6 |
| 友伴聊320金币 | `youbanliao.coins.320` | `6836168415` | 320 金币 | ¥30 |
| 友伴聊820金币 | `youbanliao.coins.820` | `6836168845` | 820 金币 | ¥80 |
| 友伴聊会员1个月 | `youbanliao.vip.1months` | `6836201153` | 1 个日历月会员 | ¥18 |
| 友伴聊会员3个月 | `youbanliao.vip.3months` | `6836203469` | 3 个日历月会员 | ¥48 |
| 友伴聊会员12个月 | `youbanliao.vip.12months` | `6836206383` | 12 个日历月会员 | ¥138 |

参考价沿用页面，其中 820 金币 ¥80 已由用户单独确认。其余金额仍需核对 App Store Connect。实际售价来自 Apple 商品查询，后端按已验证 productId 发放，不接受客户端提交的金额、金币数或会员月数作为发放依据；各地区币种和价格不应与参考人民币金额强行比较。当前客户端每次购买数量为 1；后端校验 Apple quantity 为 1，其他数量进入明确的异常处理流程。

内购商品的数字 Apple ID 只用于后台核对，客户端购买传 productId。**主 App 的数字 Apple ID（appAppleId）尚未提供，与以上六个数字不是同一个配置。**

## 2. 接入前需要准备的配置

| 配置 | 谁提供/获取 | 用途及状态 |
| --- | --- | --- |
| Bundle ID | 已从工程核实 | `com.djhl.youbanliao` |
| 主 App 数字 Apple ID | App Store Connect → 该 App 的信息 | 待提供；Apple 官方服务端库的 Production 验证器需要主 App ID |
| In-App Purchase API Key 的 `.p8` 私钥 | Apple 账号管理员 | 调用 App Store Server API，仅保存在后端密钥管理系统 |
| Key ID、Issuer ID | 与上述内购密钥配套 | 服务端 API 签名；不是 Team ID，也不是商品 ID |
| Apple Root Certificates | Apple PKI 官方站点 | 验证 JWS 证书链，属于可信根配置 |
| Production / Sandbox 配置 | 后端部署配置 | 使用分别匹配环境的 Apple API 客户端和签名验证器 |
| HTTPS 通知地址，V2 | 后端提供、Apple 管理员配置 | 正式/沙盒分别配置，接收购买、退款等通知 |
| 线上登录凭证和稳定账号 ID | 认证后端 | 所有用户接口必须鉴权，不能信任客户端提交的 Mock 用户 ID |
| API 域名、鉴权及错误格式 | 后端提供 | 供 Flutter 实现 HTTP 仓库适配 |

Apple 官方说明内购密钥及 Issuer ID 的获取路径为 Users and Access → Integrations → In-App Purchase，并要求使用配套 Key ID。[官方服务端库说明](https://github.com/apple/app-store-server-library-node#obtaining-an-in-app-purchase-key-from-app-store-connect)

私钥、用户 Bearer Token、完整交易 JWS 不进入普通日志，不放入 App、公开仓库或本文。只用安全渠道交付后端私钥。当前方案不依赖自动续期订阅共享密钥。

Sandbox 交易不可计入正式付费账本。建议测试与正式数据按环境分区，权益查询与验单使用同一分区策略；TestFlight/提审的 Sandbox 接入策略需要部署时确认。不能仅凭客户端传 `environment=Production` 就作为正式交易发放。

## 3. 最小接口清单

前三个是 App 调用，需要 `Authorization: Bearer <线上登录凭证>`；第四个由 Apple 调用，不使用 App 用户 Bearer Token，以 Apple JWS 验签建立信任。路径可按后端规范调整。

| 方法/建议路径 | 功能 | 对应当前客户端方法 |
| --- | --- | --- |
| `GET /api/v1/payments/apple/context` | 获取当前账号稳定支付 UUID | `accountToken(accountId)` |
| `POST /api/v1/payments/apple/transactions/verify` | 验证交易、幂等发放、返回权益 | `verifyAndDeliver(purchase)` |
| `GET /api/v1/me/entitlements` | 查询当前账号金币及会员有效期 | `loadEntitlements(accountId)` |
| `POST /api/v1/payments/apple/notifications` | Apple Server Notifications V2 | 后端独立处理；不依赖 App 在线 |

所有示例中的 accountId/交易号/日期均为演示值。ID 一律按字符串传输，避免大整数精度丢失。时间用带时区的 ISO 8601，服务端统一 UTC 存储。

### 3.1 获取账号支付上下文

请求：`GET /api/v1/payments/apple/context`，不需要客户端提交 userId。

```json
{
  "data": {
    "accountId": "account_example_001",
    "appAccountToken": "9b73ea44-cf23-43ba-902b-c1c8434dd0f3"
  }
}
```

后端为稳定账号分配随机 UUID 并持久化唯一映射，重复调用/重装/换设备保持一致，不向其他用户泄露或重新绑定。客户端核对线上当前 accountId 后，将 UUID 传给 `Sk2PurchaseParam.applicationUserName`，插件把它交给 StoreKit 的 appAccountToken。注销与重新注册后也不能将旧账号 token 分配给新账号。

### 3.2 验证并发放交易

请求：`POST /api/v1/payments/apple/transactions/verify`。

```json
{
  "transactionId": "2000000000000001",
  "productId": "youbanliao.coins.820",
  "signedTransactionInfo": "<Apple 签名交易 JWS>"
}
```

客户端字段映射：

| 请求字段 | Flutter 来源 | 可信性 |
| --- | --- | --- |
| transactionId | `PurchaseDetails.purchaseID` | 客户端声明，必须与验签后的交易一致 |
| productId | `PurchaseDetails.productID` | 客户端声明，必须匹配签名交易和服务端白名单 |
| signedTransactionInfo | `purchase.verificationData.serverVerificationData` | 当前 StoreKit 2 网关提供的 JWS；必须验签后使用 |

`localVerificationData` 的 JSON、回调状态 purchased、客户端余额、客户端手机号都不能代替 Apple 验证。若客户端缺少交易号/JWS，应拒绝并按异常补查策略处理，不凭空生成交易或发放。

成功返回 HTTP 200，仅在**已验证且落账发放提交成功**后返回：

```json
{
  "data": {
    "transactionId": "2000000000000001",
    "productId": "youbanliao.coins.820",
    "deliveryStatus": "fulfilled",
    "environment": "Sandbox",
    "entitlements": {
      "accountId": "account_example_001",
      "coinBalance": 820,
      "vipExpiresAt": null
    }
  }
}
```

重复提交已发放且归属一致的有效交易：HTTP 200，`deliveryStatus: "already_fulfilled"`，返回当前权益快照，不再次增加金币或月数。示例 820 余额仅表示原余额为 0；实际返回服务端当前余额，不回写固定档位数。

如果验证或发放仍在排队，可返回 HTTP 202 + `PROCESSING`，**不能当作交付成功**。客户端 HTTP 适配需要将它视为待确认，保留 Apple 交易，允许重试。只有 fulfilled/already_fulfilled 才可映射为 `PurchaseEntitlements` 并允许 finish。

建议错误结构：

```json
{
  "error": {
    "code": "APPLE_TEMPORARILY_UNAVAILABLE",
    "message": "购买结果确认中，请稍后重试",
    "retryable": true,
    "requestId": "req_example"
  }
}
```

| HTTP/业务码 | 处理 |
| --- | --- |
| 401 `UNAUTHENTICATED` | 先恢复线上登录，再重试；不 finish |
| 409 `TRANSACTION_OWNER_MISMATCH` | 交易 token 不属于当前认证账号；不重新绑定，不返回原账号余额，不 finish |
| 409 `TRANSACTION_REVOKED` | 已退款/撤销，禁止重复发放，进入客服/退款闭环 |
| 422 `INVALID_APPLE_TRANSACTION` | 签名无效或字段不匹配；不发放 |
| 422 `PRODUCT_NOT_ALLOWED` | 非本应用白名单商品或非消耗型；不发放 |
| 202 `PROCESSING` | 尚未确认交付，之后重试 |
| 503 `APPLE_TEMPORARILY_UNAVAILABLE` | Apple 超时/临时失败，之后重试 |

当前 Flutter 抽象仓库只有成功快照/异常两种结果；新 HTTP 适配需解析上述状态，错误抛异常。现有控制器对失败保留未结束交易并展示重试；针对永久拒绝的终态交互和人工处理仍需联调明确，不能假装成功以清除队列。

### 3.3 查询权益

请求：`GET /api/v1/me/entitlements`。

```json
{
  "data": {
    "accountId": "account_example_001",
    "coinBalance": 820,
    "vipExpiresAt": "2027-02-18T08:00:00Z"
  }
}
```

`coinBalance` 为非负整数，未开通会员的 vipExpiresAt 为 null，过期值可保留用于展示/审计，是否有效按服务端当前时间判断。返回当前登录用户的持久化数据，不依赖 App 本地缓存；换机/重装后的消耗型权益恢复依靠此接口。

### 3.4 Apple 通知回调

Apple 请求体：

```json
{"signedPayload": "<Apple 通知 JWS>"}
```

验证外层通知签名及环境/bundle/appAppleId，并验证包含的 signedTransactionInfo，不能只 base64 解码。可靠入库通知后再返回成功响应，通过任务队列执行后续处理；入库失败返回可让 Apple 重试的失败状态。按 notificationUUID 去重，消费任务另按 transactionId 幂等。V2 的通知和嵌套交易使用 JWS。[Apple 接收通知说明](https://developer.apple.com/documentation/appstoreservernotifications/receiving-app-store-server-notifications)

至少处理：

- `ONE_TIME_CHARGE`：本项目消耗型购买，复用同一验单/发放路径，不能与客户端请求各发一次。
- `REFUND`：记录退款并执行一次权益冲正；如果退款先于发放到达，先保存撤销标记，阻止后续迟到购买事件发放。
- `REFUND_REVERSED`：按最新可信交易状态及冲正账本恢复，不能再次无条件累加。
- `CONSUMPTION_REQUEST`：按 Apple 对该事件的要求和用户同意情况处理消费信息响应，不当作到账事件。
- `TEST`：验证通知配置，不能发放权益。

本项目不依赖自动续期订阅的 DID_RENEW 来延长会员；六个商品的业务类型仍为消耗型。[Apple 通知类型](https://developer.apple.com/documentation/appstoreservernotifications/notificationtype)

## 4. 后端验单与发放顺序

以下是建议落地流程，客户端请求和通知使用同一个交易处理服务。

1. 验证线上会话；客户端路径只允许访问当前认证账号。通知路径依据已验证交易的 appAccountToken 找账号。
2. 使用 Apple 官方服务端库验证 JWS 签名和证书链，不只解码 payload；配置正确的 bundle/environment，Production 验证器补齐主 App 数字 appAppleId。
3. 建议调用 App Store Server API 的 Get Transaction Info 查询当前可信交易并验签，核对购买及撤销状态；接口支持消耗型，也支持已经 finish 的交易。[Apple Get Transaction Info](https://developer.apple.com/documentation/appstoreserverapi/get-transaction-info)
4. 核对 transactionId、productId、bundleId、environment、Consumable 类型、quantity、购买时间及 revocationDate 等字段；签名数据决定商品及账号归属，客户端请求只用于一致性检查。
5. 校验 appAccountToken 与账号绑定；未知/缺失 token 暂挂人工核查，禁止绑定给第一个提交交易的用户。已注销账号的交易保留审计，不自动绑定到同手机号的新账号。
6. 在同一数据库事务里锁定交易和权益：唯一交易键、记录归属与商品快照、写权益流水、更新余额/会员到期、标记 fulfilled 一起提交。并发唯一键冲突回读已完成结果。
7. 提交后返回成功权益快照。客户端收到成功才结束 StoreKit 交易。finish 由客户端调用，后端不调用 Flutter 的 completePurchase。
8. 如果数据库已提交但 HTTP 响应丢失，下一次验单返回 already_fulfilled，禁止重复发放。如果 Apple/数据库暂时不可用，不返回成功。

本次没有选择后端语言。可使用 Apple 官方 Node.js、Java、Python 或 Swift 服务端库，按后端已有技术栈选型；不要自行实现证书链验证。[Apple 官方服务端库入口](https://github.com/apple/app-store-server-library-node)

## 5. 数据持久化建议

| 表/实体 | 最少字段及约束 |
| --- | --- |
| apple_account_bindings | account_id、app_account_token(UUID 唯一)、created_at；账号映射稳定，不复用 token |
| apple_transactions | bundle_id、environment、transaction_id、original_transaction_id、product_id、account_id、app_account_token、quantity、purchase_date、verified_at、fulfillment_state、revocation_date、商品权益快照、受控保存的验签凭据；唯一键 `(bundle_id, environment, transaction_id)` |
| entitlement_ledger | account_id、交易键、事件类型 grant/refund/refund_reversed、coin_delta 或会员授予记录、created_at；同一来源事件只记一次 |
| account_entitlements | account_id、环境分区、coin_balance、vip_expires_at、version；更新加锁或使用乐观锁 |
| apple_notifications | notification_uuid 唯一、environment、type/subtype、received_at、处理状态、重试次数、受控保存的原始通知 |

交易 ID 不只保存在 Redis 或内存；幂等不能只依赖请求 Header。originalTransactionId 保存以便审计，不能用它替代每笔 transactionId 的幂等判断。客户端验证请求与 Apple 通知并发时也只产生一次授予。

## 6. 固定月数会员与退款业务决策

会员是 Consumable，Apple 不替业务维护本项目的会员到期日。建议续购规则：

```text
起算时间 = max(服务端当前时间, 当前有效到期时间)
新到期时间 = 起算时间 + 该商品的 1/3/12 个日历月
```

使用日历月，不擅自按 30/90/365 天换算；月末不足日期建议截断到目标月最后一天。同一交易重试不能再次计算延长。**起算规则、月末/闰年规则和时区仍为建议，需产品确认后落库实现。** 保存每笔会员授予记录，便于退款重新计算，不能简单从当前总到期日减月数而误伤其他购买。

退款时已花掉金币、已消耗会员权益的处理规则也需产品确认。建议独立记录欠额/冻结或人工处理状态；现有 Flutter 权益契约拒绝负 coinBalance，不能直接返回负数。退款和退款撤销必须有独立冲正流水，保留历史，禁止删除原购买记录。

## 7. 客户端联调位置和后端交付物

已有抽象：`lib/features/purchases/data/repository/purchase_fulfillment_repository.dart`：

```dart
bool get isConfigured;
Future<String> accountToken(String accountId);
Future<PurchaseEntitlements> loadEntitlements(String accountId);
Future<PurchaseEntitlements> verifyAndDeliver(PurchaseDetails purchase);
```

后端就绪后，Flutter 新增 HTTP 实现并替换 `purchaseFulfillmentProvider` 的默认 UnavailablePurchaseFulfillment，接入项目已有 HTTP/线上鉴权。只有验证、持久化发放、错误处理和环境隔离可用后，才将 isConfigured 设为 true。

后端交付：三个 App 接口及通知 URL、OpenAPI/接口文档、域名和环境、鉴权方法、错误码、账号 token 规则、验证/幂等实现、权益规则、退款策略、测试账号和脱敏交易样例。不要把私钥放在接口文档里。

## 8. 联调验收与本次证据

验收至少包括：六档真实 Sandbox 查询及购买；取消不发放；同一交易重复/并发提交及通知与客户端同时到达只发放一次；落账后响应丢失可补单；App 退出/杀进程后补查；换账号不串账；重装/换机加载权益；错误 bundle/product/token/签名/环境拒绝；Sandbox 不污染正式余额；退款先到、退款重放、退款撤销、会员到期和月末续购。

本次已完成：从现有 Dart 商品、网关、抽象仓库和 iOS bundle 配置核对字段，并查阅上述 Apple 官方文档；输出建议接口及交接规则。验证：文档链接和六个商品映射核对、git diff --check；只改文档，未运行 App、测试、后端接口或沙盒购买。上轮客户端测试和构建结果见 [客户端验证报告](../testing/apple-iap-2026-11-18.md)，不作为后端已通过的证据。

未完成：实际 HTTP 契约确认及后端实现、线上鉴权、Apple 密钥/主 App ID/通知配置、权益及退款业务规则确认、Flutter HTTP 适配。下一步按第 2 节收集配置，由后端确认第 3 节契约并实现验证发放，再执行上述联调验收。

## 2026-11-18 后续方案变更

用户随后选择先实现无业务后端的 [本机支付](../ui-structure/apple-iap-local-2026-11-18.md)。本交接继续保留作为未来服务端方案草案，不是当前付款入口的必需依赖；后端接口仍未实现。
