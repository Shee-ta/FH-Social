import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/controller/create_event_controller.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/create_event_form.dart';
import 'package:frontend/screens/main_screen/map/current_location_marker_layer.dart';
import 'package:frontend/screens/main_screen/map/event_draft_marker.dart';
import 'package:frontend/screens/main_screen/map/event_panel_list.dart';
import 'package:frontend/screens/main_screen/map/event_marker_layer.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment_input.dart';
import 'package:frontend/screens/main_screen/map/map_buttons.dart';
import 'package:frontend/screens/main_screen/map/tile_layer.dart';
import 'package:frontend/services/ui_feedback_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapTab extends StatefulWidget {
  MapTab({
    super.key,
  })  : authController = AppDI.instance.authController,
        eventController = AppDI.instance.eventController;

  final AuthController authController;
  final EventController eventController;

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with AutomaticKeepAliveClientMixin {
  static const LatLng _initialCenter = LatLng(51.4939, 7.42);

  final _mapController = MapController();
  final _createEventController = CreateEventController();

  final _eventDraft = EventDraft();
  final _commentDrafts = <CommentDraft>[];

  StreamSubscription<Position>? _positionSubscription;

  LatLng? _currentLocation;
  bool _isHoveringEventList = false;
  bool _isShowingEventList = false;

  List<Event> _eventPanelList = [];
  final List<String> _disabledTags = [];

  @override
  void initState() {
    super.initState();
    _createEventController.addListener(_onCreateEventControllerChanged);
    widget.eventController.addListener(_onEventControllerChanged);
    _requestLocationTracking();
  }

  @override
  void dispose() {
    _createEventController.removeListener(_onCreateEventControllerChanged);
    widget.eventController.removeListener(_onEventControllerChanged);
    _createEventController.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _setEventDraft(EventDraft draft) {
    setState(() {
      _eventDraft.id = draft.id;
      _eventDraft.title = draft.title;
      _eventDraft.location = draft.location;
      _eventDraft.room = draft.room;
      _eventDraft.description = draft.description;
      _eventDraft.recommendation = draft.recommendation;
      _eventDraft.startTime = draft.startTime;
      _eventDraft.endTime = draft.endTime;
      _eventDraft.date = draft.date;
      _eventDraft.coordinates = draft.coordinates;
      _eventDraft.days = draft.days;
    });
  }

  void _onCreateEventControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _onEventControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      
      if (_eventPanelList.isEmpty) {
        return;
      }

      final currentEventsById = {
        for (final event in widget.eventController.events) event.id: event,
      };

      _eventPanelList = _eventPanelList
          .where((event) => currentEventsById.containsKey(event.id))
          .map((event) => currentEventsById[event.id]!)
          .toList();

      if (_eventPanelList.isEmpty) {
        _isShowingEventList = false;
      }
    });
  }

  LocationSettings _getSettings() {

    if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
          "FH Social empfängt weiterhin deinen Standort, auch wenn du die App nicht nutzt",
          notificationTitle: "Läuft im Hintergrund",
          enableWakeLock: true,
        )
    );
  } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
    return AppleSettings(
      accuracy: LocationAccuracy.high,
      activityType: ActivityType.fitness,
      distanceFilter: 5,
      pauseLocationUpdatesAutomatically: true,
      showBackgroundLocationIndicator: false,
    );
  } else if (kIsWeb) {
    return WebSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
      maximumAge: Duration(minutes: 5),
    );
  } else {
    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
  }
}

  void _createEvent({bool draftReset = false}) {
    createEventForm(
      context,
      _eventDraft,
      _useLocationForEvent,
      widget.eventController.events,
      draftReset,
      hasPickedLocation: _createEventController.hasPickedLocation,
      setHasPickedLocation: _createEventController.setHasPickedLocation,
      setUsingCustomLocation: _createEventController.setUsingCustomLocation,
      setPickingLocation: _createEventController.setPickingLocation,
    );
  }

  void _setTag(bool isSelected, String tag) {
    setState(() {
      if (isSelected) {
        _disabledTags.remove(tag);
      } else {
        _disabledTags.add(tag);
      }
    });
  }

  bool _matchesTagFilter(Event event) {
    if (_disabledTags.isEmpty) {
      return true;
    }
    if (event.creator.id == widget.authController.userId) {
      return true;
    }
    if (event.tags.isEmpty) {
      return true;
    }
    return event.tags.any((tag) => !_disabledTags.contains(tag));
  }

  List<List<Event>> _filterByTags(List<List<Event>> events) {
    List<List<Event>> filteredEvents = [];
    for (final eventGroup in events) {
      List<Event> filteredEventGroup = [];
      for(final event in eventGroup) {
        if (_matchesTagFilter(event)) {
          filteredEventGroup.add(event);
        }
      }
      if(filteredEventGroup.isNotEmpty) {
        filteredEvents.add(filteredEventGroup);
      }
    }
    return filteredEvents;
  }

  List<Event> _filterByTagsFlat(List<Event> events) {
    return events.where(_matchesTagFilter).toList();
  }

  @override
  bool get wantKeepAlive => true;

  void _handleMapTap(TapPosition _, LatLng latLng) {
    
    if (!_createEventController.isPickingLocation) {
      _toggleEventList(const [], forceClose: true);
      return;
    }
    setState(() {
      _eventDraft.coordinates = latLng;
    });
    _createEventController.setHasPickedLocation(true);
    _createEventController.setPickingLocation(false);
    _createEvent();
  }

  Future<bool> _requestLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (_currentLocation != null) {
        setState(() {
          _currentLocation = null;
        });
      }
      await Geolocator.openLocationSettings();
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (_currentLocation != null) {
          setState(() {
            _currentLocation = null;
          });
        }
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      UIfeedbackService.notification(
        message: "Bitte Standortfreigabe aktivieren", 
        type: NotificationType.error);
      if (_currentLocation != null) {
        setState(() {
          _currentLocation = null;
        });
      }
      return false;
    } 

    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
      _registerStream();
      return true;

    } catch (e) {
      UIfeedbackService.notification(
        message: "Standort konnte nicht ermittelt werden",
        type: NotificationType.error
      );
      setState(() {
        _currentLocation = null;
      });
      return false;
    }
  }

  Future<void> _registerStream() async {
    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(locationSettings: _getSettings()).listen(
      (pos) {
        if (!mounted) {
          return;
        }
        final location = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _currentLocation = location;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) {
          return;
        }
        setState(() {
          _currentLocation = null;
        });
      },
      cancelOnError: false,
    );
  }

  Future<LatLng?> _useLocationForEvent() async {
    if (!await _requestLocationTracking()) {
      UIfeedbackService.notification(
        message: "Bitte Standortfreigabe aktivieren", 
        type: NotificationType.error);
      setState(() {
        _eventDraft.coordinates = null;
        _currentLocation = null;
      });
      return null;
    }

    if (mounted) {
      setState(() {
        _moveMapToLocation(_currentLocation!);
      });
    }

    return _currentLocation;
  }

  void _moveMapToLocation(LatLng location) {
    try {
      _mapController.move(location, 18);
    } catch (_) {
      // The map controller may not be ready yet.
    }
  }

  int get _interactionFlags {
    if (_isHoveringEventList) {
      return InteractiveFlag.all & ~InteractiveFlag.scrollWheelZoom;
    }
    return InteractiveFlag.all;
  }

  void _toggleEventList(List<Event> events, {bool forceClose = false}) {
    if (forceClose) {
      setState(() {
        _isShowingEventList = false;
      });
      return;
    }

    events = _filterByTagsFlat(events);

    bool eventsEqual =
        events.length == _eventPanelList.length &&
        events.every((event) => _eventPanelList.contains(event));

    if (eventsEqual && _isShowingEventList) {
      setState(() {
        _isShowingEventList = false;
      });
      return;
    }

    if (!eventsEqual && _isShowingEventList) {
      setState(() {
        _isShowingEventList = false;
      });

      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _eventPanelList = events;
          _isShowingEventList = true;
        });
      });
      return;
    }

    setState(() {
      _isShowingEventList = true;
      _eventPanelList = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: 18,
        minZoom: 3,
        maxZoom: 20,
        interactionOptions: InteractionOptions(flags: _interactionFlags),
        onTap: _handleMapTap,
      ),
      children: [
        const MapTileLayer(),
        if (_currentLocation != null)
          CurrentLocationMarker(currentLocation: _currentLocation!),
        if (widget.eventController.events.isNotEmpty)
          EventMarkerLayer(
            events: _filterByTags(widget.eventController.eventsGroupedByLocation),
            toggleEventList: (events) => _toggleEventList(events),
            commentDrafts: _commentDrafts,
            setEventDraft: _setEventDraft,
            createEvent: _createEvent,
          ),
        if (_eventDraft.coordinates != null &&
            _createEventController.hasPickedLocation)
          EventDraftMarker(
            coordinates: _eventDraft.coordinates!,
            onCreateEvent: _createEvent,
          ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                EventPanelList(
                  isShowingEventList: _isShowingEventList,
                  eventPanelList: _filterByTagsFlat(_eventPanelList),
                  commentDrafts: _commentDrafts,
                  setFocus: (coords) => _mapController.move(coords, 21),
                  onEventListHoverChanged: (isHovering) {
                    if (_isHoveringEventList == isHovering || !mounted) {
                      return;
                    }
                    setState(() {
                      _isHoveringEventList = isHovering;
                    });
                  },
                  setEventDraft: _setEventDraft,
                  createEvent: _createEvent,
                ),
                MapButtons(
                  isShowingEventList: _isShowingEventList,
                  filterByTags: _filterByTagsFlat,
                  events: widget.eventController.events,
                  availableTags: widget.eventController.tags,
                  disabledTags: _disabledTags,
                  addEvent: _createEvent,
                  setTag: _setTag,
                  toggleEventList: (events, {bool forceClose = false}) =>
                      _toggleEventList(events, forceClose: forceClose),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
