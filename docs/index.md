# 项目文档统一入口

2026-11-24 [iOS 最低版本配置](ui-structure/ios-minimum-version-2026-11-24.md)：补齐并统一 iOS 15.6 配置，签名归档和上传仍待验证。

维护日期：2026-11-17。新聊天先遵循 [根目录规则](../AGENTS.md)，再按下表选择入口；不需要通读全部 docs。

## 按任务恢复上下文

| 任务范围 | 优先读取 | 按需深入 |
| --- | --- | --- |
| 页面结构、公共组件、模块职责 | [现有 UI 索引](ui-structure/index.md) | 索引中的 auth、square、活动/用户详情及分层章节 |
| 11-17 新版整体范围 | [新版范围与业务入口](ui-structure/iteration-2026-11-17.md) | 先读“页面与业务入口”“集成验证”，只有节点溯源时再读前面的清单 |
| 欢迎SVGA、手机号登录及注销恢复 | [欢迎与登录实现](ui-structure/login-welcome-2026-11-17.md) | 含11-18两页背景渐隐修复；[流程验证](testing/login-deletion-2026-11-17.md)，7503恢复弹窗及7日冷静期覆盖历史即时删除约定 |
| 登录后的完善资料及弹层 | [完善资料九稿实现](ui-structure/registration-2026-11-17.md) | [本轮验证](testing/registration-2026-11-17.md)，对应 `2937:27256` 上方整行；返回挽留覆盖旧返回登录约定 |
| 个人中心、编辑资料、关系 | [个人中心迭代](ui-structure/profile-iteration-2026-11-17.md) | 11-18恢复活动信誉分入口并修正客服上传卡；历史字段约定见 [第三轮字段整改](ui-structure/profile-edit-round3.md) |
| 会员中心、金币充值 | [页面实现记录](ui-structure/profile-membership-coins-2026-11-17.md) | [本机支付实现](ui-structure/apple-iap-local-2026-11-18.md)、[本轮验证及沙盒步骤](testing/apple-iap-local-2026-11-18.md)；已改用本机验证发放，真实沙盒未验，正式协议待接 |
| 苹果支付后端接入 | [后端交接与建议接口](data/apple-iap-backend-contract.md) | 商品、Apple 配置、三个 App 接口、通知、验单幂等及联调清单；后端尚未实现 |
| 当前提审检查 | [11-18 独立提审审计](testing/submission-audit-2026-11-18.md) | 用户本轮收窄为购买页：修复后29项定向回归及Release编译通过；真实Apple商品查询/系统面板未验证，完整产品历史风险保留报告 |
| 我的积分 | [积分页面实现与验证](ui-structure/profile-points-2026-11-18.md) | `3463:20998`，个人中心入口、余额及记录空态 |
| 消息、语音、通话、举报、黑名单 | [通信模块迭代](ui-structure/communications-iteration-2026-11-17.md) | 本地业务与真实服务边界，以及对应测试报告 |
| 个人入口箭头、相册上传卡、呼叫等待与声音修复 | [本轮回归报告](testing/call-profile-fixes-2026-11-17.md) | 两份模块迭代末尾更正；所有构建移除拨出模拟接通入口，原生视觉及听感仍待设备验收 |
| 全项目列表空态、个人关注页 | [空态组件与关系页设计记录](ui-structure/empty-states-2026-11-17.md) | [回归与设备验证边界](testing/empty-state-2026-11-17.md) |
| 历史交互修复 | [第三轮交互记录](ui-structure/interaction-round3.md) | [广场结构](ui-structure/square.md)、[类型图标](ui-structure/square-category-icons.md)、[认证流程](ui-structure/auth.md) |
| 测试、缺陷、验收与证据 | [测试统一索引](testing/index.md) | 按轮次选报告，先最终结论/限制，再指定矩阵和证据 |
| 初始化数据、字段来源、旧账号边界 | [初始化数据说明](data/initial-data.md) | [导入快照](data/import-2026-11-10.json)，仅需溯源时读取 |
| 历史 Figma 范围核查 | [全文件盘点](ui-structure/figma-audit/inventory.md) | 原始 XML/context 按具体节点读取，非日常恢复必读 |

