import Flutter
import StoreKit
import StoreKitTest
import XCTest
@testable import Runner

@available(iOS 17.0, *)
@MainActor
final class RunnerTests: XCTestCase {
  private var session: SKTestSession!
  private let products = [
    "youbanliao.coins.60", "youbanliao.coins.320", "youbanliao.coins.820",
    "youbanliao.vip.1months", "youbanliao.vip.3months", "youbanliao.vip.12months"
  ]

  override func setUpWithError() throws {
    let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "NativePurchases", withExtension: "storekit"))
    session = try SKTestSession(contentsOf: url)
    session.disableDialogs = true
    session.clearTransactions()
  }

  override func tearDownWithError() throws {
    session.clearTransactions()
    session = nil
  }

  private func verify(_ transaction: StoreKit.Transaction, product: String? = nil) async -> Any? {
    await withCheckedContinuation { continuation in
      LocalApplePurchaseVerifier().handle(
        FlutterMethodCall(methodName: "verifyTransaction", arguments: [
          "transactionId": String(transaction.id),
          "productId": product ?? transaction.productID
        ])
      ) { continuation.resume(returning: $0) }
    }
  }

  func testSixProductsWithAccountTokenVerifyThroughBridge() async throws {
    let token = UUID()
    for product in products {
      let transaction = try await session.buyProduct(identifier: product, options: [.appAccountToken(token)])
      let bridgeResult = await verify(transaction)
      print("NATIVE_BRIDGE_RESULT product=\(product) transaction=\(transaction.id) token=\(String(describing: transaction.appAccountToken)) errorCode=\((bridgeResult as? FlutterError)?.code ?? "none") errorMessage=\((bridgeResult as? FlutterError)?.message ?? "none")")
      let result = try XCTUnwrap(bridgeResult as? [String: Any])
      XCTAssertEqual(result["transactionId"] as? String, String(transaction.id))
      XCTAssertEqual(result["productId"] as? String, product)
      XCTAssertEqual(result["accountToken"] as? String, token.uuidString.lowercased())
      XCTAssertEqual(result["environment"] as? String, "Xcode")
      print("NATIVE_VERIFIED \(product) transaction=\(transaction.id) environment=Xcode")
      await transaction.finish()
    }
  }

  func testWrongProductAndMissingTokenRejected() async throws {
    let transaction = try await session.buyProduct(identifier: products[0], options: [.appAccountToken(UUID())])
    let wrong = await verify(transaction, product: products[1])
    XCTAssertEqual((wrong as? FlutterError)?.code, "transaction_unverified")
    await transaction.finish()
    let missing = try await session.buyProduct(identifier: products[2])
    let result = await verify(missing)
    XCTAssertEqual((result as? FlutterError)?.code, "transaction_unverified")
    await missing.finish()
  }

  func testRevokedTransactionRejected() async throws {
    let transaction = try await session.buyProduct(identifier: products[0], options: [.appAccountToken(UUID())])
    try session.refundTransaction(identifier: UInt(transaction.id))
    try await Task.sleep(nanoseconds: 500_000_000)
    let result = await verify(transaction)
    XCTAssertEqual((result as? FlutterError)?.code, "transaction_unverified")
  }
}
