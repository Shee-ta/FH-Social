import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/entity/event.dart';

class DateTimePickerRow extends StatelessWidget {
  const DateTimePickerRow({
    super.key,
    required this.colorScheme,
    required this.hasDateTimeError,
    required this.hasStartEndTimeMismatchError,
    required this.draft,
    required this.setTimeAndDate,
  });

  final ColorScheme colorScheme;
  final bool hasDateTimeError;
  final bool hasStartEndTimeMismatchError;
  final EventDraft draft;
  final void Function(TimeOfDay, TimeOfDay?, DateTime?) setTimeAndDate;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: screenWidth > 400 ? Icon(
              Icons.calendar_today,
              size: 18,
              color: hasDateTimeError ? colorScheme.error : null,
            ) : null,
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                draft.date == null ? 'Datum wählen *' : '${draft.date!.day.toString().padLeft(2, '0')}.${draft.date!.month.toString().padLeft(2, '0')}.${draft.date!.year}',
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: hasDateTimeError ? colorScheme.error : null,
              side: BorderSide(
                color: hasDateTimeError ? colorScheme.error : colorScheme.outline,
              ),
              padding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Const.textFieldRadius),
              ),
            ),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: draft.date ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setTimeAndDate(draft.startTime ?? TimeOfDay.now(), draft.endTime, date);
              }
            },
          ),
        ),
        Const.spacing,
        Expanded(
          child: OutlinedButton.icon(
            icon: screenWidth > 400 ? Icon(
              Icons.access_time,
              size: 18,
              color: hasDateTimeError || hasStartEndTimeMismatchError ? colorScheme.error : null,
            ) : null,
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                draft.startTime == null ? 'Startzeit *' : draft.startTime!.format(context),
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: hasDateTimeError || hasStartEndTimeMismatchError ? colorScheme.error : null,
              side: BorderSide(
                color: hasDateTimeError || hasStartEndTimeMismatchError
                    ? colorScheme.error
                    : colorScheme.outline,
              ),
              padding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Const.textFieldRadius),
              ),
            ),
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: draft.startTime ?? TimeOfDay.now(),
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                setTimeAndDate(time, draft.endTime, draft.date);
              }
            },
          ),
        ),
        Const.spacing,
        Expanded(
          child: OutlinedButton.icon(
            icon: screenWidth > 400 ? Icon(
              Icons.timer_off_outlined,
              size: 18,
              color: hasStartEndTimeMismatchError ? colorScheme.error : null,
            ) : null,
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                draft.endTime == null ? 'Endzeit' : draft.endTime!.format(context),
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: hasStartEndTimeMismatchError ? colorScheme.error : null,
              side: BorderSide(
                color: hasStartEndTimeMismatchError ? colorScheme.error : colorScheme.outline,
              ),
              padding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Const.textFieldRadius),
              ),
            ),
            onLongPress: draft.endTime == null
            ? null
            : () => setTimeAndDate(
                  draft.startTime ?? TimeOfDay.now(),
                  null,
                  draft.date,
                ),
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: draft.endTime ?? TimeOfDay.now(),
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                setTimeAndDate(draft.startTime ?? TimeOfDay.now(), time, draft.date);
              }
            },
          ),
        ),
      ],
    );
  }
}