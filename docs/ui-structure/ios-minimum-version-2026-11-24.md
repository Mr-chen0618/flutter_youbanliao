# 2026-11-24 iOS 最低版本配置

范围：用户反馈打包提交提示缺少最低版本配置；未提供原始错误文本，具体报错来源尚未确定。

已完成：沿用 Runner 与 Flutter AppFrameworkInfo.plist 现有 iOS 15.6，启用 Podfile 的 platform 配置，将工程级 Debug/Profile/Release 的 13.0 统一为 15.6；Runner/Info.plist 新增 MinimumOSVersion，引用 $(IPHONEOS_DEPLOYMENT_TARGET)，避免重复维护字面值。保留 Info.plist 其他已有未提交修改。

涉及文件：ios/Podfile、ios/Runner/Info.plist、ios/Runner.xcodeproj/project.pbxproj。无页面或数据契约变更。

验证：macOS 下 plutil -lint 检查两份 plist 和 project.pbxproj 通过；ruby -c ios/Podfile 通过；上述三个配置文件 git diff --check 通过。xcodebuild -project ios/Runner.xcodeproj -target Runner -configuration Release -showBuildSettings 的输出见 [构建设置日志](../testing/ios-minimum-version-2026-11-24/build-settings.log)。

未完成/未验证：未重新生成签名 Archive、未上传 App Store Connect，不能宣称提交校验已通过；未运行业务测试，本次仅修改原生打包元数据。

构建设置检查限制：本次 xcodebuild 无法写入沙箱外的默认 DerivedData/PIFCache，未能取得最终有效构建设置；日志另含模拟器服务及签名描述文件加载警告。本轮仅确认配置文件语法及源码值一致，不作为构建成功证据。

下一步：重新打包并检查最终 Runner.app/Info.plist 的 MinimumOSVersion 为 15.6，再执行上传校验；若仍报错，根据完整错误中的 bundle/framework 路径继续定位。
