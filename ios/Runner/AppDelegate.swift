import Flutter
import UIKit
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPluginRegistrant {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Flutter 3.35 的 Scene 隐式引擎在创建后通过此注册器绑定插件。
    // 此时不向尚未建立的 Scene 根控制器提前注册插件。
    pluginRegistrant = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func register(with registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)
    if let registrar = registry.registrar(forPlugin: "LocalApplePurchaseVerifier") {
      LocalApplePurchaseVerifier.register(with: registrar)
    }
  }
}

/// 直接查询 Apple 交易并要求 verified，不信任 Dart 回调状态或客户端解码的 JSON。
final class LocalApplePurchaseVerifier: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "youbanliao/apple_purchase_verification", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(LocalApplePurchaseVerifier(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "verifyTransaction" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any],
      let idString = args["transactionId"] as? String, let id = UInt64(idString),
      let productID = args["productId"] as? String else {
      result(FlutterError(code: "invalid_transaction", message: "交易信息不完整", details: nil))
      return
    }
    Task { @MainActor in
      do {
        // 新购及补单首先从 unfinished 查询，避免依赖已消费商品的恢复能力。
        for await verification in StoreKit.Transaction.unfinished {
          if verification.unsafePayloadValue.id == id {
            result(try Self.checked(verification, productID: productID))
            return
          }
        }
        for await verification in StoreKit.Transaction.all {
          if verification.unsafePayloadValue.id == id {
            result(try Self.checked(verification, productID: productID))
            return
          }
        }
        result(FlutterError(code: "transaction_not_found", message: "未找到苹果交易，请重试", details: nil))
      } catch {
        result(FlutterError(code: "transaction_unverified", message: "苹果交易验证未通过", details: nil))
      }
    }
  }

  private static func checked(
    _ verification: VerificationResult<StoreKit.Transaction>, productID: String
  ) throws -> [String: Any] {
    guard case .verified(let transaction) = verification,
      transaction.productID == productID, transaction.productType == .consumable,
      transaction.purchasedQuantity == 1, transaction.revocationDate == nil,
      let token = transaction.appAccountToken else {
      throw VerificationFailure.invalid
    }
    // 这里只读取已通过 StoreKit 验证的 JWS，不将解码本身当成验签。
    let parts = verification.jwsRepresentation.split(separator: ".")
    guard parts.count == 3 else { throw VerificationFailure.invalid }
    var payload = String(parts[1]).replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
    guard let bytes = Data(base64Encoded: payload),
      let fields = try JSONSerialization.jsonObject(with: bytes) as? [String: Any],
      let bundleID = fields["bundleId"] as? String,
      bundleID == Bundle.main.bundleIdentifier,
      let environment = fields["environment"] as? String,
      ["Production", "Sandbox", "Xcode"].contains(environment) else {
      throw VerificationFailure.invalid
    }
    return [
      "transactionId": String(transaction.id), "productId": transaction.productID,
      "accountToken": token.uuidString.lowercased(), "environment": environment,
      "purchaseDateMs": Int64(transaction.purchaseDate.timeIntervalSince1970 * 1000)
    ]
  }

  private enum VerificationFailure: Error { case invalid }
}
