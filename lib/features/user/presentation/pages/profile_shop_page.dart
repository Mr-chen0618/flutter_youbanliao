import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../../shared/widgets/images/app_image.dart';

const _ink = Color(0xFF333333);
const _muted = Color(0xFF999999);
const _yellow = Color(0xFFFFCE45);
const _gold = Color(0xFFD18F1F);

/// 从「我的」进入会员中心，并预览设计中的会员套餐与权益。
class MembershipCenterPage extends StatelessWidget {
  const MembershipCenterPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const _ProfileShopPage(shop: _Shop.membership);
}

/// 从「我的」进入金币充值，显示当前本地余额和可选充值档位。
class CoinRechargePage extends StatelessWidget {
  const CoinRechargePage({super.key, required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) =>
      _ProfileShopPage(shop: _Shop.coins, balance: balance);
}

enum _Shop {
  membership(
    title: '会员中心',
    action: '立即开通',
    agreementLead: '开通即表示同意',
    agreement: '《会员服务协议》',
    unavailable: '会员开通暂不可用',
    defaultIndex: 2,
    options: [
      _ShopOption(1, 18),
      _ShopOption(3, 48, monthlyPrice: '16'),
      _ShopOption(12, 138, monthlyPrice: '11.5'),
    ],
  ),
  coins(
    title: '金币充值',
    action: '立即充值',
    agreementLead: '充值即代表你已同意',
    agreement: '《用户充值协议》',
    unavailable: '金币充值暂不可用',
    defaultIndex: 0,
    options: [_ShopOption(60, 6), _ShopOption(320, 30), _ShopOption(820, 80)],
  );

  const _Shop({
    required this.title,
    required this.action,
    required this.agreementLead,
    required this.agreement,
    required this.unavailable,
    required this.defaultIndex,
    required this.options,
  });

  final String title;
  final String action;
  final String agreementLead;
  final String agreement;
  final String unavailable;
  final int defaultIndex;
  final List<_ShopOption> options;

  bool get isMembership => this == membership;
}

/// 画板中的展示档位，金额不用于交易。
class _ShopOption {
  const _ShopOption(this.count, this.price, {this.monthlyPrice});

  final int count;
  final int price;
  final String? monthlyPrice;
}

/// 两页共用导航、选项及操作区，保留各自的卡片内容和默认选择。
class _ProfileShopPage extends StatefulWidget {
  const _ProfileShopPage({required this.shop, this.balance = 0});

  final _Shop shop;
  final int balance;