现有 ui-structure/index.md 已有可用索引，继续沿用；本入口补足模块迭代和测试导航，不复制页面结构树。

## 历史状态摘要与适用边界

以下来自已有文档正文，本次仅整理导航，未重跑业务测试或构建，也未重新验证当前源码。

- **已完成的历史记录**：11-17 [测试迭代](testing/iteration-2026-11-17.md)“最终独立验收结果”记录全量 56/56 通过，列明正常业务入口、持久化和 UI 修复覆盖。[新版范围](ui-structure/iteration-2026-11-17.md)记录静态分析和 iOS 无签名构建成功。只能作为当轮范围的历史证据。
- **未完成/外部依赖**：真实 RTC、远端接听与来电服务、会员支付和余额交易、人工审核服务、正式协议及设计中的 7 日注销撤回未接入；详见新版范围和通信记录。当前注销采用已记录的本地即时清理契约。
- **未验证**：11-17 未操作模拟器；原生视觉、键盘/安全区、麦克风与相册授权、录放音硬件及若干上限/完整链路未独立执行，详见测试报告“仍需区分的实现约定和验证范围”。自动化通过不覆盖这些事项。
- **历史差异**：11-09 报告及矩阵保留修复前待办与后续回归；11-17 对资料、举报、通话等有新范围。对同一功能查后续明确结论，不能直接采用旧标题“当前有效”或旧限制值，也不能将旧轮未测项一律视为已关闭。

## 持续维护与交接

按 [AGENTS.md](../AGENTS.md) 的收尾规则更新相关记录与索引。索引保存导航、状态摘要和适用边界，详细实现与执行证据留在原分类中。

本次上下文机制：新增根规则、本入口和测试索引；保留所有原文档及目录。文档链接与历史文件完整性由本次检查验证，业务验证没有执行。

新聊天示例：“继续个人资料回归” → 根规则 → 本入口 → 测试索引 → 11-17 报告的最终结果/限制 → 个人中心迭代 → 只读取相关用例或证据。恢复时先列出该任务尚未完成与尚未验证的事项，再开始工作。

2026-11-19 聊天新增 [礼物赠送](ui-structure/chat-gifts-2026-11-19.md)，本地账本扣款与消息恢复已实现，验证见 [专项记录](testing/chat-gifts-2026-11-19.md)，远端礼物服务未接入。

2026-11-19 活动详情见[UI修复](ui-structure/activity-detail-2026-11-19.md)与[专项验证](testing/activity-detail-2026-11-19.md)：17项定向测试通过，设备视觉待验。

