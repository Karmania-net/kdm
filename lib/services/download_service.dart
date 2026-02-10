import 'package:flutter/foundation.dart';

import '../models/download_item.dart';
import '../persistence/storage.dart';
import 'download_engine.dart';

class DownloadService extends ChangeNotifier {
  DownloadService(this._storage);

  final Storage _storage;
  final List<DownloadItem> _items = [];
  final Map<String, DownloadEngine> _activeEngines = {};
  bool _loaded = false;

  List<DownloadItem> get items => List.unmodifiable(_items);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final list = await _storage.loadDownloadList();
    _items.clear();
    _items.addAll(list);
    _loaded = true;
    notifyListeners();
  }

  Future<void> addDownload(String url) async {
    await ensureLoaded();
    final id = '${DateTime.now().millisecondsSinceEpoch}_${url.hashCode}';
    final dir = await Storage.getDownloadsDirectoryPath();
    final baseName = _filenameFromUrl(url);
    final savePath = _uniqueSavePath(dir, baseName);
    final filename = savePath.split('/').last;

    final item = DownloadItem(
      id: id,
      url: url,
      savePath: savePath,
      filename: filename,
      status: DownloadStatus.pending,
    );
    _items.insert(0, item);
    await _storage.saveDownloadList(_items);
    notifyListeners();

    await _startEngine(item);
  }

  String _filenameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'download_${DateTime.now().millisecondsSinceEpoch}';
    final path = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    if (path.isNotEmpty && path.contains('.')) return path;
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _uniqueSavePath(String dir, String baseName) {
    var path = '$dir/$baseName';
    var suffix = 0;
    while (_items.any((e) => e.savePath == path)) {
      suffix++;
      final ext = baseName.contains('.') ? '.${baseName.split('.').last}' : '';
      final withoutExt = ext.isEmpty
          ? baseName
          : baseName.substring(0, baseName.length - ext.length);
      path = '$dir/${withoutExt}_$suffix$ext';
    }
    return path;
  }

  Future<void> _startEngine(DownloadItem item) async {
    if (_activeEngines.containsKey(item.id)) return;
    final maxConn = await _storage.getMaxConnections();
    final engine = DownloadEngine(
      item: item,
      maxConnections: maxConn,
      storage: _storage,
      onProgress: (_) => notifyListeners(),
      onComplete: (completedItem, {Object? error}) {
        _activeEngines.remove(completedItem.id);
        notifyListeners();
      },
    );
    _activeEngines[item.id] = engine;
    notifyListeners();
    await engine.start(_items);
  }

  void pause(String id) {
    final engine = _activeEngines[id];
    if (engine != null) {
      engine.cancel();
      _activeEngines.remove(id);
      final item = _items.firstWhere((e) => e.id == id);
      item.status = DownloadStatus.paused;
      _storage.saveDownloadList(_items);
      notifyListeners();
    }
  }

  Future<void> resume(String id) async {
    await ensureLoaded();
    final item = _items.firstWhere((e) => e.id == id);
    if (item.status != DownloadStatus.paused &&
        item.status != DownloadStatus.pending) {
      return;
    }
    item.status = DownloadStatus.pending;
    item.errorMessage = null;
    notifyListeners();
    await _startEngine(item);
  }

  Future<void> remove(String id) async {
    final engine = _activeEngines[id];
    if (engine != null) {
      engine.cancel();
      _activeEngines.remove(id);
    }
    _items.removeWhere((e) => e.id == id);
    await _storage.saveDownloadList(_items);
    notifyListeners();
  }

  bool isDownloading(String id) => _activeEngines.containsKey(id);
}
