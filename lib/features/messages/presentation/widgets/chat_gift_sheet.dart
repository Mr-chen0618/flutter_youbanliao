import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/navigation/app_navigator.dart';
import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../purchases/presentation/providers/apple_purchase_provider.dart';
import '../../../user/presentation/pages/profile_shop_page.dart';
import '../../data/model/chat_gift.dart';
import '../../data/model/chat_entry.dart';
import '../providers/messages_provider.dart';

class ChatGiftSheet extends ConsumerStatefulWidget {
  const ChatGiftSheet({
    super.key,
    required this.threadId,
    required this.onSent,
  });
  final String threadId;
  final ValueChanged<ChatEntry> onSent;
  @override
  ConsumerState<ChatGiftSheet> createState() => _ChatGiftSheetState();
}

class _ChatGiftSheetState extends ConsumerState<ChatGiftSheet> {
  late final _catalog = ref.read(chatGiftRepositoryProvider).catalog();
  int _selected = 0, _quantity = 1;
  bool _sending = false;
  @override
  Widget build(BuildContext context) {
    final purchase = ref.watch(applePurchaseStateProvider).value;
    final accountId = ref.watch(authSessionProvider).value?.accountId;
    final balance = purchase?.entitlements[accountId]?.coinBalance ?? 0;
    return SafeArea(
      top: false,
      child: FutureBuilder<List<ChatGift>>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return SizedBox(
              height: 150.h,
              child: const Center(
                child: Text(
                  '礼物加载失败，请关闭后重试',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }
          final gifts = snapshot.data;
          if (gifts == null) {
            return SizedBox(
              height: 150.h,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '礼物',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gifts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisExtent: 92.h,
                      crossAxisSpacing: 5.w,
                      mainAxisSpacing: 6.h,
                    ),
                    itemBuilder: (_, index) {
                      final gift = gifts[index];
                      return InkWell(
                        onTap: _sending
                            ? null
                            : () => setState(() => _selected = index),
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selected == index
                                ? const Color(0xFF3D3622)
                                : Colors.transparent,
                            border: Border.all(
                              color: _selected == index
                                  ? const Color(0xFFFFD152)
                                  : Colors.transparent,
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppImage(
                                src: gift.asset,
                                width: 44.r,
                                height: 44.r,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                gift.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppImage(
                                    src:
                                        'assets/profile/profile_shop_coin_balance.png',
                                    width: 10.r,
                                    height: 10.r,
                                    fit: BoxFit.contain,
                                  ),
                                  Text(
                                    ' ${gift.coins}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      AppImage(
                        src: 'assets/profile/profile_shop_coin_balance.png',
                        width: 20.r,
                        height: 20.r,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          '$balance',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFFFD854),
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _sending
                            ? null
                            : () async {
                                await AppNavigator.push(
                                  context,
                                  page: CoinRechargePage(balance: balance),
                                );
                                if (mounted && accountId != null) {
                                  await ref
                                      .read(applePurchaseControllerProvider)
                                      .refreshEntitlements(accountId);
                                }
                              },
                        child: const Text(
                          '充值',
                          style: TextStyle(color: Color(0xFFFFD854)),
                        ),
                      ),
                      DropdownButton<int>(
                        value: _quantity,
                        dropdownColor: const Color(0xFF333333),
                        underline: const SizedBox.shrink(),
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                        items: [1, 10, 66, 99, 520, 1314]
                            .map(
                              (n) =>
                                  DropdownMenuItem(value: n, child: Text('$n')),
                            )
                            .toList(),
                        onChanged: _sending
                            ? null
                            : (v) => setState(() => _quantity = v!),
                      ),
                      SizedBox(width: 8.w),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD152),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _sending
                            ? null
                            : () => _send(gifts[_selected]),
                        child: Text(_sending ? '赠送中' : '赠送'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _send(ChatGift gift) async {
    final accountId = ref.read(authSessionProvider).value?.accountId;
    if (accountId == null) {
      AppToast.show('请先登录');
      return;
    }
    if (!ref
        .read(messagesProvider)
        .threads
        .any((t) => t.id == widget.threadId)) {
      AppToast.show('当前会话不可用');
      return;
    }
    setState(() => _sending = true);
    try {
      final entry = await ref
          .read(chatGiftRepositoryProvider)
          .send(
            accountId: accountId,
            requestId: DateTime.now().microsecondsSinceEpoch.toString(),
            threadId: widget.threadId,
            gift: gift,
            quantity: _quantity,
          );
      if (!mounted ||
          ref.read(authSessionProvider).value?.accountId != accountId) {
        return;
      }
      widget.onSent(entry);
      await ref
          .read(applePurchaseControllerProvider)
          .refreshEntitlements(accountId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.show(e is StateError ? e.message.toString() : '赠送失败，请重试');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
