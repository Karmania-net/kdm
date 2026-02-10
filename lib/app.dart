import 'package:flutter/material.dart';
import 'package:kdm/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'persistence/storage.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Storage>(
      builder: (context, storage, _) {
        final locale = storage.localeTag != null
            ? Locale(storage.localeTag!)
            : null;
        return MaterialApp(
          title: 'KDM',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: storage.themeMode,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
          routes: {
            SettingsScreen.routeName: (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
