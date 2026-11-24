import '../../../../shared/widgets/layout/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/messages_page_surface.dart';

/// 动态通知为空时复用全应用统一空列表插画。
class DynamicNotificationsPage extends StatelessWidget {
  const DynamicNotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => MessagesPageSurface(
    title: '动态通知',
    child: Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 40.h),
        child: const AppEmptyState(message: '暂无新通知'),
      ),
    ),
  );
}
