# 2026-11-23 通信新增页面

范围：Figma sZdTOBC0a94JYUYKgAJr8e 设计中画布，排除 3618:22658 子树。已实时读取 3618:22659、3647:25656、3647:25806、3710:13927 高保真上下文及截图。session 661eb2cf-1317-4173-a1ae-5d777e61cb87。

## 页面结构与实现

- 3710:13927 聊天设置：资料卡 → 查看主页/关注/备注 → 举报/拉黑。新增 ChatSettingsPage，由聊天右上更多进入；复用 activity 关注数据、ReportPage 及 messages 黑名单。没有 peerId 的历史会话无法定位目录，主页/关注禁用；备注仍可用。拉黑后退出设置及原聊天。
- 3618:22659 IM：导航热聊入口 → 风控提醒 → 对端资料与相册卡 → 快捷语 → 既有输入器。资料和图片读取 userDetailProvider，卡片进入用户详情；快捷语实际发送消息。热聊入口显示本地已发送条数及服务端未接说明，未伪造设计示例 24°C。
- 3647:25806 消息首页：消息/好友/通话记录标签；通知三入口沿用已有设计资源及业务。好友为本地已关注且存在会话的用户，通话记录筛选有语音/视频通话消息的会话；没有独立通话记录详情稿，不虚构通话历史服务。
- 3647:25656 名称为“视频聊天-拨打鉴权”，但本次返回代码与截图均为“动态通知/暂无新通知”，存在命名与内容冲突，按可见内容核对现有通知页，未据名称新增鉴权规则。

备注新增 MessageThread.remark，displayName 仅影响列表和聊天标题，原始 name/peerId 保留；旧JSON缺失默认空，可显式清空。继续通过账号隔离 messages 仓库保存，不增加第二所有者。

发送消息落盘后更新增长任务 chatDay；任务记录失败不影响已保存消息，金币由任务中心幂等领取。热聊图标 assets/messages/messages_chat_heat.png 来源本次设计静态资源；卡片所有头像与相册均为动态业务图片。

涉及文件：messages/data/model/message_thread.dart、presentation/providers/messages_provider.dart、pages/chat_page.dart、chat_settings_page.dart、messages_page.dart，test/chat_remark_test.dart。

## 状态与验证

已完成：上述本地页面与入口、备注存取和旧数据兼容、原业务联动。未完成：真实热聊统计服务；命名冲突画板若确需视频鉴权须提供实际规则/正确画板；好友当前采用关注会话语义，双向好友服务未接。未验证：原生设备视觉、键盘/安全区、远端聊天与RTC；未操作设备。

开发检查：flutter analyze --no-pub lib/features/messages 第一轮无问题；第二轮新增卡片及标签后5个花括号info，已用 dart fix 修复，最终检查结果以独立测试报告为准。dart format 已实际修改格式，但SDK在写用户目录遥测时返回权限失败。新增备注兼容用例交 tester 串行执行，开发未运行 flutter test。

下一步：tester 独立回归消息/备注/拉黑/增长任务；用户执行设备视觉；补齐服务端热聊与好友规则后替换本地语义。

最终开发检查：`flutter analyze --no-pub lib/features/messages test/chat_remark_test.dart` 返回 No issues found（本轮实际执行）。追加青少年通话联动：CallPage.open 对开启/加载或错误状态拒绝呼叫；共享 session 监听 teenModeProvider，模式切换立即 finish，移除小窗并停止循环音。该链路设备听感仍未验证。

## 补齐广场通知入口

实时读取 3647:25346 高保真及截图，右上铃铛已接入新增公开 DynamicNotificationsPage，标题与空态按 3647:25656 实际内容呈现。灰色 138 方块是当前原稿占位，未替换成虚构插画。广场原发布动态按钮独立保留。新增设计铃铛资源 assets/messages/messages_square_notification.svg，20×22并旋转30度，来源原稿Group5477。动态通知远端服务未接；设备布局未验证。聊天任务调用改用 growth.recordChat() 类型化入口。

## 补齐签到弹窗（增长模块协作）

2026-11-23 实时读取 3628:23332/23601 双稿高保真及截图，新增 `user/presentation/pages/sign_in_dialog.dart`；个人中心签到入口改为真实模态覆盖层，任务中心保持独立页面。七日4+3卡片、粉红背景、礼物/金币/吉祥物设计资源、签到与成功两态；连续天数读取实际日期记录，不固定示例3天。奖励使用已确认统一金币x1，覆盖成功稿x5示例。按钮处理中禁止重复；先初始化账号支付账本，再checkIn，刷新增长及金币余额；已有今日记录直接成功态，不重复发放。

