# 2026-11-23 Figma 新增页面独立验收

## 范围与状态

用户要求全面检查新增功能及优化页面，排除 `3618:22658`。developer 正在实时盘点 `sZdTOBC0a94JYUYKgAJr8e`，当前主 Agent 转交的初步范围为设计中 `205:2421` 的22个顶层 frame；开发方已完成分模块 FIX_READY，最终冻结业务自动化已完成；不能据此声称原生视觉通过。详细节点来源以开发方实时台账为准。

已完成：旧业务自动化基线105项通过、新增模块阶段定向21项通过。未完成：真实服务与设备验收。未验证：所有新增页面运行视觉、原生权限、键盘/安全区、冷启动及真实服务。tester 不操作模拟器或真机，设备链路待用户验证。

## 环境、版本及证据

- 日期：2026-11-23，Asia/Shanghai。
- HEAD：`48453834a2df9f2431887c00c1bf0b06c906dbd9`，有既存未提交修改，保留不撤销。
- Flutter 3.35.7 stable，Dart 3.9.2，macOS 主机；没有启动设备。
- 工具版本：[environment.log](figma-expansion-2026-11-23/environment.log)。
- 基线源码/测试/pubspec 指纹：[baseline-fingerprints.sha256](figma-expansion-2026-11-23/baseline-fingerprints.sha256)。指纹记录基线阶段文件，不代表后续开发版本。
- 最初默认沙箱无法写 SDK `engine.stamp`；工具提权获准后可运行。`flutter test --reporter expanded` 在依赖解析停留，主动中断，见 [baseline-test.log](figma-expansion-2026-11-23/baseline-test.log)，不计测试失败。
- 改用已有依赖配置：`flutter test --no-pub --reporter expanded`，退出0，105/105通过，见 [baseline-no-pub.log](figma-expansion-2026-11-23/baseline-no-pub.log)。此结果仅覆盖开发前已有测试。

## 交互流程与验收计划

已有跨模块流程见 [interaction-flows.md](interaction-flows.md)。新增流程在设计和数据契约交接后细化，不能把代码自身作为唯一预期来源。

| 用例 | 初步设计节点 | 入口与流程/断言 | 方法与当前结果 |
| --- | --- | --- | --- |
| EXP-01 | 我的3835:20334；首页3667:26063 | 首页/我的 → 新增业务入口 → 返回；既存活动/会员/金币入口保留 | 待实现交接，Widget/代码 |
| EXP-02 | IM3618:22659、消息3647:25806、聊天设置3710:13927 | 消息 → 同一threadId聊天 → 设置修改 → 返回；对端身份及账号隔离 | 待实现交接，Widget/存储 |
| EXP-03 | 签到3628:23332、3628:23601；任务3748:26714 | 我的 → 签到/任务 → 领取 → 再进/重建；防重复领取及余额同源 | 待设计规则交接，单元/Widget |
| EXP-04 | 视频鉴权3647:25656；视频秀3715:13618、3793:12435；动态3647:25346 | 入口 → 权限/内容页 → 取消/提交；失败可重试且状态同步 | 待设计规则交接；设备权限待用户验证 |
| EXP-05 | 真人3715:13692、实名3781:11614、认证中心3781:12261 | 我的 → 认证中心 → 身份/真人 → 返回；敏感信息与Mock边界 | 待交接，代码/自动化；真实审核外部依赖 |
| EXP-06 | 设置3805:20105、青少年3805:13772/13804/13836/13867/13899及3830:13864 | 设置 → 青少年 → 设置/确认密码 → 重建 → 退出/修改；错误密码、取消、账号切换 | 待设计规则交接，单元/Widget；设备待用户验证 |

## 缺陷、限制与下一步

