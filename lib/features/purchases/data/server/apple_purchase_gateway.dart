import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

abstract class ApplePurchaseGateway {
  Stream<List<PurchaseDetails>> get updates;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> query(Set<String> ids);
  Future<List<PurchaseDetails>> unfinished();
  bool isConsumable(ProductDetails product);
  Future<bool> buy(ProductDetails product, String accountToken);
  Future<void> complete(PurchaseDetails purchase);
}

/// 当前 iOS 最低版本 15.6，使用插件默认 StoreKit 2。
class StoreKitPurchaseGateway implements ApplePurchaseGateway {
  InAppPurchase get _iap => InAppPurchase.instance;
  @override
  Stream<List<PurchaseDetails>> get updates => _iap.purchaseStream;
  @override
  Future<bool> isAvailable() => _iap.isAvailable();
  @override
  Future<ProductDetailsResponse> query(Set<String> ids) =>
      _iap.queryProductDetails(ids);
  @override
  Future<List<PurchaseDetails>> unfinished() async =>
      (await SK2Transaction.unfinishedTransactions())
          .map(
            (t) => SK2PurchaseDetails(
              productID: t.productId,
              purchaseID: t.id.toString(),
              transactionDate: t.purchaseDate,
              status: PurchaseStatus.purchased,
              appAccountToken: t.appAccountToken,
              verificationData: PurchaseVerificationData(
                localVerificationData: t.jsonRepresentation ?? '',
                serverVerificationData: t.receiptData ?? '',
                source: 'app_store',
              ),
            ),
          )
          .toList();
  @override
  bool isConsumable(ProductDetails product) =>
      product is AppStoreProduct2Details &&
      product.sk2Product.type == SK2ProductType.consumable;
  @override
  Future<bool> buy(ProductDetails product, String accountToken) =>
      _iap.buyConsumable(
        purchaseParam: Sk2PurchaseParam(
          productDetails: product,
          applicationUserName: accountToken,
        ),
      );
  @override
  Future<void> complete(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}
