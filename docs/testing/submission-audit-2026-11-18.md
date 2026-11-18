# 2026-11-18 独立提审审计

## 初始完整产品审计（历史范围）

结论：**目前不建议按收费真人社交完整产品提交**。当前工作区客户端自动化通过，支付采用StoreKit本机verified不是缺陷；阻断来自收费用途/宣传权益未实现，以及正式依赖仍是本地模拟。无P0发现，不等于已证明所有安全场景；P1见下。用户明确不再自行测试，本轮不把沙盒验收交回用户，不索取密码、不访问/购买用户真实Apple账号。主Agent安排developer在隔离模拟器做StoreKitTest；其结果单独追加。

版本与环境：2026-11-18工作区，保留未提交支付改动；macOS / Flutter 3.35.7 / Dart 3.9.2；关键文件指纹见本轮证据目录。依据根AGENTS、统一入口、最新 [本机支付记录](../ui-structure/apple-iap-local-2026-11-18.md) 及源码，未把旧测试当当前通过。

## 实际执行

- 独立 `flutter test --no-pub --reporter expanded` **96/96通过，退出0**；[全量日志](submission-audit-2026-11-18/flutter-test.log)。含本地账本12项、支付14项、账号隔离/注销及旧业务。账本测试为真实临时目录+fake Apple验证器，不是Apple真实付款。
- 独立 `flutter analyze --no-pub lib/features/purchases lib/features/auth test/apple_purchase_test.dart test/local_purchase_fulfillment_test.dart` **无问题**；[分析日志](submission-audit-2026-11-18/analyze.log)。
- 苹果规则2026-11-18实读 [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)：1.2治理要求、2.1完整性、3.1.1购买与恢复、5.1.1账号删除；下述为结合源码的审计判断，不承诺实际审核结果。

## 阻断与缺陷

| ID/优先级 | 证据和影响 | 结论/修复方向 |
| --- | --- | --- |
| REVIEW-01 / P1 | `profile_shop_page.dart:460`起承诺会员标识、更多聊天、优先推荐和专属客服；`vipExpiresAt`仅支付仓库与shop展示被使用，无其他业务权益控制。金币仅增加balance，无扣减用途 | 收费却未兑现承诺，属于产品完整性/准确性阻断。应实现真实可用权益/用途后收费，或明确决定调整收费范围；不能仅改Toast算关闭 |
| REVIEW-02 / P1 | `auth_provider.dart:8`无条件AuthMock；`auth_mock_repository.dart:176–187`不发送短信，`:211`固定8888；聊天、资料目录和远端接听仍本地演示 | 正式产品呈现手机验证/真人社交而无相应服务。不是认定所有App必须后端，而是当前所声明联网社交能力没有兑现；需真实服务或用户明确调整产品定位，并与商店元数据一致 |
| REVIEW-03 / P1 | `report_mock_repository.dart:10`只写本地JSON；客服 `user_feedback_page.dart:78`承诺24小时回复但提交只写UserBloc；未发现可运营的过滤/接收处理服务 | UGC过滤、及时举报响应及可联系支持证据不足。举报按钮和本地拉黑测试不能代替治理闭环；需落实处置渠道并纠正不可兑现承诺 |
| REVIEW-04 / P1 | `profile_shop_page.dart:564`专项《会员服务协议》《用户充值协议》点击Toast暂不可查看 | 付费入口仍是占位。这是产品已显示入口却无内容的2.1完整性缺陷，不是断言全部消耗型法定必须独立专项条款。需兑现已显示入口或经产品确认调整其呈现；不以任意复用隐私URL充当专项协议 |
| REVIEW-05 / P2待决策 | `AuthMockRepository._purgeAccount`清理AccountMock私有文件，独立 `purchases/apple_ledger.json`仍保留accountId/token/交易账本 | 注销与支付留存边界需明确政策和最小数据保留；不能为清空账号盲删去重记录导致重放发放。7日内恢复/恰到期换ID测试已覆盖客户端契约，App未运行时无服务器清理任务 |

