# 活动详情专项检查（2026-11-19）

范围：Figma 3171:32311 与 ActivityDetailPage；tester 先静态检查，developer修复，再由tester只读复核diff。具体区块及数据边界见 [实现记录](../ui-structure/activity-detail-2026-11-19.md)。

已完成：默认Chip/按钮留白、发布者行、图文信息、领队头像与参加入口、渐变底栏与间距等差异修复。复核发现的publisher缺失且不可报名的空白成员卡已改为统一空态。

验证：`/opt/homebrew/bin/flutter analyze --no-pub lib/features/activity/presentation/pages/activity_detail_page.dart lib/features/square/presentation/widgets/square_category_badge_widget.dart`，No issues found。

定向回归：`/Users/tabier/ohos/flutter_flutter/bin/flutter test --no-pub test/activity_join_guard_test.dart test/mock_json_storage_test.dart test/main_tabs_mock_test.dart`，17/17通过。证据：[回归日志](evidence/activity-detail-2026-11-19/regression.log)。覆盖报名约束、本地JSON持久化与页面入口，不等于全部视觉通过。

环境说明：初次系统Flutter test与项目package_config引用的OHOS Flutter框架不一致，dart:ui SemanticsFlags编译失败；改用项目实际关联SDK后通过，未修改依赖版本。

未验证：未完成原生iOS截图对照、320宽/大字手工验收及完整逐像素比较。新SVG确认非空、原始尺寸48×48，代码槽位48.r；头像/照片保持原动态数据。分类图标仍使用统一类别资源，仅本页覆盖橙底红字配色。

未完成：全体成员/容量接口不存在，不能以当前viewer状态声称全体报名统计完成。下一步：设备上验证安全区、长文本、滚动、关注、举报、聊天、报名完成后的返回刷新。

## 后续环境纠正与复验（2026-11-19）

用户指出应通过已有 `use_flutter_android` 函数切换环境。按此执行同一个交互式zsh：`zsh -ic 'use_flutter_android; command -v flutter; flutter --version; flutter pub get && flutter analyze --no-pub lib/features/activity/presentation/pages/activity_detail_page.dart lib/features/square/presentation/widgets/square_category_badge_widget.dart && flutter test --no-pub test/activity_join_guard_test.dart test/mock_json_storage_test.dart test/main_tabs_mock_test.dart'`。

确认路径 `/Users/tabier/flutter_sdk/flutter/bin/flutter`，Flutter 3.35.7 stable / Dart 3.9.2。pub get成功，package_config中的flutter已指向 `/Users/tabier/flutter_sdk/flutter/packages/flutter`；pubspec.lock无差异，未升级依赖版本。

最终环境复验：两文件分析 No issues found；三个定向测试文件17/17通过。证据：[Android SDK切换及完整验证日志](evidence/activity-detail-2026-11-19/android-sdk-regression.log)。此前OHOS SDK记录作为历史保留；后续继续本项目应先执行use_flutter_android，而非直接沿用此前OHOS路径。原生iOS视觉验收边界仍未覆盖。
