import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kdm/l10n/app_localizations.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import '../models/download_item.dart';
import '../services/download_service.dart';

class DownloadListItem extends StatelessWidget {
  const DownloadListItem({super.key, required this.item});

  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final downloadService = context.watch<DownloadService>();
    final isActive = downloadService.isDownloading(item.id);

    String statusText;
    switch (item.status) {
      case DownloadStatus.pending:
        statusText = l10n.pending;
        break;
      case DownloadStatus.downloading:
        statusText = l10n.downloading;
        break;
      case DownloadStatus.paused:
        statusText = l10n.paused;
        break;
      case DownloadStatus.completed:
        statusText = l10n.completed;
        break;
      case DownloadStatus.error:
        statusText = l10n.error;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(item.displayName, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(statusText),
            if (item.bytesTotal > 0)
              LinearProgressIndicator(
                value: item.progress.clamp(0.0, 1.0),
                minHeight: 4,
              ),
            if (item.errorMessage != null)
              Text(
                item.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.status == DownloadStatus.completed)
              IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: () => _openFile(context),
                tooltip: l10n.openFile,
              ),
            if (item.status == DownloadStatus.downloading || isActive)
              IconButton(
                icon: const Icon(Icons.pause),
                onPressed: () => downloadService.pause(item.id),
                tooltip: l10n.pause,
              )
            else if (item.status == DownloadStatus.paused ||
                item.status == DownloadStatus.pending ||
                item.status == DownloadStatus.error)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => downloadService.resume(item.id),
                tooltip: l10n.resume,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => downloadService.remove(item.id),
              tooltip: l10n.remove,
            ),
          ],
        ),
      ),
    );
  }

  void _openFile(BuildContext context) {
    openFile(item);
  }

  /// Opens the downloaded file with the system default app.
  static void openFile(DownloadItem downloadItem) {
    final file = File(downloadItem.savePath);
    if (file.existsSync()) {
      OpenFile.open(downloadItem.savePath, type: 'file', linuxByProcess: true);
    }
  }
}
