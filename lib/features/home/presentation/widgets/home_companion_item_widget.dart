import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import 'package:flutter/material.dart';

import '../../data/model/home_model.dart';
import 'home_companion_card_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../messages/presentation/providers/messages_provider.dart';
import '../../../../shared/widgets/feedback/app_toast.dart';

class HomeCompanionItemWidget extends ConsumerWidget {
  const HomeCompanionItemWidget({super.key, required this.person});

  final HomeCompanionModel person;

  @override
  Widget build(BuildContext context, WidgetRef ref) => HomeCompanionCardWidget(
    person: person,
    onInvite: () {
      final id = ref
          .read(messagesProvider.notifier)
          .greet(person.name, person.avatar, peerId: person.id);
      if (id == null) {
        AppToast.show('请先解除黑名单');
        return;
      }
      AppNavigator.pushNamed<void>(context, RouteNames.chat(id), arguments: id);
    },
    inviteLabel: '打招呼',
    onProfile: () => AppNavigator.pushNamed<void>(
      context,
      RouteNames.userDetail(person.id),
      arguments: person.id,
    ),
  );
}
