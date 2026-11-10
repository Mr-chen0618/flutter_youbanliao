import 'package:flutter/material.dart';

import '../../../../shared/form/widgets/app_text_field.dart';

class HomeSearchDialogWidget extends StatefulWidget {
  const HomeSearchDialogWidget({super.key, required this.query});
  final String query;

  @override
  State<HomeSearchDialogWidget> createState() => _HomeSearchDialogWidgetState();
}

class _HomeSearchDialogWidgetState extends State<HomeSearchDialogWidget> {
  late final _controller = TextEditingController(text: widget.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('搜索'),
    content: AppTextField(
      controller: _controller,
      hint: '搜索活动、用户',
      autofocus: true,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (value) => Navigator.pop(context, value),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, ''),
        child: const Text('清除'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('搜索'),
      ),
    ],
  );
}