目前没有基线自动化失败；尚未对新增业务提出“通过”结论。下一步等待 developer 的范围台账、设计上下文及 FIX_READY，审查新增页面/路由/数据所有者映射，执行受影响用例及必要全量回归，再合并用户设备手测清单。原生运行截图缺失，不声称视觉一致。当前任务不包含完整提审审计，历史真实服务/运营依赖不因本次基线通过而关闭。

## 首轮新增回归（阶段记录）

developer 交接后，tester 更新 `test/home_page_test.dart`：原首页邀约入口改为设计中的打招呼，断言实际 `ChatPage.threadId` 对应 `peerId=U002`、昵称海盐芝士及问候消息；活动发布链保留。`test/mock_json_test_store.dart` 增加默认设备未开启青少年种子并覆盖 initialize，保证Widget夹具初始化不访问真实磁盘。

首次定向执行因夹具 initialize 真实磁盘异步产生11条pumpAndSettle超时，属于测试隔离适配失败，记录 [home-teen-regression.log](figma-expansion-2026-11-23/home-teen-regression.log)。修正后 `flutter test --no-pub test/home_page_test.dart test/teen_mode_test.dart test/teen_gate_widget_test.dart test/chat_remark_test.dart --reporter expanded` 退出0，15/15通过：[targeted-regression.log](figma-expansion-2026-11-23/targeted-regression.log)。

其中青少年为**设备级**设置，跨账号保持限制；不是账号私有数据。tester 新增 `test/teen_gate_widget_test.dart` 证明根Gate遮挡平台内容、错误PIN不能解除、正确PIN后需明确返回才恢复内容。仓库测试证明状态跨实例恢复、错误密码保留、拒绝已开启时覆盖PIN、无明文PIN。根读取pending/error测试随后由teen worker追加，尚待全量回归。没有执行真实应用冷启动。

代码审查发现数据层 `enable` 原可覆盖已开启的PIN，已通知teen worker并修复为同队列拒绝重设，定向回归已包含该断言。消息备注测试验证同会话稳定ID及持久化；新增广场通知返回及发布入口用例等待全量执行。

## 第二轮全量回归与覆盖界限

`flutter test --no-pub --reporter expanded` 第二轮完成113项，112通过、1失败：[regression-second.log](figma-expansion-2026-11-23/regression-second.log)。唯一失败是既有 `new posts are visible under my posts` 未滚动查找下移的“我的动态”入口，已补 `scrollUntilVisible`，后续定向21/21通过（见 final-targeted.log），最终冻结后再执行全量。第一轮 [final-test.log](figma-expansion-2026-11-23/final-test.log) 保留95通过/16失败后中断的历史快照，多数由新增根守卫引入的测试Scope/存储夹具不适配导致。teen worker随后只修复测试夹具，第二轮这些用例均通过，没有在产品中绕过根守卫。

新增 `growth_entry_widget_test.dart` 从我的正式入口进入签到，点击领取、返回后重复进入，初版断言已签到且领取按钮禁用、奖励一次；后续最终设计采用签到弹窗，已对齐成功态和重复进入不发奖，明日再来按钮关闭弹窗；测试用隔离fake增长/支付验证UI绑定，磁盘恢复和并发幂等由独立仓库用例证明，不能将二者合称原生进程重启通过。消息通知和发布回归用例证明广场铃铛可进入设计空态，返回后仍可发布；消息标题改“消息”，聊天更多改设置页，举报/拉黑按新路由完成。

EXP-CHAT-02 曾按源码单看 settings 的 pop 提出拉黑未返回列表风险，经 developer 指出 ChatPage._showActions 返回后统一处理并对照代码撤回，第二轮Widget完整拉黑链通过，无待修缺陷。

## 合并设备手测清单（待用户验证）

前置：使用本轮构建，已完成资料账号A；设备初始未启用青少年模式，金币余额截图留底。所有设备用例未执行。

