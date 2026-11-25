# 2026-11-25 视频发布者、认证状态与提审风险独立检查

范围：广场10条视频固定模拟作者、认证中心两类状态图标；另对当前账号、UGC、付费与隐私入口进行高风险源码抽查。依据flutter-feature-development技能、用户本轮要求和现有交互流程/模块记录。不是全应用全场景验收。未启动或操作设备；用户附件为设计参考，不是当前运行截图。

版本：HEAD `99df386d21168e486087eea781895350ec108c2e` 加本轮未提交工作区；developer与tester并行，最终回归文件指纹另存。测试日志位于同名证据目录。

## 当前源码确认的提审风险

政策依据：2026-11-25 主Agent实读并转交的[Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)，重点1.2 UGC过滤/举报响应/屏蔽/联系渠道、2.1完整性、3.1.1支付及5.1数据处理。以下为源码审计判断，并非Apple预先裁定拒审。

| ID | 级别/分类 | 当前证据与影响 | 下一步/归属 |
| --- | --- | --- | --- |
| AUD25-01 | P1 上线依赖 | `auth_provider.dart:7`固定装配AuthMock；`auth_mock_repository.dart:211`只接受8888，不发真实短信。不能将本地模拟用户和固定视频作者宣传成可互动真人社交服务 | 产品/服务方落实真实鉴权、社交服务，或明确与商店元数据一致的离线产品范围 |
| AUD25-02 | P1 治理依赖 | `report_provider.dart:7`固定ReportMock，`report_mock_repository.dart:10`举报仅本地落盘；`user_bloc.dart:31`反馈仅账号本地追加，而`user_feedback_page.dart:78`承诺24小时回复、`:145`承诺消息联系。未见运营接收和处理闭环，举报按钮不能代替响应 | 提供可运营接收/审核/过滤/联系机制及响应证据；修正不能兑现的承诺 |
| AUD25-03 | P1 产品完整性 | `profile_shop_page.dart:595`付费协议入口只提示“协议暂不可查看”；`:492–499`宣传更多聊天、优先推荐、专属客服，而vipExpiresAt的消费方仅账本/付费页，未找到推荐/聊天会员权益控制 | 付费范围及协议需产品明确并落实；不能仅改Toast关闭问题。金币已有赠送扣款链路，不沿用历史“金币无用途”结论 |
| AUD25-04 | 外部核验/未验证 | `LegalLinks`有隐私/用户协议腾讯文档URL，仓库不能证明匿名可访问、正文覆盖当前身份/支付/保留规则。未访问ASC元数据、隐私问卷与年龄分级 | 最终审核环境确认公开访问及文本，核对ASC实际配置，不因URL存在或未读取即判合规/打不开 |
| AUD25-05 | 未验证/支付产品边界 | 本机StoreKit验证与消耗型账本不等同非法支付；真实商品查询、购买面板、退款及换机/重装后的权益保留仍需设备和产品政策证据 | 用最终商品/审核账号验证真实Sandbox/TestFlight；不能把fake交易单测说成真实付款通过 |

当前不据有限抽查给出“可直接提审/保证过审”。上述外部依赖不授权tester补造后端、删改收费范围或修改生产配置。

## 人工设备检查（待用户验证）

- DEV25-01：已完成资料的新测试账号，广场→视频；连续滑动10项，核对固定头像昵称、无序号、回切作者稳定，打开作者再返回。若可举报/拉黑，确认目标作者一致且被拉黑视频退出播放。关键首屏提供截图即可。
- DEV25-02：未认证、待审核、已认证各隔离夹具；我的→身份认证。每卡仅一枚状态图，未认证/待审浅色，明确批准才深色；待审不能宣称已通过。提供状态与截图，不通过提交本地照片人为制造approved。
- DEV25-03：最终发布环境打开隐私/协议/客服；完成合法账号注册/注销恢复、权限拒绝与再次授权、真实Apple商品查询及系统面板，检查后台视频无声音。使用专用测试账号，不要求交出账号密码。

设备运行、原生视觉和真实服务当前均为未验证；自动化及代码结果后续追加。

## FIX_READY后独立回归结果

已收到developer冻结交接后验证。版本文件及SHA256见[指纹](video-verification-audit-2026-11-25/fingerprints.json)。tester新增 `test/video_verification_audit_test.dart`，未改产品代码。

| 用例/证据类型 | 本轮实际结果 | 边界 |
| --- | --- | --- |
| FIX25-01 固定作者/数据检查 | 10素材ID与10个不同U001～U010一一对应，均存在种子用户、姓名及有效头像资产，媒体存在；单元通过 | 模拟作者，不是视频真实发布者授权证明 |
| FIX25-02 认证五状态Widget | empty、pending、仅真人批准、仅实名批准、双批准，5/5通过，每卡只有一枚图；approved深色、其他浅色；pending审核中而非已认证 | 图形路径及Widget结构证据，无运行设备截图像素比较 |
| FIX25-03 旧认证字段边界 | 旧缺失字段及原待审布尔不升级认证；独立批准标志不串扰，单元通过 | approved为可接入契约，当前无真实审核服务写入 |
| FIX25-04 视频切换及互动Widget | 现有视频专项1/1通过，切换与独立喜欢/收藏保持 | 不提供原生解码或作者详情点击运行证据 |
| AUD25-CORE 账号/支付 | auth_lifecycle、apple_purchase、local_purchase_fulfillment三文件36/36通过 | fake Apple验证与隔离文件环境，不是真实支付 |

命令与日志：`flutter test --no-pub test/video_verification_audit_test.dart --reporter expanded` **7/7**（[日志](video-verification-audit-2026-11-25/audit-tests.log)）；`flutter test --no-pub test/main_tabs_mock_test.dart --plain-name 'video actions update shared state and survive tab switches' --reporter expanded` **1/1**（[日志](video-verification-audit-2026-11-25/video-tests.log)）；`flutter test --no-pub test/auth_lifecycle_test.dart test/apple_purchase_test.dart test/local_purchase_fulfillment_test.dart --reporter expanded` **36/36**（[日志](video-verification-audit-2026-11-25/core-tests.log)）。分次44项通过，不是全量应用44项一次运行。

源码对照：视频信息取公共seed，非当前登录资料；点击资料传 `UserDetailPage(userId: publisher.id)`，显示头像58、昵称18、简介13及底渐变，无视频序号。Figma来源由developer对3163:24193确认，本tester未独立重取设计节点，无实际运行截图，不声称像素级验收。认证卡依据新 `realPersonVerified/identityVerified` 而非提交状态，提交方法不写批准字段。

新增风险 AUD25-06：视频作者详情提供举报/拉黑入口，但视频feed本身不订阅拉黑列表，拉黑后仍可能继续显示/播放对应作者视频（代码发现，设备未复现）；按现有1.2治理要求有风险，需产品定义内容屏蔽效果。用户本轮明确“tester列出来即可，先不让developer修复”，因此本项及上表审计项仅列待办，不要求developer修改，也不标已关闭。

结论：本轮两项需求的上述代码/自动化范围通过；未发现须在本轮原需求内修复的失败项。原生视觉、视频解码/声音、后台生命周期、详情点击运行与真实服务/ASC仍未验证；无全量测试或构建。已完成独立自动化和审计清单，未完成为上线依赖及待用户设备检查，下一步按DEV25清单执行并据结果补充。

后续更正：AUD25-06视频拉黑客户端过滤/播放器释放、AUD25-03充值协议入口占位的限定范围已实现并独立回归通过；会员协议及真实治理/运营等保留。详见[专项回归](recharge-video-blocking-2026-11-25.md)。