新增资源：assets/profile/sign_in_coin.png、sign_in_gift.png、sign_in_banner.svg、sign_in_panel.svg、sign_in_mascot.png。资源下载完成；父developer负责pubspec登记。`flutter analyze --no-pub lib/features/user/presentation/pages/sign_in_dialog.dart lib/features/user/presentation/pages/profile_page.dart` 实际返回No issues found。Widget回归交tester，未操作设备；装饰的完整像素级还原、字体及小屏布局仍需设备验收。

SVG兼容性核查：最终Widget出现foreignObject/filter警告后，读取XML标签和元数据确认`sign_in_panel.svg`的foreignObject仅为空div（backdrop-filter:blur(8.3px)），不含文字或图案；banner/panel的filter对应阴影、内阴影与噪声质感。核心图形由标准向量/填充构成；Flutter SVG不支持上述背景模糊/滤镜，设备装饰质感与设计可能不同，不能据自动化通过宣称逐像素一致。本次未删除设计资产或核心内容。

## 2026-11-23 第三轮通信UI整改

新Figma session `bf8914f8-a098-49f8-8424-b816478a00d7`，通过MCP重新读取3710:13927与3647:25806高保真及截图。实现范围：聊天资料卡禁止点击并置左侧对端头像；消息Tab由developer单独整合真实TabBar；聊天设置改用原稿尺寸自定义布局，保留原业务事件。

节点→源码核对：
- 3710:13949导航48、13954资料卡84/头像56、13960互动卡/13975安全卡圆角14，13961/13965/13971/13976/13980每行53、13964等分隔1、13967关注按钮62×30黄色；对应ChatSettingsPage.build的group/row及资料卡，统一ScreenUtil缩放。标题16、姓名16、正文14、辅助12，顶部内容padding8/左右16/卡间距14。
- 3618:22659聊天卡片组件3619:22977，对端头像3618:22936 40×40，3620:23216行gap10；对应ChatPage._profileCard，稳定key chat-profile-avatar/chat-profile-card；取消卡片InkWell避免打开详情。卡片265、主图245×308、圆角12、相册55×73。动态图片继续业务源。
- 3620:23194蓝真人badge/334:3758图标12，使用本轮MCP上下文导出的messages_chat_real_person.svg，图标与文字独立排列，person.isVerified才显示；用户目录只有单一isVerified，无法证实单独实名审核结果，橙实名通过不伪造。若补充独立实名状态，下一步接对应橙badge。此缺口保留UI-CHAT-04的实名状态部分待契约确认。
- 热聊MessageThread.heat按每条isMine非系统通话记录+1，礼物无论数量和价格只按消息条目+1；现有idempotencyKey去重继续有效。ChatPage导航显示实际°C，说明弹窗同步规则。

验证：`flutter analyze --no-pub lib/features/messages` 最终No issues found（实际执行）；开发未跑flutter test，已向tester交FIX_READY。期间settings括号错误已修复，先前解析失败保留为历史过程，不代表最终状态。未操作设备，原生像素/字形与图片比例仍待视觉验收。涉及chat_page.dart/chat_settings_page.dart/message_thread.dart及上述新SVG；messages_page.dart由developer所有，未覆盖其后续真TabBar整合。

## 2026-11-23 第四轮通信局部修复

范围：热聊入口布局、动态通知统一空态、聊天设置顶部资料入口。保留其他agent全部修改，消息Tab不在本轮修改范围。

- ChatPage热聊IconButton原默认iconSize24容纳图片+自然文本高度不足；显式40.r图标区与水平4.w/垂直2.h padding，图片使用Flexible让出系统文字所需高度，热度文本保留系统缩放，未clip或屏蔽TextScaler。仍保留点击触达区与说明弹窗。
- DynamicNotificationsPage按用户新要求覆盖原稿灰块，复用AppEmptyState(message:'暂无新通知')及assets/shared/no_data.png，与统一空列表一致。
- ChatSettingsPage顶部原有点击处理遗漏RouteNames.userDetail(peerId)必需的arguments，AppRouter按参数类型分支导致落入Example页。现补arguments:peerId，顶部卡增加chat-settings-profile稳定key。查看主页行共用同一处理一并修复；ChatPage对端消息资料卡保持不可点击。

已完成：上述源码修复；未完成：无新增服务依赖。未验证：本轮375/320与textScale1.0/1.3组合的渲染由tester独立执行，未操作原生设备。开发定向format完成，analyze结果后附；未运行flutter test避免测试锁冲突。下一步：tester断言无overflow、统一空态图资源、设置顶部跳UserDetailPage且userId匹配，资料消息卡不跳转。

第四轮开发最终检查：`flutter analyze --no-pub lib/features/messages/presentation/pages/chat_page.dart lib/features/messages/presentation/pages/chat_settings_page.dart lib/features/messages/presentation/pages/dynamic_notifications_page.dart` 实际返回No issues found（7.1s），三文件dart format通过。已交tester FIX_READY，独立测试结论以专项测试报告后续轮次为准。
