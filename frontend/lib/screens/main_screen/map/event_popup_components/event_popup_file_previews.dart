
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/entity/file_preview.dart';
import 'package:frontend/services/settings_service.dart';

class EventPopupFilePreview extends StatelessWidget {
  final List<FilePreview> files;
  final Event event;
  final bool isOwner;

  EventPopupFilePreview({
    super.key,
    required this.files,
    required this.event,
    required this.isOwner,
  })
  : settingsService = AppDI.instance.settingsService;

  final SettingsService settingsService;

  void _showFilesDialog(BuildContext context) {
    final dialogFiles = List<FilePreview>.from(files);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Dateien'),
              content: SizedBox(
                width: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: dialogFiles.length,
                  itemBuilder: (context, index) {
                    final file = dialogFiles[index];
                    final size = Formatter.formatFileSize(file.size);
                    final dateTime = Formatter.deserialiseDateTime(file.createdAt);
                    return ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(file.fileName),
                      subtitle: Text(
                        "$size, ${dateTime.date} ${dateTime.time}",
                      ),
                      trailing: PopupMenuButton(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        tooltip: 'Optionen',
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'download',
                            child: Row(
                              children: [
                                Icon(Icons.download),
                                Const.spacing,
                                Text('Herunterladen'),
                              ],
                            ),
                          ),
                          if (isOwner)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete),
                                Const.spacing,
                                Text('Löschen'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await event.controller.deleteFile(file.id).then((success) {
                              if (success) {
                                setState(() {
                                  dialogFiles.removeAt(index);
                                });
                              }
                              if (dialogFiles.isEmpty && context.mounted) {
                                Navigator.of(context).pop();
                              }
                            });
                          }
                          if (value == 'download') {
                            await event.controller.downloadFile(file.id, file.fileName);
                          }
                        },
                        child: const Icon(Icons.more_vert, size: 32),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(),
                  child: const Text('Schließen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: ElevatedButton(
        style: settingsService.neutralButtonStyle(context),
        onPressed: files.isEmpty ? null : () => _showFilesDialog(context),
        child: files.isEmpty
        ? const Text('Keine Dateien')
        : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if(screenWidth > 500) ...[
              const Icon(Icons.attach_file),
              Const.spacing,
            ],
            Text(
              files.length > 1
              ? '${files.length} Dateien'
              : '1 Datei',
            ),
          ],
        ),
      ),
    );
  }
}