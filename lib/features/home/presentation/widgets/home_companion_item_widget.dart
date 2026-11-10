import '../../../../app/navigation/app_navigator.dart';
import '../../../../app/navigation/route_names.dart';
import 'package:flutter/material.dart';

import '../../data/model/home_model.dart';
import 'home_companion_card_widget.dart';
import '../../../activity/presentation/widgets/activity_invite_action_widget.dart';

class HomeCompanionItemWidget extends StatelessWidget {
  const HomeCompanionItemWidget({super.key, required this.person});

  final HomeCompanionModel person;

  @override
  Widget build(BuildContext context) => ActivityInviteActionWidget(
    personId: person.id,
    isInvited: person.isInvited,
    builder: (onInvite, label) => HomeCompanionCardWidget(
      person: person,
      onInvite: onInvite,
      inviteLabel: label,
      onProfile: () => AppNavigator.pushNamed<void>(
        context,
        RouteNames.userDetail(person.id),
        arguments: person.id,
      ),
    ),
  );
}
