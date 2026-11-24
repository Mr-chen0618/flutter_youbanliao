# 2026-11-19 聊天礼物赠送

范围：Figma `sZdTOBC0a94JYUYKgAJr8e`，赠送面板 `3525:21388`，入口与消息 `2759:6502`。已读取两稿高保真 context 和截图，面板 metadata 保存为 [结构原文](chat-gifts-2026-11-19/structure.xml)。实例内部 metadata 未展开，不声称全量叶子读取完成；本次按 context 提供的实例内容实现礼物区域，原有聊天保持现有组件。

## 结构及组件映射

- 3525:21388 视频聊天-礼物 → 复用 ChatPage、MessagesPageSurface；礼物业务归属 messages，支付账本归属 purchases。
- 3525:21391 工具栏 / 3525:21393 礼物入口；参考3531:22606 → ChatComposer.onGift，在语音与视频之间加入本地 SVG 入口。
- 3525:22232 礼物标题 → ChatGiftSheet。
- 3525:22136、3525:22149、3528:22331、3528:22339、3528:22371、3528:22347、3528:22355、3528:22363 → 两行四列礼物卡，44×44 图，名称、金币价格，黄色选中描边。名称依用户提供图片文件名覆盖设计占位“爱神丘比特”。
- 3525:22235 充值 → 显示当前账号支付余额，AppNavigator.push(CoinRechargePage)，返回刷新权益；金币图复用 assets/profile/profile_shop_coin_balance.png。
- 3525:22246 数量、3525:22252 赠送 → 1/10/66/99/520/1314 选择，默认1，异步提交期间禁用；数量列表为本轮实现决策，设计未提供展开状态。
- 3531:22563 / 3531:22519 礼物消息 → ChatMessageRow，浅黄229×72卡片、48×48礼物图、“送出礼物/收到礼物”、名称与数量、礼盒水印。

复用：AppImage（本地PNG/SVG及contain尺寸）、AppToast.show（加载/余额/发送错误）、showModalBottomSheet（当前聊天已有面板方式）、AppNavigator（充值导航）、MessagesNotifier.send（追加消息与自动滚动）、MockJsonStore（原消息快照）、PurchaseLedgerStore.transaction（串行原子交易）。礼物独立弹层提取于 messages/widgets，不新增跨模块通用 UI。

## 数据与实现

新增 ChatGift、ChatEntry.gift/giftQuantity 和 gift 枚举；旧JSON默认无礼物，未知种类保持原兼容逻辑。`assets/mock/messages/gifts.json` 为目录来源，八张132×132 PNG原样复制自用户Downloads/礼物图标，工程使用英文语义文件名。

金币单价：冰可乐28、幸运星38、笔芯88、彩虹桥138、扎啤188、幸运锦鲤580、泰迪熊1888、玫瑰花3288。沿用设计单价及格位。

ChatGiftRepository 在现有本机支付账本中将扣款与chatGifts凭据一次原子提交，按账号和活动支付环境扣款；凭据含消息完整快照。消息初始读取时按幂等键合并恢复，拉黑历史也保留记录。并发提交串行检查余额，失败不写账，重复请求不重复扣款。目录重新读取决定单价，UI传入价格不能影响扣款。当前消息发送仍为磁盘Mock，不代表真实远端投递，也不向收礼用户创建虚构余额或积分。

## 状态与验证

已完成：入口、8款图片与名称、礼物选择及数量、充值跳转、余额扣减、本人/对方礼物卡展示、会话预览、持久化恢复、错误反馈。涉及messages/data、messages/presentation、pubspec及资源；支付原有商品与发放不变。

未完成：真实IM礼物投递、收礼端收益结算（外部服务未接入）。未验证：原生设备视觉、安全区、充值后实际赠送及双端接收；不把本地卡片当成远端送达证据。

验证命令、结果与日志见 [专项测试记录](../testing/chat-gifts-2026-11-19.md)。下一步：设备打开聊天→礼物→选择→赠送/不足充值，验收外观与操作；真实服务按礼物ID、数量、请求幂等键及扣款消息原子契约接入。

## 2026-11-19 默认金币10000

用户后续要求默认金币写入10000。本轮在 LocalPurchaseFulfillmentRepository._account 中为每账号首次读取/创建支付身份时发放10000至当前活动环境，记录initialCoinsGranted=true；已有账号在首次读取时补发一次，原充值与消费记录保留。不在刷新或重启时补满，不在每个支付环境重复赠送。覆盖前文“账号无初始余额”的约定，属于本地默认赠送，不伪造Apple付款。

已完成代码；本机17项支付账本/礼物测试通过，包含默认10000、消费后重启保持9972、旧钱包追加而非覆盖、重复读取不重复发放。命令：flutter test --no-pub test/local_purchase_fulfillment_test.dart test/chat_gift_test.dart，日志 /tmp/default-coins-test.log。未操作设备、未直接改设备现存账本；安装本轮代码后首次加载权益生效。下一步设备重新启动并打开礼物面板确认余额。
