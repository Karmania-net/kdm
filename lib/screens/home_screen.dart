import 'package:flutter/material.dart';
import 'package:kdm/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/download_service.dart';
import '../widgets/add_url_dialog.dart';
import '../widgets/download_list_item.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadService>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.downloads),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                Navigator.pushNamed(context, SettingsScreen.routeName),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Consumer<DownloadService>(
            builder: (context, service, _) {
              final items = service.items;
              if (items.isEmpty) {
                return Center(child: Text(l10n.noDownloads));
              }
              if (isWide) {
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      DownloadListItem(item: items[index]),
                );
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    DownloadListItem(item: items[index]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
        tooltip: l10n.addDownload,
        child: const Icon(Icons.add),
      ),
    );
  }
}
