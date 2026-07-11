import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment_input.dart';
import 'package:latlong2/latlong.dart';

class EventMarkerLayer extends StatelessWidget {
  const EventMarkerLayer({
    super.key,
    required this.events,
    required this.toggleEventList,
    required this.commentDrafts,
    required this.setEventDraft,
    required this.createEvent,
  });

  final List<List<Event>> events;
  final ValueChanged<List<Event>> toggleEventList;
  final List<CommentDraft> commentDrafts;
  final void Function(EventDraft) setEventDraft;
  final void Function() createEvent;

  Icon _buildMarker(List<Event> events) {
    bool isInFuture = _hasOneEventInFuture(events);
    bool isSingleEvent = _isSingleEvent(events);
    bool isOnline = _isOnline(events);

    if (isOnline) {
      return isSingleEvent ? _singleOnlineEventIcon(!isInFuture) : _multipleOnlineEventIcon(!isInFuture);
    } else {
      return isSingleEvent ? _singleEventIcon(!isInFuture) : _multipleEventsIcon(!isInFuture);
    }
  }

  bool _hasOneEventInFuture(List<Event> events) {
    bool isInFuture = true;
    for(final event in events) {
      if(Formatter.isIso8601InPast(Formatter.calculateNextIso8601(event.iso8601startDateTime, event.days))) {
        isInFuture = false;
        break;
      }
    }
    return isInFuture;
  }

  bool _isSingleEvent(List<Event> events) {
    return events.length == 1;
  }

  bool _isOnline(List<Event> events) {
    bool isOnline = true;
    for(final event in events) {
      if(event.location.compareTo('Online') != 0) {
        isOnline = false;
        break;
      }
    }
    return isOnline;
  } 

  Icon _singleEventIcon(bool isPastEvent) {
    return Icon(
      isPastEvent ? Icons.location_on_outlined : Icons.location_on, 
      color: isPastEvent ? Colors.grey : Colors.red, 
      size: 40,
    );
  }
  Icon _multipleEventsIcon(bool isPastEvent) {
    return Icon(
      isPastEvent ? Icons.add_location_alt_outlined : Icons.add_location_alt_sharp, 
      color: isPastEvent ? Colors.grey : Colors.red, 
      size: 40,
    );
  }
  Icon _singleOnlineEventIcon(bool isPastEvent) {
    return Icon(
      isPastEvent ? Icons.wifi_tethering_error : Icons.network_wifi_1_bar, 
      color: isPastEvent ? Colors.grey : Colors.blue, 
      size: 40,
    );
  }
  Icon _multipleOnlineEventIcon(bool isPastEvent) {
    return Icon(
      isPastEvent ? Icons.wifi_tethering_error : Icons.network_wifi, 
      color: isPastEvent ? Colors.grey : Colors.blue, 
      size: 40,
    );
  }

  @override
  Widget build(BuildContext context) {

    return MarkerLayer(
      markers: events.map(
        (events) => Marker(
          point: LatLng(events[0].latitude, events[0].longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _isSingleEvent(events) 
            ? eventPopup(
                context, 
                events[0], 
                commentDrafts,
                setEventDraft,
                createEvent,
              )
            : toggleEventList(events),
            child: _buildMarker(events),
          ),
        ),
      ).toList(),
    );
  }
}
