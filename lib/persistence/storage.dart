import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/download_item.dart';

const String _keyThemeMode = 'theme_mode';
const String _keyLocale = 'locale';
const String _keyMaxConnections = 'max_connections';
const String _downloadsFileName = 'downloads.json';

class Storage extends ChangeNotifier {
  Storage();

  Future<void> ensureLoaded() async {
    if (_prefs != null) return;
    await _loadPrefs();
  }

  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  String? _localeTag;
  int _maxConnections = 8;

  ThemeMode get themeMode => _themeMode;
  String? get localeTag => _localeTag;
  int get maxConnections => _maxConnections;

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode
        .values[_prefs!.getInt(_keyThemeMode) ?? ThemeMode.system.index];
    _localeTag = _prefs!.getString(_keyLocale);
    _maxConnections = _prefs!.getInt(_keyMaxConnections) ?? 8;
    _maxConnections = _maxConnections.clamp(1, 32);
  }

  Future<ThemeMode> getThemeMode() async {
    _prefs ??= await SharedPreferences.getInstance();
    return ThemeMode.values[_prefs!.getInt(_keyThemeMode) ??
        ThemeMode.system.index];
  }

  Future<Locale?> getLocale() async {
    _prefs ??= await SharedPreferences.getInstance();
    final tag = _prefs!.getString(_keyLocale);
    if (tag == null || tag.isEmpty) return null;
    return Locale(tag);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_keyThemeMode, value.index);
    _themeMode = value;
    notifyListeners();
  }

  Future<void> setLocale(String? localeTag) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (localeTag == null || localeTag.isEmpty) {
      await _prefs!.remove(_keyLocale);
    } else {
      await _prefs!.setString(_keyLocale, localeTag);
    }
    _localeTag = localeTag;
    notifyListeners();
  }

  Future<int> getMaxConnections() async {
    _prefs ??= await SharedPreferences.getInstance();
    final n = _prefs!.getInt(_keyMaxConnections) ?? 8;
    return n.clamp(1, 32);
  }

  Future<void> setMaxConnections(int value) async {
    final n = value.clamp(1, 32);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_keyMaxConnections, n);
    _maxConnections = n;
    notifyListeners();
  }

  static Future<File> _downloadsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_downloadsFileName');
  }

  Future<List<DownloadItem>> loadDownloadList() async {
    try {
      final file = await _downloadsFile();
      if (!await file.exists()) return [];
      final jsonString = await file.readAsString();
      return DownloadItem.listFromJson(jsonString);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDownloadList(List<DownloadItem> items) async {
    try {
      final file = await _downloadsFile();
      await file.writeAsString(DownloadItem.listToJson(items));
    } catch (_) {}
  }

  static Future<String> getDownloadsDirectoryPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloads = Directory('${dir.path}/downloads');
    if (!await downloads.exists()) await downloads.create(recursive: true);
    return downloads.path;
  }
}
