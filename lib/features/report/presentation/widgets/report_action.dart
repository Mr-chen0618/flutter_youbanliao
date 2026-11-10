import 'package:flutter/material.dart';
import '../../../../app/navigation/app_navigator.dart';
import '../../../../shared/widgets/feedback/app_action_sheet.dart';
import '../pages/report_page.dart';

/// 用户与活动详情复用举报操作面板，保留目标身份和内容快照。
Future<void> showReportActions(
  BuildContext context, {
  required String targetId,
  required String targetType,
  required String targetName,
  String? targetAvatar,
  String? targetSummary,
}) async {
  final selected = await showAppActionSheet<String>(
    context,
    actions: const [
      AppSheetAction(value: 'report', label: '举报', isDestructive: true),
    ],
  );
  if (selected != 'report' || !context.mounted) return;
  await AppNavigator.push<void>(
    context,
    page: ReportPage(
      targetId: targetId,
      targetType: targetType,
      targetName: targetName,
      targetAvatar: targetAvatar,
      targetSummary: targetSummary,
    ),
  );
}
