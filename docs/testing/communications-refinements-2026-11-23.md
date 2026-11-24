# 2026-11-23 四项细化与22帧设计复查

日期2026-11-23，范围为排除3618:22658后的22帧。继承本轮工作区，保留未提交修改；本报告在上一轮测试记录之外追加，不把历史112+1通过移作本轮证据。最终结论：22/22帧已完成设计与源码静态审查；确认并推动7组静态差异修复，运行缺陷CR-TEEN-01修复回归通过。自动化全量121通过+2用例适配后定向通过，非同次123通过。设备未操作，原生视觉待用户验证。

## 阶段矩阵

设计来源：增长9帧使用本轮保存于 `docs/ui-structure/growth-2026-11-23/` 的逐节点Figma PNG，tester实际逐图查看并对照源码；青少年7帧辅助独立检查详见 [审查矩阵](teen-design-review-2026-11-23.md)，包含本轮MCP证据。剩余6帧正补MCP高保真；不能以旧报告声称还原作为新验收结论。

| 节点 | 页面/状态 | 首轮静态检查与缺陷 | 修复状态 |
| --- | --- | --- | --- |
|3835:20334|我的|头像/余额/列表布局已对图，新增任务签到入口属授权扩展|未原生验收，继续入口回归|
|3628:23332|签到|粉红模态、4+3卡/资源/底部签到已对图，x1为已确认奖励契约|自动触发为本轮新增待验|
|3628:23601|签到成功|礼物/金币/成功态结构已对图，x5示例改契约x1|待新自动触发回归|
|3748:26714|任务中心|UI-TASK-01：整卡背景/大标题错误、weekday/签到卡/任务图标分隔/规则更多缺失|developer/growth FIX_READY，待复验|
|3781:12261|认证中心|UI-VERIFY-02：错误中央标题/渐变底、Card margin/按钮尺寸/左竖条|growth FIX_READY，待复验|
|3781:11614|实名认证|结构已对图，页面环境渐变与F6原稿底色不同|并UI-VERIFY-02，待复验|
|3715:13692|真人认证|主结构/底部52按钮已对图，环境渐变底色不同|并UI-VERIFY-02，待复验|
|3715:13618|视频未上传|UI-VIDEO-03：默认Card底色及margin代替黄底白边预览|growth FIX_READY，待复验|
|3793:12435|视频已上传|UI-VIDEO-03：删除TextButton放预览下导致内容下移，原稿右上圆X|growth FIX_READY，待复验|
|3805:13772|设置密码|TEEN-UI-01：标题/说明对齐、进度、键盘数字副标|辅助审查不通过，整改中|
|3805:13804|确认密码|TEEN-UI-01：同上|整改中|
|3805:13836|关闭验证|TEEN-UI-01：同上|整改中|
|3805:13867|已开启|TEEN-UI-02：徽标/标题布局、按钮定位|整改中|
|3805:13899|退出成功|TEEN-UI-02：状态页按钮定位|整改中|
|3830:13864|未开启|TEEN-UI-02：状态页布局|整改中|
|3805:20105|设置|SETTINGS-UI-01：分组结构、间距、底部注销/退出区|整改中|
|3667:26063|首页|已实时取截图，待高保真/源码完整复核|待查|
|3647:25346|动态|已MCP返回截图URL，尚未完整高保真复核|待查|
|3647:25806|消息|本轮3Tab还原任务，尚待独立高保真/源码复核|通信整改中|
|3618:22659|聊天|本轮资料卡非点击/左头像及热聊+1，尚待独立完整复核|通信整改中|
|3710:13927|聊天设置|本轮整页还原，尚待独立高保真/源码复核|通信整改中|
|3647:25656|动态通知（节点旧名鉴权）|截图URL已取，尚待独立高保真/源码复核|待查|

阶段统计16/22已静态对照，确认6个缺陷组（任务、认证、视频、密码页、状态页、设置），剩余6帧尚未完整复查。此为阶段统计，后文追加修复后状态。任务CTA最初BUG消息误称满宽，更正为原稿居中窄pill；当前已按高保真确认202×44，不能据错误描述扩大按钮。

