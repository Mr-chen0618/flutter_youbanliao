# 2026-11-17 欢迎动画、登录及注销冷静期回归

范围：用户指定 `2937:27256` 上方第二、第三行，登录顶部图 `2769:7325`、弹窗 `2769:7503`，并使用提供的 `/Users/tabier/Downloads/微撩-登录页动画.svga`。保留既有未提交更改。本轮冷静期按主 Agent 确认采用已有设计7日约定，覆盖先前 [即时注销历史](iteration-2026-11-17.md)；历史事实不改写。前轮 [注册资料回归](registration-2026-11-17.md) 64项通过只代表当时版本。

## 设计和流程

设计节点范围：`2769:7219` 启动；`7262/7296` 欢迎；`7312/7325/7350/7376/7402/7428/7453/7478` 手机号与验证码状态；`7503` 注销冷静期；`7519` 封禁。同名稿归并状态而不当作独立页面数量。7503独立截图读取确认：标题「恢复账号」，正文明确处于注销冷静期，登录恢复正常并取消注销，按钮「继续注销」「恢复账号」。正确验证码后应由用户选择，未选择前不创建业务会话。

| ID | 流程及预期 | 证据方法 |
| --- | --- | --- |
| LD01 | 欢迎SVGA→未同意协议禁止前进→勾选→手机号页→返回欢迎仍保持同意 | Widget正式入口 |
| LD02 | 已填写手机号/验证码→获取/错误/Loading/重发→完整账号或资料引导 | 既有反馈/资料/导航回归；登录限制新增专项 |
| LD03 | 我的→设置→注销→返回取消→再次进入等15秒→原因及说明→申请 | 新公开入口Widget，不能直接调用Bloc代替完整链路 |
| LD04 | 注销后退出业务栈→欢迎→验证码登录→7503继续注销 | session仍空，原资料不删除，不能直接进入业务页 |
| LD05 | 同码再次登录→恢复账号 | 同ID、原昵称/私有数据恢复，pending取消，isDeleted=false |
| LD06 | 真实磁盘+可控时钟，pending跨仓库、7日边界后登录 | 未到期恢复保留原身份；恰到期清理旧数据并分配新ID；B账号不受影响；跨账号不可注销 |
| LD07 | 真实SVGA解码、前后台/离页、失败与迟到解码 | Parser+Widget实际控制器；不能替代设备动效观感 |

## 已有执行与缺陷

环境 macOS、Flutter 3.35.7 / Dart 3.9.2；Widget 375×812，正常流程测试明确关闭连续动画（系统无障碍disableAnimations），独立动画用例采用有限pump读取实际控制器状态。存储分为隔离内存Mock夹具（Widget）和真实临时目录（仓库）；不使用真实账号。

源SVGA为231987B，SHA256 `f9fc07a4473e4176dbb001a499a4f9f08c1ef55098e15c1ca43aea48847b0f68`，zlib解压287308B；[源资源记录](login-deletion-2026-11-17/source-svga.json)。新增真实 `SVGAParser` 解码测试已通过，校验尺寸/FPS/多帧/sprites/bitmap资源非空，不能仅由文件大小推断播放正常。

新的冷静期仓库第一轮 **6/6通过**，见 [日志](login-deletion-2026-11-17/lifecycle-first.log)。后续产品增加当前账号注销权限和recoverAccount显式身份参数，测试增加相应防绕过断言后继续执行最终回归。

ANIM-01 / P2：动画解码失败/未完成时卸载，lazy controller首次在dispose创建Ticker导致 deactivated ancestor 断言。独立Widget实际发现，见 [失败日志](login-deletion-2026-11-17/widget-second.log)。已派开发，修复为initState显式创建，待最终回归结果追加。

早期 [widget-first.log](login-deletion-2026-11-17/widget-first.log) 与 [target.log](login-deletion-2026-11-17/target.log) 记录产品接口半写阶段编译错误及测试括号错误，已分别修正；保留真实失败历史。首次注销夹具使用pumpAndSettle等待账号异步加载超时，改用既有认证测试同类的限次真实异步drain，并保留每个页面/状态断言；不降低成功断言。

