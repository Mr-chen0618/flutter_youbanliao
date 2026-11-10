import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSheetAction<T extends Object> {
  const AppSheetAction({
    required this.value,
    required this.label,
    this.isDestructive = false,
  });

  final T value;
  final String label;
  final bool isDestructive;
}

/// Displays a list of choices and returns null when the sheet is dismissed.
Future<T?> showAppActionSheet<T extends Object>(
  BuildContext context, {
  required List<AppSheetAction<T>> actions,
}) => showModalBottomSheet<T>(
  context: context,
  backgroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
  ),
  clipBehavior: Clip.antiAlias,
  builder: (sheet) => SafeArea(
    top: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in actions)
          _ActionRow(
            label: action.label,
            isDestructive: action.isDestructive,
            onTap: () => Navigator.pop(sheet, action.value),
          ),
        SizedBox(
          height: 8.h,
          child: const ColoredBox(color: Color(0xFFF8F8F8)),
        ),
        _ActionRow(label: '取消', onTap: () => Navigator.pop(sheet)),
      ],
    ),
  ),
);

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: 54.h),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isDestructive
                ? const Color(0xFFDB6464)
                : const Color(0xFF333333),
            fontSize: 16.sp,
          ),
        ),
      ),
    ),
  );
}