## 自动化与下一步

developer负责修业务，tester拥有新专项测试/证据。测试窗口已交tester；先等待四项FIX_READY并读取自动签到API。将验证每日首次/已签到/账号隔离/重启/青少年、每条消息和礼物热聊+1及资料卡无导航。设计静态差异先派修，不因缺原生图跳过。MCP截图URL已返回，但批量curl下载提升请求被拒，未擅自重试；后续使用MCP返回的高保真结构/参数核对可继续。

## 第二阶段：22/22首轮静态检查已覆盖

剩余6帧已直接调用Figma `get_design_context`，使用返回代码/样式参数与内联截图对照源码；原文保存在同名证据目录 `context-<node>.txt`，截图下载被拒后未重试curl。MCP本身读取正常。

|节点|源码与本轮核对|结论|
|---|---|---|
|3667:26063|home_companion_card_widget.dart/home_card_surface：48头像、左头像右资料、88方相册、卡边2/R20、打招呼、蓝年龄及动态业务数据|主结构匹配；外padding及动态照片张数适配不等于固定样例像素；父developer继续细核|
|3647:25346|square_page.dart/square_post_card_widget.dart：推荐选中标、右铃铛旋转、40头像、图组与赞评、卡边2/R20|结构已对照；保留授权发布按钮；动态图片和文本不复制设计样例|
|3647:25806|messages_page.dart：同排消息/好友/通话记录，52通知图标/93x97槽、76会话行|本轮由旧分行按钮改内联Tab，待通信最终冻结复验|
|3618:22659|chat_page.dart：40左头像、非点击265资料卡、245x308主图、4张55x73相册、快捷语|UI-CHAT-04：设计主图底独立蓝真人/橙实名徽章缺失，被白文字代替，已派修；动态审核状态不能伪造通过|
|3710:13927|chat_settings_page.dart：首卡56头像、三组白卡、53行/分隔、关注黄色pill、备注右对齐|通信按实时高保真整改中，最终需复验|
|3647:25656|dynamic_notifications_page.dart：标题动态通知、138灰方块与13号文案、消息同款背景|匹配原稿静态结构；节点旧名不据此虚构视频鉴权|

已确认缺陷增至7组（原6+UI-CHAT-04）。本次是逐页静态设计/源码核对，全部22帧原生画面仍待设备验收，不能称全部像素通过。

自动签到 `flutter test --no-pub test/automatic_sign_in_test.dart --reporter expanded`：3/3通过，见 [automatic-sign-in.log](communications-refinements-2026-11-23/automatic-sign-in.log)。包含磁盘重建、同日去重、次日/账号隔离、已签到跳过及青少年开/关的Widget守卫。新通信测试首次运行撞上worker正在改chat_settings_page中间态语法，0项执行，见 [communications-test.log](communications-refinements-2026-11-23/communications-test.log)；等待最终FIX_READY重跑，不将中间态当最终产品缺陷关闭或通过。

## 增长三组差异复验

tester重新读取修复代码确认UI-TASK-01/VERIFY-02/VIDEO-03关键静态差异已修：任务窄黄条/白主体/weekday/连续日期、202×44 CTA、242分组及规则更多；认证F0背景无中央标题、4×12竖条、171认证卡、132×34按钮；真人/实名/视频F6背景、视频154×182黄底白描边及右上角删除。此结论只关闭明确列出的静态差异，不称像素还原验收完成。

首页边距进一步源码确认：共享Container边框2叠显式padding10形成有效12，外12得到351卡、x24头像、x80图片区及约88图片，与高保真一致；此前padding疑问已排除，不盲目修改共享组件。

## 本轮设备验证（待用户执行）

