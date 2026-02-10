import 'package:flutter/material.dart';
import 'package:kdm/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../persistence/storage.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final storage = context.watch<Storage>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.theme),
            subtitle: Text(_themeModeLabel(l10n, storage.themeMode)),
            trailing: DropdownButton<ThemeMode>(
              value: storage.themeMode,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.themeLight),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.themeDark),
                ),
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.themeSystem),
                ),
              ],
              onChanged: (value) {
                if (value != null) storage.setThemeMode(value);
              },
            ),
          ),
          ListTile(
            title: Text(l10n.language),
            subtitle: Text(storage.localeTag ?? 'System'),
            trailing: DropdownButton<String?>(
              value: storage.localeTag,
              items: [
                const DropdownMenuItem(value: null, child: Text('System')),
                const DropdownMenuItem(value: 'en', child: Text('English')),
                const DropdownMenuItem(value: 'fa', child: Text('فارسی')),
              ],
              onChanged: (value) => storage.setLocale(value),
            ),
          ),
          ListTile(
            title: Text(l10n.maxConnections),
            subtitle: Text('${storage.maxConnections}'),
            trailing: DropdownButton<int>(
              value: _clampToOptions(storage.maxConnections),
              items: const [1, 2, 4, 8, 16, 32]
                  .map((i) => DropdownMenuItem(value: i, child: Text('$i')))
                  .toList(),
              onChanged: (value) {
                if (value != null) storage.setMaxConnections(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }

  int _clampToOptions(int value) {
    const options = [1, 2, 4, 8, 16, 32];
    for (final o in options) {
      if (value <= o) return o;
    }
    return 32;
  }
}