| ID | 连续操作 | 预期与关键证据 |
| --- | --- | --- |
| DEV-01 | 首页打招呼→聊天→设置备注/关注→举报取消→返回；消息切好友/通话记录；广场通知返回后发布 | 对端一致、备注返回同步、筛选正确、原发布入口保留；截图聊天/设置/通知 |
| DEV-02 | 我的→签到领取→退出重进→任务中心→完成聊天/浏览/发动态任务→领取→重启重进 | 余额与记录同步、每日不重复发放、任务完成由实际动作驱动；截图首次/再次领取状态及余额 |
| DEV-03 | 我的→认证中心→真人/实名→取消/提交；视频秀相机拒绝/取消/选择视频→播放→删除→重进 | 敏感信息无意外保存；本地提交保持待审核；媒体时长/比例/权限/播放正确；远端核验未接 |
| DEV-04 | 设置→青少年→两次密码不一致→一致开启→系统返回/重启→错误密码→正确关闭→返回首页 | 错误输入不解锁、开启立即暂停内容和通话、重启与切账号不能绕过、关闭成功显式恢复；截图锁定/成功状态 |

真实后端审核、通知和音视频远端服务依赖未完成；本轮自动化不证明这些线上能力，也不证明22画板像素一致。

## 最终冻结独立回归结论

developer 确认增长与通信修改停止后执行 `flutter test --no-pub --reporter expanded`，共113项：**112通过、1失败**，见 [final-frozen-test.log](figma-expansion-2026-11-23/final-frozen-test.log)。唯一失败是新增签到UI用例仍用 `tester.pageBack()` 关闭弹窗，Dialog没有导航返回箭头；改用设计中的“明日再来”关闭后，`flutter test --no-pub test/growth_entry_widget_test.dart --reporter expanded` **1/1通过、退出0**，见 [sign-in-final.log](figma-expansion-2026-11-23/sign-in-final.log)。业务源码未因这次失败修改。冻结业务的113项均取得通过证据，但**不是单次113/113通过**。

最终测试及业务/pubspec指纹：[final-fingerprints.sha256](figma-expansion-2026-11-23/final-fingerprints.sha256)。这些测试证明本地业务、仓库与Widget事件链路，设计资源的原生视觉验收仍未执行。日志中 `unhandled element <foreignObject/>`、`<filter/>` 提醒部分SVG能力不受Flutter渲染器支持，不能把资源文件存在或测试通过视为这些效果已完整呈现。

覆盖结果：EXP-01首页打招呼和既存入口Widget通过；EXP-02会话备注、举报与拉黑Widget/仓库通过，好友/通话记录筛选代码实现尚缺独立UI筛选断言；EXP-03正常签到入口与重复进入、并发奖励/每日任务校验/账户隔离及恢复自动化通过；EXP-04动态通知往返和发布入口Widget通过，视频播放/相机/媒体读取未设备执行；EXP-05认证代码与待审核边界已交接，真实身份服务未接、原生表单及相机待验证；EXP-06错误密码/拒绝覆盖/恢复、loading和error fail-closed、正确关闭及显式返回Widget通过。并非22帧所有视觉状态均有运行截图。

实现记录关联：[总台账](../ui-structure/figma-expansion-2026-11-23.md)、[通信新增](../ui-structure/communications-expansion-2026-11-23.md)。分模块设计读取由developer与worker执行，本报告不声称tester重复读取全部节点。构建由developer执行，其日志 [ios-build.log](figma-expansion-2026-11-23/ios-build.log) 只对应当时快照；最终增量构建结论由developer补充。

已完成：新增6组流程的风险审查、独立自动化、测试适配修复、证据与版本记录。未关闭的可复现业务缺陷：0；此前数据边界PIN覆盖风险已修，聊天pop风险经复核撤回。未完成/未验证：上表明确的原生场景、好友/通话筛选UI专项、真实审核和远端服务、22帧原生视觉对照。下一步按DEV-01~04由用户合并执行设备验证，失败携带页面状态/截图回传并按具体链路补回归；设备结果不能由本报告自动判定为通过。
