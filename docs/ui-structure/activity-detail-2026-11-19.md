# 活动详情 UI 修复（2026-11-19）

范围：Figma `sZdTOBC0a94JYUYKgAJr8e` / `3171:32311`。tester 先读源码与现有记录，developer 按当日官方 MCP 高保真上下文及截图修复，仅影响活动详情页。

已完成：分类标签复用 SquareCategoryBadgeWidget；发布者28px头像、12px文案、关注渐变按钮和0.5px分隔线；信息卡统一时间、地址、性别13px图文行，真实描述独立；成员卡展示48px领队头像/角标、真实当前报名者以及可点击参加入口；图片区保留动态图片与343:257比例、16px圆角及8px间距；底部按钮16px外边距/4px间距、52px最小高度和渐变胶囊；封面顶部黑色遮罩与透明导航。

复用与归属：ActivityDetailPage继续由activityDetailProvider与原Repository供数；AppImage负责动态图像；SquareCategoryBadgeWidget负责统一类别映射；AppToast/showReportActions/AppNavigator与原报名及聊天入口保留。参加图标下载自节点3171:32616的原始Group5390，保存在assets/activity/activity_detail_join_placeholder.svg，48×48，页面48.r槽位使用，无临时URL引用。其他图标沿用既有activity SVG；照片与头像继续来自业务数据，未用设计样例替换真实内容。

设计与数据边界：设计标题重复“发布的活动”按原稿保留；本页分类覆盖橙底红字，统一组件新增可选颜色参数，其他调用默认保持不变。当前数据没有全体成员或名额上限，不硬编码1/10及虚构人物；仅展示已知成员，一个参加入口不表示剩余名额。已报名计数仍为当前账号的本地状态，未实现全体统计。缺活动时间时显示真实发布时间。长文、缺字段会改变纵向高度，避免用绝对坐标裁剪。

未完成/外部依赖：真实报名名单与容量接口未提供。未验证：原生设备逐像素视觉、安全区和大字模式手动验收。

验证结果见对应 testing/activity-detail-2026-11-19.md。下一步：tester复核定向测试及diff，再在iOS设备按375基准验收。

2026-11-19 后续环境纠正：按用户要求use_flutter_android切换Flutter3.35.7并pub get；最终两文件分析和17项回归通过，见测试记录后续环境纠正章节。
