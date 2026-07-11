
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/recommendation.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/appComponents/locations.dart';
import 'package:frontend/dto/event_dto.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/action_buttons.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/coordinates_label.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/date_time_error.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/date_time_picker_row.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/day_selection_buttons.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/description.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/dropdown_rooms.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/location_name.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/location_picker.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/location_selection_mode.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/repeat_for_days_switch.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/title.dart';
import 'package:latlong2/latlong.dart';

List<String> daysOfWeek() => ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

void createEventForm(
  BuildContext context,
  EventDraft draft,
  Future<LatLng?> Function() useLocationForEvent,
  List<Event> events,
  bool draftReset,
  {
    required bool hasPickedLocation,
    required ValueChanged<bool> setHasPickedLocation,
    required ValueChanged<bool> setUsingCustomLocation,
    required ValueChanged<bool> setPickingLocation,
  }
) {
  final mediaQuery = MediaQuery.of(context);
  final appBarHeight = Scaffold.maybeOf(context)?.appBarMaxHeight ?? (kToolbarHeight + kTextTabBarHeight);
  final maxSheetHeight = mediaQuery.size.height - mediaQuery.padding.top - appBarHeight;

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: maxSheetHeight - 10,
      maxWidth: Const.modalWidth,
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: CreateEventForm(
        draft: draft,
        useLocationForEvent: useLocationForEvent,
        events: events,
        draftReset: draftReset,
        hasPickedLocation: hasPickedLocation,
        setHasPickedLocation: setHasPickedLocation,
        setUsingCustomLocation: setUsingCustomLocation,
        setPickingLocation: setPickingLocation,
      )
    ),
  );
}

class CreateEventForm extends StatefulWidget {
  final EventController eventController;
  final EventDraft draft;
  final Future<LatLng?> Function() useLocationForEvent;
  final List<Event> events;
  final bool draftReset;
  final bool hasPickedLocation;
  final ValueChanged<bool> setHasPickedLocation;
  final ValueChanged<bool> setUsingCustomLocation;
  final ValueChanged<bool> setPickingLocation;

  CreateEventForm({
    super.key,
    required this.draft,
    required this.useLocationForEvent,
    required this.events,
    required this.draftReset,
    required this.hasPickedLocation,
    required this.setHasPickedLocation,
    required this.setUsingCustomLocation,
    required this.setPickingLocation,
  }) : eventController = AppDI.instance.eventController;

  @override
  State<CreateEventForm> createState() => _CreateEventFormState();
}

class _CreateEventFormState extends State<CreateEventForm> {

