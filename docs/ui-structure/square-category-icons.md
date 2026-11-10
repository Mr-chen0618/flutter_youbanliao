# 广场动态类型图标

设计来源：`sZdTOBC0a94JYUYKgAJr8e` / `3163:24161`，2026-11-09重新读取设计上下文及截图。完整上下文保存在 `figma-audit/context-3163-24161.txt`，图标按独立父节点整体导出为40×40透明PNG，不在运行时引用Figma地址。

| 类型 | 图标节点 | 本地文件（assets/square/） | 标签底色 / 文字色 |
| --- | --- | --- | --- |
| 美食 | 3163:24162 | square_category_food_icon.png | #FFF4F4 / #F9544A |
| 探店 | 3163:24165 | square_category_shops_icon.png | #FFF4F4 / #FE5D45 |
| 户外 | 3163:24167 | square_category_outdoors_icon.png | #E5FFFC / #17CAB7 |
| 运动 | 3163:24163 | square_category_sports_icon.png | #E8F4FF / #2198FD |
| 旅游 | 3163:24164 | square_category_travel_icon.png | #FFFAE7 / #E0A800 |
| 摄影 | 3163:24169 | square_category_photo_icon.png | #E9FBFF / #00C3FF |
| 研学 | 3163:24166 | square_category_study_icon.png | #476CFF（10%） / #BB62F5 |
| 桌游 | 3163:24168 | square_category_games_icon.png | #FFF8E3 / #DAA500 |

`SquareCategoryBadgeWidget`归属广场展示层，由动态卡片统一组合，列表与详情共用。复用`AppImage`和`AppText`，图标显示18.r、标签水平间距8.w、纵向3.h、圆角8.r。通过动态category匹配八种中文类型、对应目录编码及带“搭子”的名称，未知类型显示中性文字标签，不冒用运动图标。原来的固定sport_badge引用已替换。
