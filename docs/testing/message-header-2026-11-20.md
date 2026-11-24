# 2026-11-20 消息入口及顶部背景验证

范围：MessagesPage三项常驻通知入口及ProfilePage共享首页背景。实现/节点映射见通信迭代和个人中心迭代末节。

已完成：本机 `flutter test --no-pub test/main_tabs_mock_test.dart` 12项通过，包含三个入口可见并直接点击系统消息、主Tab导航及个人中心入口回归。原菜单测试去掉打开菜单步骤，其余行为断言保留。日志：[tests.log](message-header-2026-11-20/tests.log)。SVG filter提示来自现有资源，不阻断本轮测试。

`flutter analyze --no-pub lib/features/messages/presentation/pages/messages_page.dart lib/features/user/presentation/pages/profile_page.dart` 定向检查结果见[analyze.log](message-header-2026-11-20/analyze.log)。

未完成：本轮无新增外部服务工作。未验证：真机/模拟器视觉、小屏及字体缩放、原生安全区；未执行iOS构建。下一步设备查看首页、消息、我的背景一致，逐项打开三个通知入口。