## 关键链路独立回归结果

- 注销公开入口单项 **1/1通过，退出0**，见 [最终注销日志](login-deletion-2026-11-17/deletion-final-2.log)：从完整账号首页进入我的→设置→注销，15秒按钮禁用；返回取消保留会话；再次读完→原因/说明必填→提交→完成页；此时restore为空，确认退出到欢迎且原业务页面已销毁。协议同意后进入手机号页，验证码登录显示7503；选继续注销仍无会话/无主Tab；同码再次登录选恢复，进入原ID和原昵称的账号。
- SVGA实际解码测试通过，使用新播放器 `SVGAParser.shared.decodeFromBuffer`，包括所有位图解码；动画控制器前后台暂停/恢复、离页释放及失败兜底/迟到释放三项在 [widget-third.log](login-deletion-2026-11-17/widget-third.log) 中通过。该日志第四项为后续已修正夹具的注销失败，不能把整个文件说成全绿。
- ANIM-01已由上述失败路径回归关闭：`initState`创建控制器后，失败及未解码完成就卸载不再抛deactivated ancestor，静态品牌兜底仍可见。
- 注销夹具中直接await在真实异步区创建的AuthRepository future，曾卡在返回后的restore查询；已按既有AuthGate测试改为 `tester.runAsync(auth.restore)`。调试/中断/超时日志保留 [deletion-debug.log](login-deletion-2026-11-17/deletion-debug.log)、[deletion-final.log](login-deletion-2026-11-17/deletion-final.log)。之后两次失败为测试输入触发setState后未pump导致仍禁用的按钮没有触发，见 `deletion-verified.log`、`deletion-final-pass.log`；补真实帧重建并断言按钮可用后，最终单项通过。没有通过直接发事件或降低断言绕过失败。
- 产品认证目录和账号操作页分析无问题，归档 [产品静态分析](login-deletion-2026-11-17/product-analyze.log)。iOS Release无签名构建通过，产物117.8MB，见 [构建日志](login-deletion-2026-11-17/ios-build.log)。构建不是设备动效验收。

最终全量与测试静态分析由主 Agent 接管执行，待其明确结果再追加；此处不先填通过数。新增测试包含 `auth_entry_test.dart`、`account_deletion_flow_test.dart`、`login_svga_asset_test.dart`、`welcome_animation_test.dart`，共用AuthTestStore从原导航测试提取；原导航和注册用例按欢迎页新入口同步，既有冷静期仓库用例按新7日契约更新。

主 Agent 最终回归追加：`flutter test --no-pub --reporter expanded` 退出0，69/69通过，见 [最终全量日志](login-deletion-2026-11-17/flutter-test-final.log)。首轮全量有一项注册测试遗留发送验证码后的Toast两秒timer，已补等待清理并保留 [首轮日志](login-deletion-2026-11-17/flutter-test-first-full.log)。测试静态检查发现三处const样式提示，已逐处补const，最终结果见 [测试分析](login-deletion-2026-11-17/test-analyze-final.log)。收尾 `git diff --check` 通过。

已完成：7503语义与7日契约对齐，公开注销→继续注销→恢复整链Widget，真实磁盘跨仓库pending/到期清理及身份隔离，动画解码与生命周期缺陷独立回归。

未完成/上线依赖：短信、远端审核和线上账号服务仍是既有依赖；当前冷静期以本地持久化时钟执行，到期清理在下一次登录请求触发。应用未运行时没有服务端后台定时清理，本轮不将此描述为线上账号服务完成。

未验证：本轮未操作模拟器/真机逐屏截图；实际动效观感、设备视频帧率/内存、品牌顶部图原生位置、真实相册/输入法及权限、真实短信与线上注销运营不可由Widget或构建替代。持续动画的真实控制器测试有限pump执行；普通静态流程测试设置系统disableAnimations，分别记录，未把产品动画全局关掉使测试通过。

下一步：主 Agent 汇总最终自动化结果；用户只需一次设备链路确认欢迎动画→协议→手机号登录→设置注销→7503继续/恢复，无需逐稿截图。出现差异时保留机型、系统、状态和最短重现步骤，再定向补测。
