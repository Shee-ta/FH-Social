
import 'package:flutter/material.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/tags_selector.dart';
class MapButtons extends StatelessWidget {
  MapButtons({
    super.key,
    required this.isShowingEventList,
    required this.events,
    required this.filterByTags,
    required this.availableTags,
    required this.disabledTags,
    required this.addEvent,
    required this.setTag,
    required this.toggleEventList,
  }) : authController = AppDI.instance.authController;

  final bool isShowingEventList;
  final List<Event> events;
  final Map<String, int> availableTags;
  final List<String> disabledTags;
  final List<Event> Function(List<Event> events) filterByTags;
  final void Function({bool draftReset}) addEvent;
  final void Function(bool isSelected, String tag) setTag;
  final void Function(List<Event> events, {bool forceClose}) toggleEventList;
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final buttonChildren = <Widget>[
      if (authController.isLoggedIn)
        ElevatedButton(
          onPressed: () => addEvent(draftReset: false),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(24),
          ),
          child: const Icon(Icons.add, size: 40),
        ),
      if (availableTags.isNotEmpty)
        TagsSelector(
          closeEventList: toggleEventList,
          availableTags: availableTags,
          disabledTags: disabledTags,
          setTag: setTag,
        ),
      if ((filterByTags(events)).isNotEmpty)
        ElevatedButton(
          onPressed: () => toggleEventList(events, forceClose: isShowingEventList),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            iconSize: 40,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(24),
          ),
          child: Icon(isShowingEventList ? Icons.expand_more : Icons.expand_less),
        ),
    ];

    return SizedBox(
      width: isMobile ? double.infinity : 300,
      child: Row(
        spacing: isMobile ? 0 : 16,
        mainAxisAlignment:
          isMobile ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.start,
        children: buttonChildren
          .map((button) => isMobile
            ? Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8), 
                  child: button))
            : button)
          .toList(),
      ),
    );
  }
}