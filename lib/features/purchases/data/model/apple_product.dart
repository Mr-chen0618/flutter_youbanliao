/// App Store Connect 商品目录。购买使用 productId，Apple ID 仅用于后台核对。
enum AppleProduct {
  coins60('youbanliao.coins.60', '6836163432', 60, 6),
  coins320('youbanliao.coins.320', '6836168415', 320, 30),
  coins820('youbanliao.coins.820', '6836168845', 820, 80),
  vip1('youbanliao.vip.1months', '6836201153', 1, 18),
  vip3('youbanliao.vip.3months', '6836203469', 3, 48),
  vip12('youbanliao.vip.12months', '6836206383', 12, 138);

  const AppleProduct(
    this.productId,
    this.appleId,
    this.quantity,
    this.previewPrice,
  );
  final String productId;
  final String appleId;
  final int quantity;

  /// 设计中的离线展示价，不传给 Apple，也不用于权益发放。
  final int previewPrice;
  bool get isMembership => name.startsWith('vip');

  static AppleProduct? find(String id) {
    for (final product in values) {
      if (product.productId == id) return product;
    }
    return null;
  }
}
