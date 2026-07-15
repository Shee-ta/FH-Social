
import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment_input.dart';
import 'package:latlong2/latlong.dart';

({List<Event> list, int indexBeforeToday}) orderEvents(List<Event> events) {
  final beforeToday = <Event>[];
  final afterToday = <Event>[];

  for(final event in events) {
    Formatter.isIso8601InPast(Formatter.calculateNextIso8601(event.iso8601startDateTime, event.days))
    ? beforeToday.add(event)
    : afterToday.add(event);
  }
  return (list: [...afterToday, ...beforeToday.reversed], indexBeforeToday: afterToday.length);
}

class EventPanelList extends StatelessWidget {
  EventPanelList({
    super.key,
    required this.isShowingEventList,
    required this.onEventListHoverChanged,
    required this.setFocus,
    required this.eventPanelList,
    required this.commentDrafts,
    required this.setEventDraft,
    required this.createEvent,
  }) : eventController = AppDI.instance.eventController;

  final bool isShowingEventList;
  final ValueChanged<bool> onEventListHoverChanged;
  final ValueChanged<LatLng> setFocus;
  final List<Event> eventPanelList;
  final EventController eventController;
  final List<CommentDraft> commentDrafts;
  final void Function(EventDraft) setEventDraft;
  final void Function() createEvent;
  ({List<Event> list, int indexBeforeToday}) get orderedEvents 
    => orderEvents(eventPanelList);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          constraints: BoxConstraints(maxHeight: isShowingEventList ? 400 : 0),
          curve: Curves.easeInOut,
          child: MouseRegion(
            onEnter: (_) => onEventListHoverChanged(true),
            onExit: (_) => onEventListHoverChanged(false),
            child: Material(
              elevation: 8,
              child: ListenableBuilder(
                listenable: eventController, 
                builder: (context, _) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: orderedEvents.list.length,
                    itemBuilder: (context, index) {
                      final event = orderedEvents.list[index];
                      final isBeforeToday = index >= orderedEvents.indexBeforeToday;
                      return ListenableBuilder(
                        listenable: event.controller,
                        builder: (context, _) {
                          return ListTile(
                            title: Text(event.title),
                            subtitle: Text('Ort: ${event.location}'),
                            trailing: isBeforeToday ? const Text('Vorbei') : null,
                            onTap: () {
                              setFocus(LatLng(event.latitude, event.longitude));
                              eventPopup(
                                context, 
                                event, 
                                commentDrafts,
                                setEventDraft,
                                createEvent,
                              );
                            },
                          );
                        }
                      );
                    },
                  );
                }
              ),
            ),
          ),
        ),
      ),
    );
  }
}