  @override
  void initState() {
    super.initState();
    titelController = TextEditingController(text: widget.draft.title ?? '');
    locationController = TextEditingController(text: widget.draft.location ?? '');
    descriptionController = TextEditingController(text: widget.draft.description ?? '');
    recommendationController = TextEditingController(text: widget.draft.recommendation ?? '');

    widget.draft.room ??= Locations.rooms.keys.first;
    repeatedForDays = widget.draft.days.isNotEmpty;
    daysSelected = daysOfWeek().map(
      (day) => widget.draft.days.contains(day))
      .toList();

    showDateTimeError = false;
    showStartEndTimeMismatchError = false;

    formKey = GlobalKey<FormState>();

    if (widget.draftReset) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          resetDraft();
        }
      });
    }
  }

  @override
  void dispose() {
    titelController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    recommendationController.dispose();
    super.dispose();
  }

  late final GlobalKey<FormState> formKey;
  late final TextEditingController titelController;
  late final TextEditingController locationController;
  late final TextEditingController descriptionController;
  late final TextEditingController recommendationController;

  late List<bool> locationSelectMode = 
    widget.hasPickedLocation 
    ? [false, true] 
    : [true, false];

  late bool repeatedForDays;
  late bool showDateTimeError;
  late bool showStartEndTimeMismatchError;
  late List<bool> daysSelected;

  void setLocationSelectionMode(int index) {
    if(locationSelectMode[index]) {
      return;
    } 
    setState(() {
        if(index == 0) {
          locationSelectMode = [true, false];
          widget.setHasPickedLocation(false);
          widget.setUsingCustomLocation(false);
        } else if (index == 1) {
          locationSelectMode = [false, true];
          widget.setHasPickedLocation(widget.draft.coordinates != null);
          widget.setUsingCustomLocation(true);
        }
      });
  }

  void setRoom(String room) {
    if(room == widget.draft.room) {
      return;
    }
    setState(() { 
      widget.draft.room = room; 
    });
  }

  void setCoordinates(LatLng? coordinates) {
    if(coordinates == widget.draft.coordinates) {
      return;
    }
    setState(() { 
      widget.draft.coordinates = coordinates; 
    });
  }

  void setTimeAndDate(
    TimeOfDay startTime,
    TimeOfDay? endTime,
    DateTime? date,
  ) {
    if(startTime == widget.draft.startTime && endTime == widget.draft.endTime && date == widget.draft.date) {
      return;
    }
    setState(() { 
      widget.draft.startTime = startTime; 
      widget.draft.endTime = endTime;
      widget.draft.date = date;
      if (widget.draft.startTime != null && widget.draft.date != null) {
        showDateTimeError = false;
      }
      if (widget.draft.endTime != null && widget.draft.startTime != null && widget.draft.endTime!.isBefore(widget.draft.startTime!)) {
        showStartEndTimeMismatchError = true;
      } else {
        showStartEndTimeMismatchError = false;
      }
    });
  }
  
  bool checkTimeAndDate() {
    if (widget.draft.startTime == null || widget.draft.date == null) {
      setState(() {
        showDateTimeError = true;
      });
      return false;
    }
    if (widget.draft.endTime != null && widget.draft.startTime != null && widget.draft.endTime!.isBefore(widget.draft.startTime!)) {
      setState(() {
        showStartEndTimeMismatchError = true;
      });
      return false;
    }
    return true;
  }

  void setSwitchToggle(bool value) {
    setState(() {
      repeatedForDays = value;
      if (value && widget.draft.days.isEmpty) {
        widget.draft.days = ['Mo'];
        daysSelected = [true, false, false, false, false, false, false];
      }
    });
  }

  void setSelectedDays(int index) {
    setState(() {
      daysSelected[index] = !daysSelected[index];
      final day = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'][index];
      if (daysSelected[index]) {
        widget.draft.days.add(day);
      } else {
        widget.draft.days.remove(day);
      }
    });
  }

  EventDTO finishDraft({required EventDraft draft}) {
    return EventDTO(
      id: draft.id ?? '',
      title: draft.title!,
      location: locationSelectMode[0] ? draft.room! : draft.location!,
      description: draft.description ?? '',
      recommendation: draft.recommendation ?? '',
      iso8601startDateTime: Formatter.serialiseDateTime(draft.date!, draft.startTime!),
      iso8601endDateTime: draft.endTime != null ? Formatter.serialiseDateTime(draft.date!, draft.endTime!) : '',
      latitude: locationSelectMode[0] ? Locations.rooms[draft.room!]!.latitude : draft.coordinates?.latitude ?? 0,
      longitude: locationSelectMode[0] ? Locations.rooms[draft.room!]!.longitude : draft.coordinates?.longitude ?? 0,
      days: repeatedForDays ? draft.days : [],
    );
  }

  void resetDraft() {
    setState(() {
      widget.draft.id = null;
      titelController.text = widget.draft.title = '';
      locationController.text = widget.draft.location = '';
      descriptionController.text = widget.draft.description = '';
      recommendationController.text = widget.draft.recommendation = '';
      widget.draft.room = Locations.rooms.keys.first;
      widget.draft.coordinates = null;
      widget.draft.date = null;
      widget.draft.startTime = null;
      widget.draft.endTime = null;
      widget.draft.days = [];
      locationSelectMode = [true, false];
      daysSelected = [false, false, false, false, false, false, false];
      repeatedForDays = false;
      showDateTimeError = false;
      widget.setHasPickedLocation(false);
      widget.setUsingCustomLocation(false);
    });
  }

  void sendEvent() async {
    if (formKey.currentState!.validate() & checkTimeAndDate()) {

      final eventDTO = finishDraft(draft: widget.draft);

      await widget.eventController.uploadEvent(eventDTO).then((success) {
        if (success) {
          resetDraft();
          if(mounted) {
            Navigator.of(context).pop();
          }
        }
      });
    }  
  }

  @override
  Widget build(BuildContext context) {
    return  StatefulBuilder(
      builder: (context, setState) {
        final colorScheme = Theme.of(context).colorScheme;
        final hasDateTimeError = showDateTimeError 
          && (widget.draft.date == null || widget.draft.startTime == null);

        final isEditingExistingEvent = widget.events.any((event) => event.id == widget.draft.id);

        return SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  if (isEditingExistingEvent) ...[
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Editing Existing Event',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Const.spacing,  
                  ],

                  TitleField(
                    titleController: titelController,
                    draft: widget.draft,
                  ),

                  Const.spacing,

                  LocationSelectionMode(
                    locationSelectMode: locationSelectMode,
                    setLocationSelectionMode: (index) => setLocationSelectionMode(index),
                  ),

                  Const.spacing,

                  if (locationSelectMode[0]) ...[
                    DropdownRooms(
                      draft: widget.draft,
                      setRoom: (room) => setRoom(room!),
                    ),
                  ],

                  if (locationSelectMode[1]) ...[
                    Row(
                      children: [
                        Expanded(
                          child: LocationNameField(
                            locationController: locationController,
                            draft: widget.draft,
                          ),
                        ),
                        Const.spacing,
                        LocationPicker(
                          setCoordinates: (coordinates) => setCoordinates(coordinates),
                          useLocationForEvent: widget.useLocationForEvent,
                          setHasPickedLocation: widget.setHasPickedLocation,
                          setPickingLocation: widget.setPickingLocation,
                        ),
                      ],
                    ),
                  ],

                  if (locationSelectMode[1] && widget.draft.coordinates != null) ...[
                    CoordinatesLabel(draft: widget.draft),
                  ],

                  Const.spacing,

                  DateTimePickerRow(
                    colorScheme: colorScheme,
                    hasDateTimeError: hasDateTimeError,
                    hasStartEndTimeMismatchError: showStartEndTimeMismatchError,
                    draft: widget.draft,
                    setTimeAndDate: (startTime, endTime, date) =>
                        setTimeAndDate(startTime, endTime, date),
                  ),
              
                  if (hasDateTimeError) ...[
                    DateTimeError(
                      colorScheme: colorScheme,
                      message: 'Please pick both date and start time.',
                    ),
                  ]
                  else if (showStartEndTimeMismatchError) ...[
                    DateTimeError(
                      colorScheme: colorScheme,
                      message: 'End time cannot be before start time.',
                    ),
                  ],
                  
                  Const.spacing,

                  RepeatForDaysSwitch(
                    repeatedForDays: repeatedForDays,
                    setSwitchToggle: (value) => setSwitchToggle(value),
                  ),

                  if (repeatedForDays) ...[
                    Const.spacing,
                    DaySelectionButtons(
                      daysSelected: daysSelected,
                      onPressed: (index) => setSelectedDays(index),
                    ),
                  ],
                  Const.spacing,

                  DescriptionField(
                    descriptionController: descriptionController,
                    draft: widget.draft,
                  ),

                  Const.spacing,

                  RecommendationField(
                    recommendationController: recommendationController,
                    draft: widget.draft,
                  ),

                  Const.spacing,
                  Divider(color: colorScheme.onSurface.withValues(alpha: 0.2)),
                  Const.spacing,

                  ActionButtons(
                    colorScheme: colorScheme,
                    checkTimeAndDate: () => checkTimeAndDate(),
                    finishDraft: () => finishDraft(draft: widget.draft),
                    resetDraft: () => resetDraft(),
                    formKey: formKey,
                    isEditingExistingEvent: isEditingExistingEvent,
                    sendEvent: () => sendEvent(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}