- CR-DEV01：已登录资料完整账号，当日未签到；当天首次打开APP自动签到弹层，关闭后再次打开不再自动弹；换第二账号独立判断；次日再次具备自动资格，已签到账号当天不自动弹。截图仅需首次弹层和已签到状态。
- CR-DEV02：青少年开启时启动/前后台均无签到覆盖锁页；正确关闭后恢复业务且满足资格才弹，登录未完成不弹。切账号与快速前后台不得出现上一账号弹层。
- CR-DEV03：消息三个Tab同排；选择好友/通话记录再返回消息；打开聊天点击资料卡不跳转，左头像与卡对齐；发文字/图片/礼物各增1热聊，收消息/通话话单不增加，重启保留。
- CR-DEV04：聊天设置、任务中心、认证/视频与青少年各状态按同尺寸截图对照本报告逐节点设计。重点查看任务白签到主体、视频删除不导致下文位移、密码页左标题/步骤/数字副标、设置底部退出按钮。当前没有该轮原生运行截图，不能宣称此清单已通过。

## 自动签到扩展回归

`flutter test --no-pub test/automatic_sign_in_test.dart --reporter expanded` 扩展后8/8通过，退出0：[automatic-sign-in-final.log](communications-refinements-2026-11-23/automatic-sign-in-final.log)。新增auth loading/error/资料不完整三个不弹分支；通过Completer分别控制reserve/confirm期间切换为未完善账号B，验证A不弹、旧owner释放、资格未被消耗、B没有误触发。异步切换使用fake可控仓库，真实磁盘的跨实例/账号/日期及release语义由仓库用例证明，不声称已执行原生冷启动。

## 青少年/设置及通信修复静态复验

tester实际重读当前源码，对照辅助报告所引逐帧高保真参数：TEEN-UI-01/02已落实设计y减96的slot体系、左标题/说明、108×25步骤/201×4进度/327×54密码卡、88×58数字键ABC等副标、状态卡和徽标叠层、底128/80对应652/700按钮约束；SETTINGS-UI-01已落实F8背景、52内容+1分隔、14文字/16箭头、退出R16/FFE1E9/EC1F59。上述三组明确静态差异修复已复核，安全区和小屏实际画面仍未设备验收。

通信UI-CHAT-04修复：新增独立蓝真人badge，由业务 `person.isVerified` 决定显示；当前没有独立实名已通过字段，不能仅为复刻样例展示橙色实名已通过。实名徽标按真实业务状态缺失处理，未假造审核。资料卡独立40左头像、10间距、265卡且无整卡InkWell；消息页采用真实TabController/TabBar/TabBarView点击横滑联动；聊天设置53行、分隔、真实关注pill和资料摘要已按设计落实。

## 最终定向首次结果与新缺陷

全部业务FIX_READY后，执行 `flutter test --no-pub test/communications_refinements_test.dart test/automatic_sign_in_test.dart test/teen_gate_widget_test.dart test/teen_mode_test.dart test/main_tabs_mock_test.dart --reporter expanded`：**27通过、1失败**，见 [final-targeted.log](communications-refinements-2026-11-23/final-targeted.log)。通信专项已通过：同排3Tab点击及横滑联动、首页打招呼后资料卡左头像且点击卡不跳转、设置入口、热聊主动文字/图片/礼物各1（99数量礼物单次只1）、通话话单/对端消息不计及JSON恢复。

失败CR-TEEN-01：正确PIN关闭并返回根内容时，Flutter TextStyle插值抛出inherit不同错误（true16字500 → false14字500），`teen_gate_widget_test.dart`末尾 `takeException`捕获。已发送teen与developer修复，P1（监护主链出现运行错误），不能以Widget仍呈现成功关闭此缺陷；待修复后重跑原始失败和关联主导航。

## CR-TEEN-01 修复复验

修复将状态CTA及设置退出按钮文字样式由裸TextStyle改为主题labelLarge.copyWith，保留16/500视觉参数并统一inherit及完整字段。tester保留原异常断言，执行 `flutter test --no-pub test/teen_gate_widget_test.dart --reporter expanded`：1/1通过、退出0，[teen-style-regression.log](communications-refinements-2026-11-23/teen-style-regression.log)。同一正确PIN→关闭→明确返回链未再捕获异常；自动化缺陷关闭，原生设备行为仍待用户验证。