  @override
  State<_ProfileShopPage> createState() => _ProfileShopPageState();
}

class _ProfileShopPageState extends State<_ProfileShopPage> {
  late int _selected = widget.shop.defaultIndex;

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              child: _asset('backdrop.png', height: 255.h, fit: BoxFit.fill),
            ),
            SafeArea(
              child: Column(
                children: [
                  // 导航与当前页标题。
                  SizedBox(
                    height: 48.h,
                    child: NavigationToolbar(
                      leading: IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () => Navigator.maybePop(context),
                        icon: _asset('back.svg', width: 24.r, height: 24.r),
                      ),
                      middle: Text(
                        shop.title,
                        style: TextStyle(color: _ink, fontSize: 16.sp),
                      ),
                      centerMiddle: true,
                    ),
                  ),
                  // 内容在小屏和大字体下独立滚动。
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                      children: [
                        _ShopHero(shop: shop, balance: widget.balance),
                        SizedBox(height: shop.isMembership ? 40.h : 16.h),
                        for (final (index, option) in shop.options.indexed) ...[
                          if (index > 0) SizedBox(height: 12.h),
                          _ShopOptionTile(
                            shop: shop,
                            option: option,
                            selected: index == _selected,
                            onTap: () => setState(() => _selected = index),
                          ),
                        ],
                        if (shop.isMembership) const _MemberBenefits(),
                      ],
                    ),
                  ),
                  _ShopFooter(shop: shop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 会员卡与余额卡的图层均来自 Figma，文本来自当前页面状态。
class _ShopHero extends StatelessWidget {
  const _ShopHero({required this.shop, required this.balance});

  final _Shop shop;
  final int balance;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: 102.h),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: _asset('hero.svg', fit: BoxFit.fill)),
        if (shop.isMembership)
          Positioned(
            right: 24.w,
            top: 15.h,
            child: _asset('member_badge.png', width: 60.r, height: 54.r),
          )
        else ...[
          Positioned(
            right: 44.w,
            top: 81.h,
            child: _asset('coin_shadow.png', width: 44.r, height: 14.r),
          ),
          Positioned(
            right: 19.w,
            top: -14.h,
            child: _asset('coin_balance.png', width: 95.r, height: 95.r),
          ),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(18.w, 18.h, 118.w, 18.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shop.isMembership) ...[
                Text(
                  '友伴聊 VIP',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '开通会员，享专属社交礼遇',
                  style: TextStyle(
                    color: const Color(0xFF614A1A),
                    fontSize: 13.sp,
                  ),
                ),
              ] else ...[
                Text(
                  '金币余额',
                  style: TextStyle(
                    color: const Color(0xFFC2971C),
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$balance',
                  style: TextStyle(
                    color: const Color(0xFF342600),
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// 选中态按当前交互更新，读屏可辨别选中套餐。
class _ShopOptionTile extends StatelessWidget {
  const _ShopOptionTile({
    required this.shop,
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final _Shop shop;
  final _ShopOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final monthlyPrice = option.monthlyPrice;
    final radius = BorderRadius.circular(20.r);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? const Color(0xFFFFF9E8) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? _yellow : const Color(0xFFF1F1F1),
            width: shop.isMembership ? 1.w : 2.w,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 68.h),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
              child: Row(
                children: [
                  if (shop.isMembership)
                    SizedBox.square(
                      dimension: 36.r,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _asset('duration.svg', width: 36.r, height: 36.r),
                          Text(
                            '${option.count}',
                            style: TextStyle(color: _gold, fontSize: 14.sp),
                          ),
                        ],
                      ),
                    )
                  else
                    _asset('coin_package.png', width: 36.r, height: 36.r),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: shop.isMembership
                        ? Text(
                            '${option.count}个月会员',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : Text.rich(
                            TextSpan(
                              text: '${option.count}',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: ' (金币)',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  SizedBox(width: 6.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¥${option.price}',
                        style: TextStyle(
                          color: _ink,
                          fontSize: shop.isMembership ? 18.sp : 20.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (monthlyPrice != null) ...[
                        SizedBox(height: 3.h),
                        Text(
                          '¥$monthlyPrice/月',
                          style: TextStyle(color: _muted, fontSize: 11.sp),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 会员权益区展示画板中的两列条目。
class _MemberBenefits extends StatelessWidget {
  const _MemberBenefits();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 16.h),
      Text(
        '会员专属权益',
        style: TextStyle(
          color: _ink,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: 6.h),
      Container(
        constraints: BoxConstraints(minHeight: 124.h),
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFF1F1F1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _benefit('会员专属标识')),
                Expanded(child: _benefit('更多聊天机会')),
              ],
            ),
            SizedBox(height: 22.h),
            Row(
              children: [
                Expanded(child: _benefit('优先推荐曝光')),
                Expanded(child: _benefit('专属客服支持')),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _benefit(String label) => Row(
    children: [
      _asset('benefit_dot.svg', width: 8.r, height: 8.r),
      SizedBox(width: 8.w),
      Expanded(
        child: Text(
          label,
          style: TextStyle(color: _ink, fontSize: 13.sp),
        ),
      ),
    ],
  );
}

/// 底部操作延用全局反馈，支付和专用协议配置到位后可接入。
class _ShopFooter extends StatelessWidget {
  const _ShopFooter({required this.shop});
  final _Shop shop;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
    child: Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: Size(0, 52.h),
              backgroundColor: _yellow,
              foregroundColor: shop.isMembership ? _ink : Colors.black,
              textStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => AppToast.show(shop.unavailable),
            child: Text(shop.action),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              shop.agreementLead,
              style: TextStyle(color: Colors.black, fontSize: 11.sp),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC99011),
                textStyle: TextStyle(fontSize: 11.sp),
                padding: EdgeInsets.zero,
                minimumSize: Size(0, 28.h),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => AppToast.show('协议暂不可查看'),
              child: Text(shop.agreement),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _asset(
  String name, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
}) => AppImage(
  src: 'assets/profile/profile_shop_$name',
  width: width,
  height: height,
  fit: fit,
);
