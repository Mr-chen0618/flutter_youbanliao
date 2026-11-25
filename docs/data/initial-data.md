# 初始化数据导入

当前来源：`/Users/tabier/Downloads/应用数据-11:9/搭子App模拟数据.xlsx`及同目录`assets/`，导入日期2026-11-10。

已替换打包样本：用户20、活动24、动态20、兴趣/标签60，配套图片172，全部172个引用文件均已校验。用户详情使用表格中的三张相册图；活动使用三张活动图和活动头像。素材来源工作表保留为输入来源，不作为业务列表。

字段约定：保留用户/活动/动态ID与作者关系；用户分类categoryIds由该用户发布活动的类型去重生成，表格未提供独立的用户分类字段。发布时间原样保留，不视为活动排期；性别限制写入gender字段。缺少报名/聊天/履约数据时不新建虚构记录。既有有效动态活动关联按原ID保留，不根据文字新猜关联。

公共用户目录包含U001在内的全部用户，首页按实际登录ID排除本人。公共初始动态无固定本人标记，首次建立账号快照时按authorId判断isMine。提审号预注册逻辑不变，仍无预置的个人报名和发布记录。

重导入命令：

```sh
python3 tool/import_mock_workbook.py --source '/Users/tabier/Downloads/应用数据-11:9'
```

导入只修改工程内assets/mock及图片，不访问或覆盖手机已有账号快照。公开目录与兴趣读取新的打包数据；已写入手机的动态快照和用户编辑保留，新的账号快照使用新样本。原始文件未修改。导入清单和源文件哈希见import-2026-11-10.json。

## 2026-11-17 登录注销冷静期增量

按本次用户要求实现Figma7503恢复账号交互，auth/accounts新增可选pendingDeletions，键为稳定accountId，值为requestedAt和deadline两个ISO8601时间，默认7天。旧文件缺此字段按空集合兼容；原账号、目录和公开关联ID继续使用原身份。申请时只允许当前登录账号，重复申请保留原时间，auth/session置空。

冷静期登录通过验证码后返回受限结果，不先创建有效业务会话。选择恢复时绑定accountId/手机号/验证码，取消注销并将user/account的isDeleted清为false、isSignedIn设true，保留原资料和业务数据。到期后首次登录时幂等清理私有文件和本人公开活动，最后删除账号映射及pending，再分配新的递增ID。旧已永久删除账号保持删除，不复活。

auth/accounts另支持可选suspendedAccounts，键为手机号，值为reason和可选unblocksAt（ISO8601），用于认证返回的封禁说明。没有预置封禁数据。验证码时间与冷静期时间由AuthMockRepository可注入的now函数驱动，默认当前时间。此次无业务种子更改。上述均为磁盘Mock契约，真实短信和服务端定时清理仍待接入。

## 2026-11-18 内购权益边界

六个苹果商品均为消耗型。商品目录在 purchases 模块内，不更改初始种子或 Mock 账号余额。真实权益从 PurchaseFulfillmentRepository 获取并按 accountId 隔离展示；当前无后端实现，不伪造落账，默认禁用购买。服务端需要按 Apple 交易 ID 持久化幂等发放记录及 appAccountToken 账号归属。契约及剩余事项见 [苹果内购客户端](../ui-structure/apple-iap-2026-11-18.md)。

## 2026-11-18 苹果支付后端交接

[后端接入契约草案](apple-iap-backend-contract.md) 列明线上账号 token、验单发放、权益快照与通知建议接口。该文档不代表已实现服务，也未更改磁盘 Mock 数据；后端确认后再落实真实 HTTP 适配和持久化账本。

## 2026-11-18 本机支付账本

用户后续选择无业务后端方案。付费数据现存应用支持目录 purchases/apple_ledger.json（version=1），账号 UUID、环境分区余额/会员和交易去重原子提交，不改变初始样本或 Mock 资料快照。覆盖此前默认等后端开通的约定；数据字段、UTC 日历月规则、保留与恢复限制见 [本机支付](../ui-structure/apple-iap-local-2026-11-18.md)。

## 2026-11-19 聊天礼物增量

新增只读目录 `assets/mock/messages/gifts.json`（id/name/coins/asset）及用户提供的8张礼物PNG，不改变账号初始余额。ChatEntry新增可选gift快照、giftQuantity默认1和kind=gift。现有 `purchases/apple_ledger.json` version=1新增可选chatGifts映射，键为accountId:requestId；值含accountId/environment/threadId/cost/entry。扣减对应环境coins与保存凭据一次原子提交，旧账本无该字段兼容。聊天初始加载合并凭据防止扣款后消息快照未写入的中断丢失。详见 [实现及边界](../ui-structure/chat-gifts-2026-11-19.md)。这是本地赠送记录，不代表线上IM或对端收益。

### 2026-11-19 默认赠送金币更正

按用户后续要求，LocalPurchaseFulfillmentRepository每账号初始化默认赠送10000金币，旧账号首次读取同样追加一次。accounts项新增可选initialCoinsGranted布尔标志，写账后true；当前活动环境coins加10000，已有交易和消费保留，其他环境不重复赠送，重启/刷新不补满。覆盖此前不预置余额约定。设备账本未直接修改，更新代码后读取权益生效。详见聊天礼物记录末节。

## 2026-11-23 青少年设备设置与增长记录

