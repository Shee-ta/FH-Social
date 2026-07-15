
import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment_input.dart';
import 'package:latlong2/latlong.dart';

class EventPanelList extends StatelessWidget {
  EventPanelList({
    super.key,
    required this.isShowingEventList,
    required this.onEventListHoverChanged,
    required this.setFocus,
    required this.eventPanelList,
    required this.commentDrafts,
    required this.createEvent,
  }) : eventController = AppDI.instance.eventController;

  final bool isShowingEventList;
  final ValueChanged<bool> onEventListHoverChanged;
  final ValueChanged<LatLng> setFocus;
  final List<Event> eventPanelList;
  final EventController eventController;
  final List<CommentDraft> commentDrafts;
  final void Function() createEvent;

  @override
  Widget build(BuildContext context) {
    eventPanelList.sort((b, a) => Formatter.iso8601StringToDateTime(Formatter.calculateNextIso8601(a.iso8601startDateTime, a.days)).compareTo(
      Formatter.iso8601StringToDateTime(Formatter.calculateNextIso8601(b.iso8601startDateTime, b.days)),
    ));
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
                    itemCount: eventPanelList.length,
                    itemBuilder: (context, index) {
                      final event = eventPanelList[index];
                      final isBeforeToday = Formatter.iso8601StringToDateTime(Formatter.calculateNextIso8601(event.iso8601startDateTime, event.days)).isBefore(DateTime.now());
                      return ListenableBuilder(
                        listenable: event.controller,
                        builder: (context, _) {
                          final scheme = Theme.of(context).colorScheme;
                          return ListTile(
                            tileColor: 
                            isBeforeToday 
                            ? Colors.grey.shade900 
                            : Color.alphaBlend(scheme.primary.withValues(alpha: 0.9), Colors.grey.shade900),
                            leading: isBeforeToday ? Icon(Icons.timer_off_outlined) : Icon(Icons.calendar_month),
                            iconColor: isBeforeToday 
                            ? Colors.white70 
                            : scheme.onPrimary,
                            title: Text(
                              event.title, 
                              style: TextStyle(
                                color: isBeforeToday 
                                ? Colors.white70 
                                : scheme.onPrimary
                              )
                            ),
                            subtitle: Text('Location: ${event.location}', 
                            style: TextStyle(color: isBeforeToday 
                            ? Colors.white70 
                            : scheme.onPrimary)),
                            trailing: isBeforeToday ?
                             const Text('Past', style: TextStyle(color: Colors.white70)) : null,
                            onTap: () {
                              setFocus(LatLng(event.latitude, event.longitude));
                              eventPopup(
                                context, 
                                event, 
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