7组静态缺陷复验状态：UI-TASK-01、UI-VERIFY-02、UI-VIDEO-03、TEEN-UI-01、TEEN-UI-02、SETTINGS-UI-01已按明确列出参数修复；UI-CHAT-04蓝徽标及层级已修，橙实名因无独立approved字段保留为数据契约限制，未伪造审核通过。四项原始细化中：资料卡禁点/左头像、每日自动签到、消息真Tab点击横滑、聊天设置页面均已实现并有专项自动化或静态证据；22帧全部完成静态审查。尚无本轮原生截图，未声称逐像素还原。

源码映射（上述逐节点矩阵的具体调用文件）：

- 3835:20334 → `lib/features/user/presentation/pages/profile_page.dart`；3628:23332/23601 → 同目录 `sign_in_dialog.dart`；3748:26714 → `task_center_page.dart`。
- 3781:12261 → `verification_center_page.dart`；3781:11614 → `user_verification_page.dart`；3715:13692 → `real_person_page.dart`；3715:13618/3793:12435 → `video_show_page.dart`。
- 6个青少年状态 → `lib/features/teen/presentation/teen_mode_page.dart`，3805:20105 → `lib/features/user/presentation/pages/profile_settings_page.dart`。分状态精确参数和整改前证据见辅助报告。
- 3667:26063 → `lib/features/home/presentation/widgets/home_companion_card_widget.dart`、`home_companion_item_widget.dart`；3647:25346 → `lib/features/square/presentation/pages/square_page.dart`、同模块widgets/square_post_card_widget.dart。
- 3647:25806 → `lib/features/messages/presentation/pages/messages_page.dart`；3618:22659 → 同目录 `chat_page.dart`；3710:13927 → `chat_settings_page.dart`；3647:25656 → `dynamic_notifications_page.dart`。

## 最终回归与交接

冻结版本执行 `flutter test --no-pub --reporter expanded`：123项，**121通过、2失败**，见 [final-full-test.log](communications-refinements-2026-11-23/final-full-test.log)。失败是既有注销与AuthGate导航测试进入首页后未处理新增自动签到模态，导致点击我的被遮挡。新增 `test/auth_sign_in_test_helper.dart` 显式关闭确实存在的签到Dialog并断言消失，保留原业务断言、没有在产品关闭Gate。随后执行 `flutter test --no-pub test/account_deletion_flow_test.dart test/auth_gate_navigation_test.dart --reporter expanded`：**2/2通过、退出0**，见 [auth-dialog-regression.log](communications-refinements-2026-11-23/auth-dialog-regression.log)。因此当前123项均有最终冻结业务的通过证据，但不能描述为同一次123/123全通过。

最终源码/测试/pubspec指纹：[final-fingerprints.sha256](communications-refinements-2026-11-23/final-fingerprints.sha256)。`git diff --check`实际退出0；新增测试格式化已执行，Dart遥测写权限异常单独保存在test-format.log，不代表格式没有实际修改。构建由developer独立执行，测试窗口已释放，不在本报告虚构最终构建结果。

已完成：四项细化、热聊契约、22帧静态对照与7组差异复验、新增自动化、真实运行错误CR-TEEN-01闭环及旧用例适配。当前未关闭确定的可复现业务缺陷0。未完成/待外部契约：独立实名approved字段、远端审核/消息服务；未验证：原生安全区/多屏/逐像素、相机与视频插件、CR-DEV01~04实际设备链路。下一步按合并手测收集同状态运行截图，与本轮Figma逐页对照后继续修实际差异；源码静态核对与Widget通过不能替代原生视觉结果。

## 第三轮：热聊溢出、通知空态、设置跳转与签到二态