新增设备级 `device/teen_mode.json`，字段 `enabled`、随机 `salt`、PIN `hash`；关闭清除摘要，开启期间不允许重新设置绕过原密码。退出及切换账号不清除此设备设置；首次初始化为关闭。读取失败时全局界面暂停并提供重试，不能默认关闭。Gate 覆盖根 Navigator，通话监听开启后停止铃声和小窗。

新增账号级增长记录与统一金币账本奖励，本轮仍在整合；最终契约见 [增长实现](../ui-structure/growth-2026-11-23.md)。认证身份敏感字段不作为 Mock 明文数据保存，真实认证审核仍需外部服务。数据与流程验证见 [独立回归](../testing/figma-expansion-2026-11-23.md)，设备视觉及真实服务均不由仓库测试代替。

本轮最终补充：增长状态在`accounts/<accountId>/user/growth.json`保存，旧视频字符串兼容解析为VideoShow，新写`{path,status:pending}`；待审标记不代表真人或实名核验通过。每日chat/discover/publish日期由成功业务动作写入，领取时数据层再次检查当日完成；奖励与签到写同一支付账本`growthRewards`环境+事件键去重，跨文件失败可重试且不重复发放。签到图稿x1/x5/x10文案冲突采用统一x1，待产品规则明确后变更。视频本机文件复制至应用支持目录，原生播放与拍摄权限待设备验证。真实审核服务与审核奖励尚未接入。

2026-11-23 后续每日自动签到契约：增长账号JSON新增`automaticSignInDay`和`automaticSignInToken`。自动展示采用reserve/confirm/release两阶段令牌，检查当天未签到且未自动展示；异步被账号/监护状态切换取消时仅释放自己的令牌，不消费展示日期。成功展示后关闭或重启不再自动弹，手动签到入口仍可用。Gate要求登录资料已完成，auth/teen均非读取中/错误且青少年关闭；恢复前台跨日重新检查，同日正在显示弹窗保持。新增行为验证见本轮communications-refinements独立报告，未将前轮签到用例作为自动触发证据。

2026-11-23 后续签到提醒契约更正：用户改为当天未完成签到时每次打开提醒。增长JSON的`checks`是唯一当天完成判据；旧`automaticSignInDay`保留历史数据但不再读取/更新或阻止提醒，`automaticSignInToken`继续用于账号隔离的异步预留/确认/取消安全。展示不再消费当天资格；同次普通build去重由Gate内账号+日期key负责，恢复前台/重启重新检查。当天完成签到后跳过。个人中心签到入口移除，任务中心操作保留。用户本次明确不走测试，未执行测试和构建；详见communications-refinements开发记录最后轮次。


## 2026-11-24 广场本地视频目录

用户确认下载目录根目录5个MP4导入 `assets/square/videos/`，原始来源、SHA256及媒体信息见 [导入清单](square-videos-2026-11-24.json)。这是打包只读内容，不覆盖活动/用户/动态种子或账号历史数据。广场账号快照 `square/feed` 增加可选 `videoLikes`、`videoSaves` 字符串ID数组，缺字段默认空集合；首视频 `square_video_01` 沿用原 `videoLiked`、`videoSaved`，其余ID为 `square_video_02～05`。互动仍由现有磁盘写队列保存。目录导入与字段实现完成，专项回归通过，原生播放未验证；文件与下一步见[广场记录](../ui-structure/square.md#2026-11-24-广场接入五个本地视频)。


### 2026-11-24 后续素材更换

用户要求改用 `/Users/tabier/Downloads/归档` 的10视频，覆盖上节5项打包目录；原目录资源已从工程删除。新目录 `square_video_catalog.dart` 使用 `archive_<SHA256前12位>` ID，全部读取既有 `videoLikes`/`videoSaves` 集合，不使用首项旧布尔字段，防止将原视频互动转给新内容。旧互动保留在账号JSON中，不迁移或清空。来源与哈希见[归档清单](square-archive-videos-2026-11-24.json)。10视频探测及封面生成完成；设备播放未验。

## 2026-11-24 新注册头像默认值

新用户完善资料未上传照片时，按性别将 `assets/auth/auth_default_avatar_male.jpg` 或 `assets/auth/auth_default_avatar_female.jpg` 写入原MemberProfile.avatar；有自选头像继续保存自选路径。使用原账号资料持久化字段，不改已完成账号、公开用户目录或初始样本。默认头像在注册表单派生，完成资料时写入，未提交时不写入。实现完成；设备重登恢复待验，见[注册后续记录](../ui-structure/registration-2026-11-17.md#2026-11-24-新用户默认头像)。

## 2026-11-25 视频作者与认证状态

固定视频目录新增素材ID→U001～U010公开用户ID映射，用户信息读取既有home/catalog种子，未改种子或覆盖账号文件。视频作者用昵称/头像/signature模拟，不声称真人认证。GrowthState兼容解析可选realPersonVerified/identityVerified，缺字段false；旧realPerson与identityPending继续表示已提交，不当作已认证。现有提交方法不会写verified；真实可信审核结果仍待服务接入。实现文件见[视频记录](../ui-structure/square.md#2026-11-25-视频固定模拟发布者)和个人中心迭代末节。

### 2026-11-25 视频拉黑效果

新增行为只读取现有账号messages.blocked线程peerId/id，与稳定视频作者ID匹配后派生可见列表；不新增账号字段或改写媒体目录。解除黑名单会恢复该作者视频，账号切换重新派生目录，目录变化销毁旧播放器。实现完成，独立播放器回归由tester记录，设备播放未验证。
