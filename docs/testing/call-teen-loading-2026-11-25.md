# 2026-11-25 首次通话青少年状态读取回归

范围：CallPage.open异步等待设备青少年设置，避免加载中误报开启。实现及决策见[通信记录](../ui-structure/communications-iteration-2026-11-17.md#2026-11-25-首次呼叫青少年状态误判修复)。单人开发验证，无独立tester或设备执行。

新增home_page_test四场景：延迟关闭时首次请求进入呼叫、开启拦截、读取失败不呼叫、等待中页面卸载不呼叫；借助可控Completer及fake响铃，不连接真实服务。应用全局TeenModeGate开启/出错时会替换入口，因此后两类检查实际provider状态与无通话，不能断言入口卸载后的Toast一定可见。

初轮全文件8通过/7失败（test.log）：新增测试通过用户详情导航定位，受跨用例导航节流影响；改为直接使用HomePage context，不依赖该导航。中间专项2通过/2失败（targeted.log）：原断言要求Gate替换入口后Toast仍存在，已改核验provider状态和无通话。未以这两轮失败声称产品通过。静态分析初轮一条async context info已通过提前获取Navigator和mounted检查清理，最终No issues found（[日志](call-teen-loading-2026-11-25/analyze.log)）。最终结果见下方追加。

未完成：无本范围编码待办。未验证：真机冷启动、语音听感及系统设置错误提示，未执行构建或其他模块全量。下一步设备同账号冷启动首次拨出，检查未开启可进入且已开启仍限制；历史真实RTC未接边界不变。

最终验证：`flutter test --no-pub test/home_page_test.dart --reporter expanded` **15/15通过**，包括新增4项、重复呼叫拦截、语音取消、视频超时及响铃生命周期（[日志](call-teen-loading-2026-11-25/final-tests.log)）；`flutter analyze --no-pub lib/features/messages/presentation/pages/call_page.dart test/home_page_test.dart`零问题。格式化完成，`git diff --check`通过。仅代表本轮Flutter测试环境，不替代真机冷启动。
