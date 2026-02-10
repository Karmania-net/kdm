import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kdm/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/download_item.dart';
import '../services/download_service.dart';
import '../utils/format_utils.dart';
import '../widgets/add_url_dialog.dart';
import '../widgets/download_list_item.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadService>().ensureLoaded();
    });
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildTopBar(context, l10n),
          Expanded(
            child: Consumer<DownloadService>(
              builder: (context, service, _) {
                var items = service.items;
                if (_searchQuery.isNotEmpty) {
                  items = items
                      .where(
                        (e) =>
                            e.displayName.toLowerCase().contains(_searchQuery),
                      )
                      .toList();
                }
                if (items.isEmpty) {
                  return _buildEmptyState(context, l10n, service.items.isEmpty);
                }
                return _buildDownloadList(context, l10n, items, service);
              },
            ),
          ),
          _buildStatusBar(context, l10n),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Material(
      color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              DropdownButton<String>(
                value: 'newest',
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: 'newest', child: Text(l10n.newest)),
                ],
                onChanged: (_) {},
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: 'all',
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: 'all', child: Text(l10n.allFiles)),
                ],
                onChanged: (_) {},
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () async {
                  final url = await showDialog<String>(
                    context: context,
                    builder: (context) => const AddUrlDialog(),
                  );
                  if (!context.mounted) return;
                  if (url != null && url.isNotEmpty) {
                    await context.read<DownloadService>().addDownload(url);
                  }
                },
                icon: const Icon(Icons.add, size: 20),
                label: Text(l10n.addDownload),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchInDownloads,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    Navigator.pushNamed(context, SettingsScreen.routeName),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    bool noItemsAtAll,
  ) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.back_hand,
                size: 48,
                color: Theme.of(context).hintColor,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.dragDropUrl,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadList(
    BuildContext context,
    AppLocalizations l10n,
    List<DownloadItem> items,
    DownloadService service,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          child: _tableRow(
            context,
            l10n,
            isHeader: true,
            name: l10n.name,
            size: l10n.size,
            status: l10n.status,
            download: l10n.downloadSpeed,
            upload: l10n.uploadSpeed,
            added: l10n.added,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final sizeStr = item.bytesTotal > 0
                  ? formatBytes(item.bytesTotal)
                  : '—';
              final downloadStr =
                  (item.status == DownloadStatus.downloading &&
                      item.speedBytesPerSecond != null &&
                      item.speedBytesPerSecond! > 0)
                  ? formatSpeed(item.speedBytesPerSecond!)
                  : '0 B/s';
              final addedStr = _formatAdded(item.createdAt, l10n);
              return _tableRow(
                context,
                l10n,
                isHeader: false,
                name: item.displayName,
                size: sizeStr,
                status: item,
                download: downloadStr,
                upload: '0 B/s',
                added: addedStr,
                item: item,
                downloadService: service,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tableRow(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isHeader,
    required String name,
    required String size,
    required dynamic status,
    required String download,
    required String upload,
    required String added,
    DownloadItem? item,
    DownloadService? downloadService,
  }) {
    const colName = 2.5;
    const colSize = 0.8;
    const colStatus = 1.8;
    const colSpeed = 0.9;
    const colAdded = 1.2;
    const colActions = 0.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 24.0; // Padding symmetric horizontal 12
        final w = (constraints.maxWidth - horizontalPadding).clamp(
          0.0,
          double.infinity,
        );
        final nameW =
            w *
            colName /
            (colName +
                colSize +
                colStatus +
                colSpeed * 2 +
                colAdded +
                colActions);
        final sizeW =
            w *
            colSize /
            (colName +
                colSize +
                colStatus +
                colSpeed * 2 +
                colAdded +
                colActions);
        final statusW =
            w *
            colStatus /
            (colName +
                colSize +
                colStatus +
                colSpeed * 2 +
                colAdded +
                colActions);
        final speedW =
            w *
            colSpeed /
            (colName +
                colSize +
                colStatus +
                colSpeed * 2 +
                colAdded +
                colActions);
        final addedW =
            w *
            colAdded /
            (colName +
                colSize +
                colStatus +
                colSpeed * 2 +
                colAdded +
                colActions);
        final actionsW =
            w *
            colActions /
            (colName +
                colSize +
                colStatus +
                colSpeed * 2 +
                colAdded +
                colActions);

        Widget statusWidget;
        if (isHeader) {
          statusWidget = Text(
            status as String,
            overflow: TextOverflow.ellipsis,
          );
        } else {
          final i = item as DownloadItem;
          if (i.status == DownloadStatus.completed) {
            statusWidget = Text(
              l10n.completed,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            );
          } else if (i.status == DownloadStatus.downloading) {
            statusWidget = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(i.progress * 100).round()}%',
                  overflow: TextOverflow.ellipsis,
                ),
                LinearProgressIndicator(
                  value: i.progress.clamp(0.0, 1.0),
                  minHeight: 4,
                ),
              ],
            );
          } else {
            String st;
            switch (i.status) {
              case DownloadStatus.pending:
                st = l10n.pending;
                break;
              case DownloadStatus.paused:
                st = l10n.paused;
                break;
              case DownloadStatus.error:
                st = l10n.error;
                break;
              default:
                st = '';
            }
            statusWidget = Text(st, overflow: TextOverflow.ellipsis);
          }
        }

        return InkWell(
          onTap: isHeader ? null : () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: nameW,
                  child: isHeader
                      ? Text(name, overflow: TextOverflow.ellipsis)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (downloadService != null && item != null) ...[
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon:
                                    (item.status == DownloadStatus.downloading)
                                    ? const Icon(Icons.pause, size: 20)
                                    : const Icon(Icons.play_arrow, size: 20),
                                onPressed: () {
                                  if (item.status ==
                                      DownloadStatus.downloading) {
                                    downloadService.pause(item.id);
                                  } else {
                                    downloadService.resume(item.id);
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
                SizedBox(
                  width: sizeW,
                  child: Text(size, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(width: statusW, child: statusWidget),
                SizedBox(
                  width: speedW,
                  child: Text(download, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(
                  width: speedW,
                  child: Text(upload, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(
                  width: addedW,
                  child: Text(added, overflow: TextOverflow.ellipsis),
                ),
                if (!isHeader && downloadService != null && item != null)
                  SizedBox(
                    width: actionsW,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (item.status == DownloadStatus.completed)
                          IconButton(
                            icon: const Icon(Icons.folder_open, size: 20),
                            onPressed: () => DownloadListItem.openFile(item),
                            tooltip: l10n.openFile,
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => downloadService.remove(item.id),
                          tooltip: l10n.remove,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatAdded(DateTime d, AppLocalizations l10n) {
    final now = DateTime.now();
    final today =
        d.year == now.year && d.month == now.month && d.day == now.day;
    if (today) {
      return l10n.todayAt(DateFormat.jm().format(d));
    }
    return DateFormat.yMMMEd().add_jm().format(d);
  }

  Widget _buildStatusBar(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Consumer<DownloadService>(
      builder: (context, service, _) {
        final totalSpeed = service.totalDownloadSpeed;
        return Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.arrow_downward, size: 16, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(
                    totalSpeed > 0 ? formatSpeed(totalSpeed) : '0 B/s',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.arrow_upward, size: 16, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text('0 B/s', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