日期2026-11-23，延续用户新增四项。旧轮123项证据不代表本轮通过。新增 `test/chat_header_and_empty_state_test.dart` 准备375/320逻辑宽度×文字1/1.5组合的真实ChatPage热聊入口无Flutter异常检查，以及动态通知使用AppEmptyState的断言；更新通信专项，验证聊天资料卡仍不跳转，而聊天设置顶部用户及查看主页均进入既有UserDetailPage，ID为U002。暂未执行，等待developer冻结。

本轮tester重新直接调用MCP读取3628:23332/23601，两态完整高保真与内联截图已实际观察，原文在 [round3/](communications-refinements-2026-11-23/round3/)。明确静态差异已派developer：原稿panel311×340，旧代码311×370；成功副标题应“每天登录，奖励领不停”；恭喜获得两侧装饰线及连续天数两侧箭头缺失。奖励x1沿用已确认契约，不把成功图x5当业务奖励。filter/foreignObject兼容必须在本轮资源落地后复核，不能仅文件存在即通过。

第三轮通信冻结回归：`flutter test --no-pub test/chat_header_and_empty_state_test.dart test/communications_refinements_test.dart --reporter expanded` **7/7通过、退出0**，[round3/messages-regression.log](communications-refinements-2026-11-23/round3/messages-regression.log)。覆盖375/320宽×文字缩放1/1.5四组合热聊头部无异常且按钮可点击、动态通知实际复用AppEmptyState、设置顶部用户/查看主页都进入UserDetailPage且ID U002、聊天卡依旧不能跳转。保留消息Tab点击横滑和热聊计数断言。

首跑 [round3/messages-test.log](communications-refinements-2026-11-23/round3/messages-test.log) 的5失败属于新测试夹具未预加载profileInitial、误用tester.pageBack定位自定义返回按钮；修正后直接点击实际“返回”入口，未修改业务或弱化异常断言。修复热聊布局未夹断温度文字、保留系统文字缩放，7/7仅证明上述Widget尺寸组合，未声称原生全尺寸通过。

### 第三轮签到最终复验与交接

developer/growth最终冻结后，tester重新核对源码：311×340面板由纯装饰3628:23444导出PNG承载，351×463装饰整体含宝箱/高光/阴影，无页面截图或文字/按钮烘焙；动态文字、4+3天格、奖励卡和213×52签到按钮仍由Widget构成。成功副标题、两侧渐变线、连续天数原SVG箭头已补；不再调用旧panel.svg/banner.svg，历史文件保留。已实际查看新本地PNG及sips元数据，资源尺寸351×463、最终127748字节。成功奖励x1继续沿用业务契约。

`flutter test --no-pub test/sign_in_visual_structure_test.dart test/growth_entry_widget_test.dart test/automatic_sign_in_test.dart --reporter expanded` **14/14通过，退出0**：[round3/sign-in-test.log](communications-refinements-2026-11-23/round3/sign-in-test.log)。包括rootBundle读取并解码装饰PNG、320/375两状态四Widget无异常、我的签到领取/重进不重奖、自动签到8个仓库/Widget边界。此日志没有出现 `unhandled element <filter/>` 或 `<foreignObject/>`；这说明本轮签到资产路径没有触发这些不兼容警告，不能由此宣称原生逐像素一致。

本轮合计通信7项+签到14项定向通过；没有重复全量和iOS构建（修改为Flutter布局、路由和已登记资源，相关链已执行）。源码/测试/签到资产指纹为 [round3/final-fingerprints.sha256](communications-refinements-2026-11-23/round3/final-fingerprints.sha256)，本轮不覆盖此前final-fingerprints快照。

已完成：热聊小屏/文字放大无overflow、通知通用空态、设置正确用户详情双入口且资料卡禁点、签到二态重读设计及兼容资产替换的独立验证。未关闭本轮确定的业务缺陷0。未验证：真实设备文字放大、安全区、签到装饰像素对照；下一步用户在320/375附近设备验证四路径并提供同状态截图，特别关注温度全文可读与签到阴影/高光。旧轮真实服务/实名approved字段限制继续保留，不因本轮通过关闭。