REVIEW-01–03是产品范围和上线依赖，不是由tester自行补造后端或删入口可以安全解决的局部修复；已即时向主Agent派发。静态发现的正式协议占位与付费承诺均未声称已设备复现。

## 支付专项核查

本机验证读取StoreKit `.verified` 后核对bundle、商品、consumable、数量1、无revocation与appAccountToken；Dart校验商品/环境/时间、按原token找所有者，环境+交易ID去重，原子提交后controller才complete。不能用Dart回调purchased代替验签。已覆盖迟到归原账号、双回调/重启/并发、Sandbox/Production独立、文件损坏及失败重试；这些通过支持客户端记账约束，不替代原生交易证据。

六商品全部消耗型，不机械套用自动续期订阅的恢复及订阅披露要求。源码只有unfinished补单/重试，没有完整跨设备Restore；不能将“重试确认”宣传为重装恢复全部余额。已完成消耗型本身不承诺StoreKit恢复；但当前会员以消耗型时长与本机账本实现，换机/卸载丢失、系统时间影响有效期、已发权益退款冲正均未完成，需对购买者明确限制并评估适合的商品类型。不能因无业务后端就直接认定StoreKit本机验证非法，也不能从账本测试推断真实沙盒通过。

## 正式包、权限与元数据

- UME/日志由环境define控制，默认false；本轮未见正式开启模拟接通按钮。支付Xcode/Sandbox余额有测试标识，Production独立，仍应由最终归档配置核实ENABLE_UME/ENABLE_LOG未开启。
- Info.plist声明相册与麦克风用途。当前录音和选图使用路径与文案相符；没有拍照路径不能仅因无Camera usage就判缺陷。权限拒绝/重试硬件本轮未执行。
- Release产物包含依赖PrivacyInfo.xcprivacy；不能因Runner无独立manifest就判断缺失。App Store隐私问卷、年龄分级、UGC审核、数据处理、商品价格资料及审核备注不在仓库可完整核实范围，需有实际ASC配置证据。
- 用户协议/隐私政策为腾讯文档URL，根Agent工具无法读取正文，仅能记原生WebView与内容待核实，不能推断用户打不开。专项协议则源码明确占位，性质不同。
- 本地StoreKitTest由developer在隔离模拟器执行，真正Sandbox/TestFlight未验证；未在已连接真机上执行安装/购买，真实Sandbox会话尚未建立，原生运行先用隔离Simulator；不接触用户账户。

已完成：本轮全量/重点静态、账本契约审计、正式入口/条款/权限源码检查、P1即时派发。
未完成：收费权益用途与治理/社交正式服务，专项协议，商店元数据证据；详见阻断表。
未验证：真实Sandbox完整交易与退款、App Store实际配置、权限硬件、真机视觉及长时稳定性；本轮不以用户不测试为由假填通过。
下一步：根Agent核对已派阻断，developer完成隔离StoreKitTest；修复后按变更定向回归。产品阻断未解决前不能建议收费真人社交产品提交，更不能保证审核通过。

## 用户最新收窄：本轮仅购买入口与商品加载

用户后续明确本轮只保证购买页能查询正确商品并发起系统购买，不要求本轮补全其他业务。以上完整产品风险保留作交接，不能把这些广泛P1替换为本轮客户端链路失败。最新范围为：进入页自动重试商品查询、部分商品返回时已找到的仍可买、正确productId/ProductDetails、UUID appAccountToken以及iOS系统购买发起路径。

独立源码确认 canBuy 检查iOS、已登录、验证器配置、商店可用、非加载/购买/未完成恢复状态和选中商品存在；gateway使用Apple返回的ProductDetails及Sk2PurchaseParam appAccountToken发起buyConsumable，数字Apple ID仅供后台对照。六款productId为 `youbanliao.coins.60/320/820`、`youbanliao.vip.1months/3months/12months`，不把数字Apple ID作为购买ID。价格展示使用Apple商品price，不把设计参考价传入购买。

