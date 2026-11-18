# 2026-11-18 我的积分

设计来源为 `sZdTOBC0a94JYUYKgAJr8e` 的 `3463:20998`，已读取完整设计上下文及截图，Figma会话 `b4f673c7-c03b-45c3-ab9c-da1149c6bd30`。375×812画板为导航、余额卡、积分记录和空态。

页面结构与组件映射如下。

- 顶部背景 `3463:20999` 高255，复用同款会员/金币背景资源。
- 导航 `3463:21031` 高48，系统安全区下显示返回和「我的积分」。
- 余额卡 `3463:21076` 包含102高圆角卡 `21077`、阴影 `21078`、装饰图层 `21079` 和95方钱包 `21080/21081`。文字 `21082/21083` 为余额和标签。
- 记录标题 `3463:21088` 使用15号灰色文字。
- 空态 `3463:21089` 的138方图片占位及13号文字，接入用户此前指定的 AppEmptyState 统一插画，显示「暂无积分记录」。

实现归属 user 模块，从 ProfilePage 的积分卡经 AppNavigator 打开 ProfilePointsPage。复用 AppImage、AppEmptyState、同款背景/卡片/返回资源。设计9999为样例，当前页面沿用原积分状态0，未提供积分交易、记录或后台服务。此次不新增数据契约。

已完成 ProfilePointsPage、ProfilePage入口与钱包本地资源。既有同款卡片包含设计的半透明装饰层，背景及模糊阴影复用此前保留滤镜的PNG资源。钱包按设计的95方视口、124%原图居中裁剪呈现。空态使用现有AppEmptyState，列表可滚动以适配小屏。未完成的外部依赖为真实积分余额及记录服务。此次余额0及空记录沿用原页面状态，未生成交易样本。

验证环境为当前macOS Flutter工作区。`dart format`涉及三个文件，`flutter analyze --no-pub lib/features/user/presentation/pages/profile_points_page.dart lib/features/user/presentation/pages/profile_page.dart test/main_tabs_mock_test.dart`退出0，无问题。`flutter test --no-pub test/main_tabs_mock_test.dart --reporter expanded`退出0，11/11通过。既有会员/金币入口用例已补积分卡入口、记录标题、空态、零余额及返回个人中心断言。工具输出有共享旧SVG filter提示，未将其当原生视觉通过。未另外保存完整原始日志，结果可在本轮工具调用复核。

本轮未执行构建或设备视觉验收。下一步在设备上核对字体缩放和小屏，并在积分服务明确后通过统一余额/记录数据源替换当前状态。
