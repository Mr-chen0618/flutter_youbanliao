# 2026-11-20 广场Tab及活动入口回归

范围：首页/广场共用选中标签、个人中心参与/发布活动入口。日期2026-11-20，本机Flutter测试。

已完成：`flutter test --no-pub test/main_tabs_mock_test.dart` 13项通过，包括新增两入口分别导航MyActivitiesPage(joined:true/false)及返回、原主Tab/广场切换/个人业务。日志[tests.log](square-profile-2026-11-20/tests.log)。

`flutter analyze --no-pub lib/shared/widgets/layout/feed_tab_label.dart lib/shared/widgets/layout/discovery_header.dart lib/features/home/presentation/widgets/home_feed_switch_widget.dart lib/features/user/presentation/pages/profile_page.dart` 无问题，日志[analyze.log](square-profile-2026-11-20/analyze.log)。git diff --check通过。

实现及决策分别在square.md、profile-iteration-2026-11-17.md的本日末节，未改活动数据契约。

未完成：无本轮待实现项。未验证：设备视觉、小屏/字体缩放、原生页面；未构建。下一步设备核对三Tab装饰与我的两行入口，并打开本人活动。

## 2026-11-20 用户SVG替换增量

参与/发布入口图标替换用户提供的两份24×24 SVG，XML解析成功，原样复制并由个人中心_asset渲染。个人中心定向分析无问题；两入口专项回归1项通过，见[activity-icons-tests.log](square-profile-2026-11-20/activity-icons-tests.log)。未重复全量回归和构建，设备视觉待验证；下一步设备查看图标。
