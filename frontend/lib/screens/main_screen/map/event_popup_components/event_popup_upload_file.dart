
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/entity/file_preview.dart';
import 'package:frontend/services/settings_service.dart';
import 'package:frontend/services/ui_feedback_service.dart';
import 'package:http/http.dart' as http;

class EventPopupUploadFile extends StatelessWidget {
  final List<FilePreview> files;
  final String eventId;
  final Event event;

  EventPopupUploadFile({
    super.key,
    required this.files,
    required this.eventId,
    required this.event,
  })
  : settingsService = AppDI.instance.settingsService;

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: ElevatedButton(
        style: settingsService.negativeButtonStyle(context),
        onPressed: event.controller.isUploadingFile ? null : () async {

          FilePickerResult? result = await FilePicker.pickFiles(
            type: FileType.any,
          );

          if (result == null) {
            return;
          }
          if(result.files.any((file) => files.any((existingFile) => existingFile.fileName == file.name))) {
            UIfeedbackService.notification(
              message: 'Es existiert bereits eine Datei mit diesem Namen.',
              type: NotificationType.error,
            );
            return;
          }

          for (final file in result.files) {
            http.MultipartFile multipart;

            if (kIsWeb) {
              multipart = http.MultipartFile.fromBytes(
                'file',
                await file.readAsBytes(),
                filename: file.name,
              );
            } else {
              multipart = await http.MultipartFile.fromPath(
                'file',
                file.path!,
              );
            }
            await event.controller.uploadFile(multipart, eventId);
          }
        },
        child: event.controller.isUploadingFile 
        ? SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            strokeWidth: 2,
          ),
        )
        : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (screenWidth > 500) ...[
              Icon(Icons.upload_file),
              Const.spacing,
            ],
            Text(screenWidth > 500 ? 'Datei hochladen' : 'Hochladen'),
          ],
        ),
      ),
    );
  }
}