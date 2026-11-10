import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/layout/companion_page_surface.dart';
import '../widgets/activity_form_widget.dart';
import '../providers/activity_publication_provider.dart';

/// 首页「发布」入口对应的创建搭子页面。
class ActivityPublishPage extends ConsumerWidget {
  const ActivityPublishPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => CompanionPageSurface(
    title: '创建搭子',
    child: ActivityFormWidget(onSubmit: ref.read(publishActivityProvider)),
  );
}
