// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KDM';

  @override
  String get downloads => 'Downloads';

  @override
  String get addDownload => 'Add Download';

  @override
  String get addUrl => 'Add URL';

  @override
  String get urlHint => 'https://example.com/file.zip';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get language => 'Language';

  @override
  String get maxConnections => 'Max connections per download';

  @override
  String get pending => 'Pending';

  @override
  String get downloading => 'Downloading';

  @override
  String get paused => 'Paused';

  @override
  String get completed => 'Completed';

  @override
  String get error => 'Error';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get remove => 'Remove';

  @override
  String get openFile => 'Open file';

  @override
  String get invalidUrl => 'Please enter a valid URL';

  @override
  String get downloadsDirectory => 'Downloads';

  @override
  String get noDownloads => 'No downloads yet';

  @override
  String get searchInDownloads => 'Search in downloads...';

  @override
  String get newest => 'Newest';

  @override
  String get allFiles => 'All files';

  @override
  String get dragDropUrl => 'Drag-and-drop URL or torrent file';

  @override
  String get added => 'Added';

  @override
  String get size => 'Size';

  @override
  String get name => 'Name';

  @override
  String get status => 'Status';

  @override
  String get downloadSpeed => 'Download';

  @override
  String get uploadSpeed => 'Upload';

  @override
  String get enterUrlOrTorrent => 'Enter URL or choose torrent file';

  @override
  String todayAt(String time) {
    return 'Today $time';
  }
}
