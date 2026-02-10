// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'KDM';

  @override
  String get downloads => 'دانلودها';

  @override
  String get addDownload => 'افزودن دانلود';

  @override
  String get addUrl => 'افزودن آدرس';

  @override
  String get urlHint => 'https://example.com/file.zip';

  @override
  String get cancel => 'انصراف';

  @override
  String get add => 'افزودن';

  @override
  String get settings => 'تنظیمات';

  @override
  String get theme => 'تم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تاریک';

  @override
  String get themeSystem => 'سیستم';

  @override
  String get language => 'زبان';

  @override
  String get maxConnections => 'حداکثر اتصال برای هر دانلود';

  @override
  String get pending => 'در انتظار';

  @override
  String get downloading => 'در حال دانلود';

  @override
  String get paused => 'متوقف شده';

  @override
  String get completed => 'تکمیل شده';

  @override
  String get error => 'خطا';

  @override
  String get pause => 'توقف';

  @override
  String get resume => 'ادامه';

  @override
  String get remove => 'حذف';

  @override
  String get openFile => 'باز کردن فایل';

  @override
  String get invalidUrl => 'لطفاً یک آدرس معتبر وارد کنید';

  @override
  String get downloadsDirectory => 'پوشه دانلودها';

  @override
  String get noDownloads => 'هنوز دانلودی وجود ندارد';

  @override
  String get searchInDownloads => 'جستجو در دانلودها...';

  @override
  String get newest => 'جدیدترین';

  @override
  String get allFiles => 'همه فایل‌ها';

  @override
  String get dragDropUrl => 'آدرس یا فایل تورنت را اینجا بکشید و رها کنید';

  @override
  String get added => 'اضافه شده';

  @override
  String get size => 'حجم';

  @override
  String get name => 'نام';

  @override
  String get status => 'وضعیت';

  @override
  String get downloadSpeed => 'دانلود';

  @override
  String get uploadSpeed => 'آپلود';

  @override
  String get enterUrlOrTorrent =>
      'آدرس را وارد کنید یا فایل تورنت را انتخاب کنید';

  @override
  String todayAt(String time) {
    return 'امروز $time';
  }
}
