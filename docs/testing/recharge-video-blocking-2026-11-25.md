# 2026-11-25 充值协议、反馈入口和视频拉黑独立回归

范围：用户新增授权仅修充值协议链接、拉黑作者的视频过滤及停止播放，并增加蓝色“充值遇到问题？”进入既有反馈页。其他审计发现继续仅列出不修。已收到developer FIX_READY并对冻结代码独立验证。HEAD+未提交文件SHA256见[指纹](recharge-video-blocking-2026-11-25/fingerprints.json)。没有操作设备或生产账号。

## 实际执行结果

- `flutter test --no-pub test/recharge_agreement_regression_test.dart --reporter expanded` **3/3通过**（[日志](recharge-video-blocking-2026-11-25/recharge-navigation-fixed.log)）：充值协议按钮callback推入AppWebPage，标题“用户充值协议”、URL精确等于 `https://docs.qq.com/doc/DYUtKYWJCTkZCZXdL`；320px宽度充值页蓝色#1890FF帮助按钮导航FeedbackPage；会员页无此帮助入口且未复用充值协议，未见布局异常。路由参数检查不实际构建原生WebView，不能证明网页匿名可访问或正文内容有效。
- `flutter test --no-pub test/video_blocking_regression_test.dart --reporter expanded` **1/1通过**（[日志](recharge-video-blocking-2026-11-25/video-fake-platform.log)）：独立fake VideoPlayerPlatform记录create/play/dispose；当前首项作者被拉黑后旧播放器销毁、下个可见ID正确，混合屏蔽只余末项仍能播放，末项拉黑后全空通用空态且无playing播放器；解除恢复完整目录；切账号及消息状态重新装配后旧播放器销毁、恢复未屏蔽目录；最终卸载无playing残留。账号切换用可控Provider模拟，不是设备账号登录/磁盘切换端到端。

测试夹具过程限制：首版dispose断言因fakeAsync未排空平台异步取消而失败，改用tester.runAsync等待实际事件队列后旧播放器确实释放，未据此要求产品修改。充值夹具初版把控制器建在fake区再runAsync启动造成等待，修正为真实异步区构建/启动后完成；初始调试日志保留在同目录，以上指定最终日志才为结论依据。原生播放声音停止仍需设备确认，fake平台释放不能代替硬件证据。

## 风险状态增量

- AUD25-06 视频拉黑：**代码/Widget范围回归通过**，仅关闭“视频feed不订阅拉黑、拉黑后仍展示并持有旧播放器”的实现缺口；设备声音、跨设备屏蔽和服务端治理不在关闭范围。
- AUD25-03 付费协议：**充值协议入口占位部分已修复并通过路由断言**；会员服务协议仍是旧占位，会员权益兑现、协议正文与匿名可访问性仍未关闭。
- 客服入口：已新增可达本地FeedbackPage；它仍不等于真实客服接收与24小时回复机制完成，AUD25-02保留。
- FLOW25-01永久注销growth残留及其他流程审计问题均未改，既有失败复现不因本轮通过而关闭。

已完成：本范围4项独立定向测试与源码入口核对。未完成：真实客服/治理、会员协议及权益等保留风险，用户尚未授权本轮修复。未验证：原生WebView网页加载/权限、真机拉黑后声音及播放、设备真实账号切换；未重跑全量或构建。下一步用户设备以A账号播放首/末视频→详情拉黑→返回、全部拉黑、解除和B账号切换；充值页打开协议及帮助并返回，确认网页可访问和反馈接收预期。
