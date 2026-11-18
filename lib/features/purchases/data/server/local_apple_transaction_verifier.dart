import 'package:flutter/services.dart';

/// 只接受原生 StoreKit 的 verified 结果；Dart 交易状态不作为付款证明。
class VerifiedAppleTransaction {
  const VerifiedAppleTransaction({
    required this.transactionId,
    required this.productId,
    required this.accountToken,
    required this.environment,
    required this.purchaseDate,
  });
  final String transactionId;
  final String productId;
  final String accountToken;
  final String environment;
  final DateTime purchaseDate;
}

abstract class LocalAppleTransactionVerifier {
  Future<VerifiedAppleTransaction> verify(
    String transactionId,
    String productId,
  );
}

class StoreKitLocalTransactionVerifier
    implements LocalAppleTransactionVerifier {
  static const _channel = MethodChannel(
    'youbanliao/apple_purchase_verification',
  );

  @override
  Future<VerifiedAppleTransaction> verify(
    String transactionId,
    String productId,
  ) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'verifyTransaction',
      {'transactionId': transactionId, 'productId': productId},
    );
    if (result == null ||
        result['transactionId'] != transactionId ||
        result['productId'] != productId ||
        result['accountToken'] is! String ||
        (result['accountToken'] as String).isEmpty ||
        !const {
          'Production',
          'Sandbox',
          'Xcode',
        }.contains(result['environment']) ||
        result['purchaseDateMs'] is! num) {
      throw StateError('苹果交易验证结果不完整');
    }
    return VerifiedAppleTransaction(
      transactionId: transactionId,
      productId: productId,
      accountToken: (result['accountToken'] as String).toLowerCase(),
      environment: result['environment'] as String,
      purchaseDate: DateTime.fromMillisecondsSinceEpoch(
        (result['purchaseDateMs'] as num).toInt(),
        isUtc: true,
      ),
    );
  }
}