发现进页前早期查询失败后原页面没有主动重载，已向主Agent提交客户端改进；待其修复后独立定向回归。真实ASC商品是否属于当前签名团队、地区及可售状态不在本机源码中可证明，因此无法保证任意审核员商店环境均可查询成功。隔离StoreKitTest不是Apple Sandbox；后续原生结果应按此界限报告。

原生独立核对 `native-storekit-final.log`：iOS26.1 Simulator / Xcode本地StoreKitTest，3项实际运行1通过2失败。退款拒绝项通过；六档正向用例在首笔bridge返回非Dictionary，缺token用例得到transaction_not_found而不是期望transaction_unverified。不能把这些not_found负向响应记作真实verified成功。本轮未执行Dart页面到系统面板整链；主Agent安排唯一追加诊断以区分本地测试交易来源/原生验证路径，不盲目放宽验证或将unverified当成功。前两轮native-storekit.log/retry是测试target版本和API类型编译问题，保留但不当业务运行失败。

### 最新窄范围修复后独立结论

主Agent修复后独立执行 `flutter test --no-pub test/apple_purchase_test.dart test/main_tabs_mock_test.dart --reporter expanded` **29/29通过，退出0**，见 [购买页回归](submission-audit-2026-11-18/purchase-entry-regression.log)。`flutter analyze --no-pub lib/features/purchases lib/features/user/presentation/pages/profile_shop_page.dart test/apple_purchase_test.dart test/main_tabs_mock_test.dart` **无问题**，见 [定向分析](submission-audit-2026-11-18/purchase-entry-analyze.log)。本轮没有再次扩全量，前文96项为补丁前工作区证据。

实际验证：查询瞬时失败有限重试、最多3次（500/1000ms退避）；成功后替换商品缓存，临时刷新失败保留当次启动已返回的真实Apple ProductDetails；冷启动无商品禁止付款，部分结果只让有效商品可买；进页自动查询调用至少两次已有Widget断言。恢复前台刷新与busy/loading跳过为源码核查，没有额外设备生命周期执行。若进页恰逢已有loading会跳过本次触发，加载内部仍最多3次尝试，最终失败保留明确手动刷新入口；不能保证无网络/ASC未配置也成功。

[原生StoreKitTest结果](submission-audit-2026-11-18/native-storekit-results.md) 由developer执行，tester独立核对日志：追加诊断有一笔coins60、交易ID0本地桥接verified成功，Xcode环境及商品/交易/token匹配；紧接coins320 ID1返回transaction_not_found，后四款未执行。首轮正式3项仍1过2失败。因而结论是“一笔本地Swift验证已执行成功，六档全链未通过”，不能改称六款App Store Connect查询或Dart系统支付面板均验证成功。这不提供实际Sandbox、ASC销售地区/团队匹配或购买面板证据。

**本轮客户端购买链路改动自动化通过；真实Apple商店商品查询和系统面板仍缺实际运行证据，不作保证可买结论。** 本地测试发现的交易查找失败保留为原生验证未闭环限制，未通过放宽验证强行成功。广泛产品审计风险保留历史交接，不作为用户最新收窄范围的额外实现要求。

### 最终购买页发布构建与交接

主Agent执行 `flutter build ios --no-codesign --release --no-pub` 成功，Xcode 91.2秒，118.8MB，证据 [购买页Release构建](submission-audit-2026-11-18/purchase-entry-build-ios.log)。产物中未发现 NativePurchases.storekit 或 RunnerTests 测试资源，未将本地StoreKit配置绑定正式Run/Release Scheme；用户商品仍经真实StoreKit查询。git diff --check通过。此为无签名编译和测试资源排除证据，不证明正式团队签名、ASC可查询或审核员支付面板可用。

本轮已修客户端自动查询/有限重试/缓存保护并独立回归；未完成的是可用正式签名环境下的真实商品查询及系统面板运行验证。用户已表示不自行测试，本报告不把这些未测项写为通过，也不要求以用户手测代替本轮证据。后续若接通正式签名的设备/测试环境，再由测试执行实际链路；当前环境不能保证审核员一定不会遇到商店查询失败。原生本地六档未全部通过的结果保留，不通过隐藏错误或伪造商品来满足表面展示。
