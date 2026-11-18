# 2026-11-18 苹果本机支付验证

## 范围与当前结论

用户选择不接业务后端，使用 StoreKit 2 本机验证和本地权益账本。本轮实现见 [本机支付记录](../ui-structure/apple-iap-local-2026-11-18.md)，覆盖上轮等待后端而禁用付款的默认实现。已完成代码与本地自动化，实际 Sandbox 交易及原生桥接运行仍未验证；不能把 fake 验证器通过称为 Apple 验单通过。

环境：本地 macOS / 当前 Flutter、Dart 3.9.2；插件 in_app_purchase 3.2.3、in_app_purchase_storekit 0.4.8+1；iOS Runner bundle com.djhl.youbanliao，最低 15.6。无 Sandbox 账号登录、无实际扣款。

## 已执行

- `flutter test --no-pub test/local_purchase_fulfillment_test.dart test/apple_purchase_test.dart test/main_tabs_mock_test.dart --reporter expanded`：**38/38 通过**，有效证据 [flutter-test-final.log](apple-iap-local-2026-11-18/flutter-test-final.log)。首轮 [flutter-test.log](apple-iap-local-2026-11-18/flutter-test.log) 也为 38/38。包含新账本 12 项、原支付 14 项和主导航 12 项。
- 静态命令：`flutter analyze --no-pub lib/features/purchases lib/features/user/presentation/pages/profile_shop_page.dart test/local_purchase_fulfillment_test.dart test/apple_purchase_test.dart`。首次 [analyze-final.log](apple-iap-local-2026-11-18/analyze-final.log) 有一条括号样式 info，已修正；最终分析无问题，证据 [analyze-verified.log](apple-iap-local-2026-11-18/analyze-verified.log)。
- `flutter build ios --no-codesign --release --no-pub`：原生 StoreKit 验证桥接编译成功，首轮 118.8MB / Xcode 103.2 秒，证据 [build-ios.log](apple-iap-local-2026-11-18/build-ios.log)。最终 Dart/展示调整后重新编译成功，118.8MB / Xcode 45.2 秒，证据 [build-ios-final.log](apple-iap-local-2026-11-18/build-ios-final.log)。构建后仅补齐一处 Dart if 括号样式并完成最终静态分析，不涉及行为变化。
- `git diff --check`：通过。没有运行全量历史测试，不覆盖其他未提交模块。

新账本覆盖：账号 UUID 重启稳定、不同账号独立；金币与去重记录重启恢复；并发相同交易只发一次；不同购买累加；native verifier 拒绝时 purchased 不足以发放；未知 token 拒绝；迟到回调归属原账号；同号 Sandbox/Production 账本隔离；会员叠加及重放不延长；过期续购、月末和闰年；损坏账本不清空；原子保存失败不报成功且能重试。写入测试使用真实临时文件，验证器是 fake。

原支付/页面回归覆盖查询、选中档位、真实价格格式传递、缺失商品、取消/失败、等待状态、重复回调、完成失败重试、启动补查、账号切换及慢速权益读取保护。原测试中“server UUID”等名称保留上轮含义，当前 UUID 的真实来源已改为本地账本。既有 SVG filter 提示不属于新增支付资源。

## 未验证及限制

未执行原生桥接实际运行、六商品 Apple 真实查询、Sandbox 购买弹窗与系统确认、真正中断/杀进程补单、签名安装、跨设备、退款或时钟改变。Swift 的 verified 分支已源码核对和编译，但没有真实 Apple 交易执行证据。实际按 token 找回原账号和本机写入后再 finish 的整链，需要设备验收。

本机账本无法承诺卸载/换机恢复已消费权益；没有服务端账本、防篡改及账号同步。会员依赖本机时间；本机拒绝未验证或已撤销的待发放交易，但已发放权益的自动退款冲正未实现。专项协议链接仍待提供。旧后端契约保留作未来方案，不是当前支付的必需配置。

## 沙盒操作步骤

1. App Store Connect 确认上述六个 productId 均属于同一 App 和开发者账号，商品资料及价格已配置，付费协议有效；沙盒账号由用户准备，不需要发给 Agent 密码。
2. 使用已正确签名的开发版从 Xcode 安装到开启开发者模式的 iPhone，或使用 TestFlight。当前项目没有绑定本地 StoreKit 测试配置；此步骤用于测试 App Store Connect 的实际商品。
3. 开发签名版第一次尝试购买后，可按系统提示登录 Sandbox Apple Account；iOS 设置 → 开发者中的 Sandbox 账号选项也会出现。开发版不需要退出正常的 Apple 账号。确认购买系统界面为 Sandbox 环境，再继续。[Apple 沙盒准备与登录说明](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox)
4. App 内登录当前业务账号 → 我的 → 金币充值；确认商品已加载、不再是参考价，逐档购买 60/320/820。成功后核对余额增加，测试余额标题带“测试”；取消时不能增加。商店价格以账号地区返回为准。
5. 我的 → 会员中心，分别购买 1/3/12 个月；核对会员有效期按日历月增加。它们是消耗型，不采用自动续期订阅的沙盒加速到期规则。
6. 关闭重启 App，确认余额和有效期保持；同一苹果交易重放不重复发放。测试断网/中断付款后恢复，存在待确认交易时点击“重试确认”。不要用清除 App 数据代替正常重启。
7. 切换 App 业务账号，核对另一账号没有前一账号的余额。支付过程中切换账号时，迟到交易只归原账号。不要把旧账号未知 token 的交易强行转给新账号。
8. 记录设备/iOS/签名或 TestFlight/商品/交易号/预期与实际结果；订单号和账号敏感资料脱敏。若查询失败先核对商品配置、地区、签名与网络，不能将参考价档位当成已连通商店。

下一步：由用户准备 Sandbox 账号后执行设备验收，补充真实交易结果和必要证据；原生桥接或沙盒不通过时按日志修复，不以构建成功替代交易成功。