2026-11-20 消息顶部三入口及消息/我的首页同色背景已调整，见[通信记录末节](ui-structure/communications-iteration-2026-11-17.md#2026-11-20-消息顶部入口与背景)与[验证记录](testing/message-header-2026-11-20.md)。

2026-11-20 广场Tab采用首页同款选中装饰、我的页恢复参与/发布活动入口，见[个人中心最新记录](ui-structure/profile-iteration-2026-11-17.md#2026-11-20-恢复参与和发布活动入口)及[回归报告](testing/square-profile-2026-11-20.md)。

2026-11-23 [Flutter developer skill 抽离](flutter-developer-skill-2026-11-23.md)：个人通用 skill 与项目 agent 配置分离；框架源码和真实任务调用待验证。

2026-11-23 [Paperclip 真实接口版 skill](flutter-developer-skill-2026-11-23.md#后续paperclip-真实接口版本)：独立交付 flutter-api-developer，模板源码已读取、技能校验通过，Paperclip 运行及业务联调待验证。

2026-11-23 [完整前端与自主验收 skill](flutter-developer-skill-2026-11-23.md#后续完整前端与自主验收版本)：flutter-frontend-developer 覆盖模板获取、模块文件分类、完整 UI 与真实接口、自主验收；包校验通过，实际运行待验证。

2026-11-23 [Figma 新增与优化页面](ui-structure/figma-expansion-2026-11-23.md)：排除 `3618:22658`，完成8个Page盘点及22帧本地页面/交互接入；[独立验收](testing/figma-expansion-2026-11-23.md)记录冻结版本112项全量通过+1项定向通过、最终iOS无签名构建通过。应用分析无error/warning、27条历史info；原生视觉、真实审核/视频上传等服务待验或未接入，见报告DEV-01～04。

2026-11-23 [developer 编码细则补齐](flutter-developer-skill-2026-11-23.md#后续对照-developer-补齐编码细则)：Paperclip 前端 skill 补齐强制注释、组件组织、复用与资源规范，新增编码自验，包校验通过。

2026-11-23 [第三版逐页还原与修复](ui-structure/communications-refinements-2026-11-23.md)：覆盖本版22帧设计/源码检查，修复资料卡、自动签到、消息Tab、聊天设置及任务等差异；22/22首轮静态检查及7组差异复验完成；全量121通过+2旧用例适配后定向通过（非同次123通过），见[专项报告](testing/communications-refinements-2026-11-23.md)。真实服务及设备视觉边界仍保留。

本轮第三版修复最终构建：2026-11-23 iOS Release 无签名构建通过（Runner.app 121.7MB），证据 `docs/testing/communications-refinements-2026-11-23/final-ios-build.log`；与本轮专项报告的冻结版本对应。

2026-11-23 第三版后续修复：热聊头部溢出、动态通知通用空态、设置用户详情参数、签到双态布局与兼容PNG已修；通信7/7、签到及自动弹窗14/14定向通过，无filter/foreignObject警告。详见[开发记录](ui-structure/communications-refinements-2026-11-23.md)与[第三轮独立报告](testing/communications-refinements-2026-11-23.md)。原生视觉仍待设备验证；未重复全量或iOS构建。

2026-11-23 签到提醒规则调整：未完成当日签到时，每次打开/恢复App可自动弹出，历史已展示不再阻止；移除“我的”签到入口。详见[开发记录](ui-structure/communications-refinements-2026-11-23.md)末节；按用户要求未运行测试或构建，前轮测试不覆盖此变更。

2026-11-24 [广场五视频](ui-structure/square.md#2026-11-24-广场接入五个本地视频)已接入打包素材、滑动播放与逐视频互动；[验证记录](testing/square-videos-2026-11-24.md)列明专项通过、导航失败项与设备待验。

2026-11-24 后续广场视频已改用下载“归档”10条视频并移除左下角序号；原5条方案由[后续记录](ui-structure/square.md#2026-11-24-后续改用归档视频并移除序号)覆盖。

2026-11-24 [新用户默认头像](ui-structure/registration-2026-11-17.md#2026-11-24-新用户默认头像)：男用用户第一张图、女用第二张，默认头像可直接注册；[验证记录](testing/default-avatars-2026-11-24.md)。

2026-11-25 [视频固定模拟发布者](ui-structure/square.md#2026-11-25-视频固定模拟发布者)与[认证图标状态](ui-structure/profile-iteration-2026-11-17.md#2026-11-25-认证中心单图状态)：10视频绑定固定用户，认证单图按可信通过状态深/浅显示。独立回归及当前提审风险见[本轮报告](testing/video-verification-audit-2026-11-25.md)；按用户要求审计发现仅列出，暂不修复。设备视觉与真实服务仍待验。

2026-11-25 [后续业务闭环审计](testing/flow-closure-audit-2026-11-25.md)：仅列问题未修复；永久注销后growth残留以隔离测试复现（0通过/1失败），相关6项通过；补充到期删除触发、评论治理、认证奖励、活动退出及送礼/通话链路断点。设备、真实服务和构建未验。

2026-11-25 [充值协议、反馈入口与视频拉黑回归](testing/recharge-video-blocking-2026-11-25.md)：充值协议接入用户URL，新增蓝色“充值遇到问题？”跳转反馈；账号黑名单过滤视频并释放旧播放器。独立导航布局3/3与fake播放器1/1分次通过。仅覆盖上述客户端范围，真机声音及协议正文加载未验；其他审计问题保留未修。
