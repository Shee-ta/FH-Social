
import 'package:flutter/material.dart';
import 'package:frontend/entity/user.dart';

class EventPopupMembers extends StatelessWidget {
  const EventPopupMembers({
    super.key,
    required this.members,
  });

  final List<User> members;

  final radius = 20.0;
  final overlap = 0.25;
  final maxVisibleMembers = 2;

  @override
  Widget build(BuildContext context) {
    final limitExceeded = members.length > maxVisibleMembers;
    return Transform.translate(
      offset: const Offset(12, -24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: PopupMenuButton<User>(
          color: Theme.of(context).colorScheme.primaryContainer,
          tooltip: 'Alle Mitglieder anzeigen',
          itemBuilder: (context) => [
            ...members.map((user) => PopupMenuItem(
              value: user,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayname),
                  Text(user.username, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            )),
          ],
          child: SizedBox(
            width: radius * 2 * (limitExceeded ? maxVisibleMembers + 1 : members.length) 
            - (limitExceeded ? maxVisibleMembers * overlap * radius * 2 : (members.length - 1) * overlap * radius * 2) 
            + 3,
            height: radius * 2 + 3,
            child: Stack(
              children: List.generate(
                limitExceeded ? maxVisibleMembers + 1: members.length,
                (index) => Positioned(
                  left: index * radius * 2 - (index * overlap * radius * 2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
                      radius: radius,
                      child: Text(
                        index >= maxVisibleMembers
                            ? "+${members.length - maxVisibleMembers}"
                            : members[index].displayname.substring(0, 2).toUpperCase(),
                        style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        )
      ),
    );
  }
}