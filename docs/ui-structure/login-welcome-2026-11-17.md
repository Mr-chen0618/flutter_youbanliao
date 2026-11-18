# 2026-11-17 欢迎、手机号登录及注销恢复

## 设计范围

用户指定锚点 `2937:27256` 上方第二、第三行。根据父框 `2937:27257` 的 y=-1193，第二行为 y=-3063 手机号登录十稿，第三行为 y=-3975 欢迎两稿。本轮已读取12张画板的完整上下文和截图。

| 节点 | 状态及实现 |
| --- | --- |
| 2769:7262、2769:7296 | 欢迎用户进入两种头图状态，按用户指定由本地SVGA替换旧顶部静态图；手机号登录按钮、协议勾选与阅读 |
| 2769:7312、2769:7325 | 手机号未输入/已输入，顶部按用户特别指定7325人物与气泡统一，手机号、验证码和登录按钮由真实输入驱动 |
| 2769:7350 | 稿名手机号错误，但图中实际为验证码已发送提示，反馈仍按当前请求结果展示 |
| 2769:7376、2769:7402 | 发送成功倒计时、失败可重试 |
| 2769:7428、2769:7453、2769:7478 | 输入验证码、提交中防重复、倒计时完成重新获取 |
| 2769:7503 | 注销冷静期恢复账号对话框，继续注销/恢复账号 |
| 2769:7519 | 账号被封禁说明，原因及剩余时长来自认证数据 |

页面结构为 AuthGate → AuthEntryPage（SVGA、介绍、手机号登录、勾选协议）→ PhoneLoginPage（返回欢迎、7325顶部人物/气泡、两个输入行、验证码操作、登录操作及协议）→ 新号RegistrationProfilePage/已完成账号MainTabShell。输入控件、Toast、协议H5、AppNavigator、图片资源沿用项目公共能力。

## SVGA及资源

用户源文件 `/Users/tabier/Downloads/微撩-登录页动画.svga` 原样复制为 `assets/auth/auth_welcome.svga`，231987字节，zlib+SVGA2 protobuf。项目原先无SVGA播放器。本轮使用精确版本 `flutter_svga: 0.0.8`，发布元数据支持Dart^3.8.1，与当前Dart3.9兼容，后续版本要求更高SDK。沿用现有audioplayers依赖，欢迎动画采用本地字节解码，不经播放器磁盘缓存。包版本依据见 [pub.dev版本记录](https://pub.dev/packages/flutter_svga/versions)。

WelcomeAnimation管理控制器、异步解码及资源归属。控制器在initState立即创建；切后台或TickerMode关闭暂停，减少动画时保留静态首帧，离页释放控制器及位图，迟到解码主动释放，失败使用已有品牌图兜底，登录操作持续可用。测试可注入decoder覆盖失败和迟到释放。

7325人物五图及气泡、背景和封禁图标来自本轮Figma，位于 `assets/auth/auth_login_*`。欢迎协议必须主动勾选，阅读H5后仍需用户自行勾选，未勾选时提示同意协议。手机号页返回欢迎时保留该勾选选择。

## 账号冷静期契约更正

本次用户明确要求跑通7503，按主Agent确认采用设计记录的7日冷静期，覆盖此前即时清理约定。申请注销落盘requestedAt/deadline并退出当前会话，冷静期保留原ID和数据。验证码正确时若账号处于冷静期，抛AuthAccountPendingDeletion并显示恢复对话框，业务AccountScope尚不可进入。

“继续注销”只关闭对话框并保持未登录，截止时间继续使用原值。“恢复账号”通过AuthRecoveryRepository.recoverAccount(accountId, request)绑定原账号和有效验证码，恢复UserState的isDeleted/isSignedIn并清除pending，成功进入原资料和业务状态。恢复失败保留pending，弹窗可重试。冷静期到期后在该账号下次登录时幂等清理旧身份，再创建新ID；如果恢复确认时已过期，提示重新登录。旧即时删除的账号不会恢复。

清理先写墓碑、清私有文件及本人公开活动，最后删除账号映射和pending，失败后可重试。清全局会话时只清目标账号，申请注销仅接受当前登录账号，重复同一pending不延长deadline。数据字段见 [初始化数据增量契约](../data/initial-data.md)。登录封禁分支只读取真实Mock的suspendedAccounts状态，不种造封禁样本。

注销申请页、说明页与成功提示均同步为7天冷静期，等待与原因填写流程继续沿用。实现涉及auth数据模型/仓库、AuthGate、AuthEntryPage、PhoneLoginPage、WelcomeAnimation、登录限制弹窗及两处账号操作页。

## 状态及验证

已完成12稿页面映射、SVGA接入、欢迎协议和返回、验证码与异步反馈、注销申请与恢复、到期重新注册。未完成的外部依赖为真实短信、服务端注销任务和封禁鉴权，本地冷静期清理在该手机号再次登录时执行。原生动画视觉、键盘及后台交互仍需设备验收。产品静态分析和构建证据见下文，Widget与磁盘回归由同轮测试报告记录，下一步按测试报告核对正常登录和完整注销恢复链路。


开发最终验证已执行 `flutter analyze --no-pub lib/features/auth lib/features/user/presentation/pages/account_deletion_page.dart lib/features/user/presentation/pages/account_action_page.dart`，退出0且无问题，见 [分析日志](../testing/login-deletion-2026-11-17/product-analyze.log)。`flutter build ios --release --no-codesign --no-pub` 成功，83.9秒，产物 `build/ios/iphoneos/Runner.app`（117.8MB），见 [构建日志](../testing/login-deletion-2026-11-17/build-ios.log)。产品文件的 `git diff --check` 通过。

## 2026-11-18 欢迎与手机号页背景衔接

本次范围为用户指出的欢迎页、手机号页上下背景分界。根因为 `auth_login_backdrop.svg` 的线性底色末端是实色 `#EFE7D6`，固定高度图片结束后与页面白底直接衔接。新增 `auth/presentation/widgets/login_backdrop.dart` 的 `LoginBackdrop`，两页统一接入。背景区块继续采用欢迎页414.h、手机号页334.h，原Figma图层上方叠加从35%高度开始至底部的白色透明渐变，终点完全白色。透明端与实色端都使用白色RGB，以保证过渡颜色连续。

涉及 `auth_entry_page.dart`、`phone_login_page.dart` 与新增背景组件。已完成共享组件接入和渐变处理。未完成事项为无。设备视觉仍待本轮验收。下一步检查两页相邻区域的色差与登录入口回归，验证日志由本轮测试记录补充。

验证执行于2026-11-18的当前Flutter工作区。三个产品文件定向 `flutter analyze --no-pub` 退出0且无问题，`git diff --check` 通过。根Agent执行 `flutter test --no-pub test/auth_entry_test.dart test/auth_feedback_test.dart`，3/3通过，覆盖欢迎入口及登录反馈。根源码审查确认同RGB透明渐变在底部终止为白色，背景组件使用IgnorePointer保留控件操作。本轮未执行设备视觉验收。
