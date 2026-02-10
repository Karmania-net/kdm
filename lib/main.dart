import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'persistence/storage.dart';
import 'services/download_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = Storage();
  await storage.ensureLoaded();
  final downloadService = DownloadService(storage);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => storage),
        ChangeNotifierProvider(create: (_) => downloadService),
      ],
      child: const App(),
    ),
  );
}
