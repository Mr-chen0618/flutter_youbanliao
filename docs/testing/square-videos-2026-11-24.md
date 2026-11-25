# 2026-11-24 广场视频接入验证

范围：5个本地素材、广场视频Tab、逐视频互动、主Tab活跃状态传递。实现与决策见[广场记录](../ui-structure/square.md#2026-11-24-广场接入五个本地视频)。

已完成：ffprobe校验5视频（HEVC/AAC，19.65～50.10秒），ffmpeg提取5首帧；素材哈希见[清单](../data/square-videos-2026-11-24.json)。Dart格式化完成，`git diff --check`通过。

命令及结果（本机Flutter Widget环境，无原生播放器）：

- `flutter analyze --no-pub lib/features/square lib/app/navigation/main_tab_shell.dart`：No issues found，[日志](square-videos-2026-11-24/analyze.log)。
- `flutter test --no-pub test/main_tabs_mock_test.dart`：首轮13通过/1失败，失败用例为 `new posts are visible under my posts`，非完整通过，首轮终端输出未保存。
- 补充视频切换、第二项独立互动、JSON往返及首项状态隔离后，`flutter test --no-pub test/main_tabs_mock_test.dart --plain-name 'video actions update shared state and survive tab switches' --reporter expanded`：1/1通过，[日志](square-videos-2026-11-24/video-test.log)。
- `flutter test --no-pub test/main_tabs_mock_test.dart --plain-name 'new posts are visible under my posts' --reporter expanded`：单独复跑失败，个人中心“我的动态”找不到可点击匹配；未修改该业务，[日志](square-videos-2026-11-24/my-posts-test.log)。

未完成：个人中心该用例失败原因待独立排查。未验证：原生播放、声音、滑动性能及后台/路由覆盖暂停；Widget环境不提供原生解码证据。未执行iOS构建。下一步在设备逐个播放5条，并执行手动暂停、切换视频/主Tab/子Tab、打开发布/通知页、锁屏恢复检查。源素材原样保留，新增资源约179MiB；如需减小包体再转码。


## 后续：归档10视频与移除序号

2026-11-24 用户修改素材范围，改用“归档”10个MP4；已删除工程旧5视频和封面，导入新素材、生成10封面，SHA256与ffprobe结果见[新清单](../data/square-archive-videos-2026-11-24.json)。播放器改读10项目录，使用内容ID隔离历史互动，移除左下角视频序号与提示；用例改为按内容ID验证切换与互动JSON往返。

未完成：前轮个人中心测试失败待查，本轮没有修改该业务。未验证：设备播放/声音/生命周期和视觉，无构建证据。下一步在设备逐项检查10条视频及无序号效果。前节5视频测试不能替代本轮结果。

本轮结果：Dart格式化完成，`flutter analyze --no-pub lib/features/square` 零问题（[日志](square-videos-2026-11-24/archive/analyze.log)）；`flutter test --no-pub test/main_tabs_mock_test.dart --plain-name 'video actions update shared state and survive tab switches' --reporter expanded` 1/1通过（[日志](square-videos-2026-11-24/archive/video-test.log)）。Python核对10项MP4及封面存在、导入后SHA256与源清单一致，工程内只有10项新视频；`git diff --check`通过。未重复全量导航回归。
