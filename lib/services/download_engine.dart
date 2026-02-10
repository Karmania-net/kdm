import 'dart:io';

import 'package:dio/dio.dart';

import '../models/download_item.dart';
import '../persistence/storage.dart';

typedef ProgressCallback = void Function(DownloadItem item);
typedef CompletionCallback = void Function(DownloadItem item, {Object? error});

class DownloadEngine {
  DownloadEngine({
    required this.item,
    required this.maxConnections,
    required this.storage,
    required this.onProgress,
    required this.onComplete,
  });

  final DownloadItem item;
  final int maxConnections;
  final Storage storage;
  final ProgressCallback onProgress;
  final CompletionCallback onComplete;

  final Dio _dio = Dio();
  bool _cancelled = false;
  final List<CancelToken> _tokens = [];
  int _lastSpeedBytes = 0;
  DateTime? _lastSpeedTime;

  void _updateSpeed() {
    final now = DateTime.now();
    if (_lastSpeedTime != null) {
      final elapsed = now.difference(_lastSpeedTime!).inMilliseconds / 1000.0;
      if (elapsed >= 0.3) {
        item.speedBytesPerSecond =
            ((item.bytesDone - _lastSpeedBytes) / elapsed).round();
        _lastSpeedBytes = item.bytesDone;
        _lastSpeedTime = now;
      }
    } else {
      _lastSpeedTime = now;
      _lastSpeedBytes = item.bytesDone;
    }
  }

  Future<void> start(List<DownloadItem> allItems) async {
    try {
      final response = await _dio.head(item.url);
      final contentLength = response.headers.value(Headers.contentLengthHeader);
      final acceptRanges = response.headers.value('accept-ranges');
      final total = contentLength != null ? int.tryParse(contentLength) : null;

      if (total == null || total <= 0) {
        await _downloadSingleConnection(allItems);
        return;
      }

      final supportsRange = acceptRanges?.toLowerCase() == 'bytes';
      if (!supportsRange || maxConnections <= 1) {
        await _downloadSingleConnection(allItems);
        return;
      }

      await _downloadSegments(total, allItems);
    } catch (e) {
      if (_cancelled) return;
      item.status = DownloadStatus.error;
      item.errorMessage = e.toString();
      onComplete(item, error: e);
    }
  }

  void cancel() {
    _cancelled = true;
    for (final t in _tokens) {
      t.cancel();
    }
  }

  Future<void> _downloadSingleConnection(List<DownloadItem> allItems) async {
    final token = CancelToken();
    _tokens.add(token);
    try {
      await _dio.download(
        item.url,
        item.savePath,
        cancelToken: token,
        onReceiveProgress: (received, total) {
          if (_cancelled) return;
          item.bytesDone = received;
          item.bytesTotal = total;
          item.progress = total > 0 ? received / total : 0.0;
          item.status = DownloadStatus.downloading;
          _updateSpeed();
          onProgress(item);
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );
      if (_cancelled) return;
      item.speedBytesPerSecond = null;
      item.status = DownloadStatus.completed;
      item.progress = 1.0;
      item.bytesDone = item.bytesTotal;
      onProgress(item);
      onComplete(item);
      await storage.saveDownloadList(allItems);
    } catch (e) {
      if (_cancelled) return;
      rethrow;
    }
  }

  String _partPath(int index) => '${item.savePath}.part.$index';

  Future<void> _downloadSegments(int total, List<DownloadItem> allItems) async {
    item.bytesTotal = total;
    final n = maxConnections.clamp(1, 32);
    final segmentSize = total ~/ n;
    final List<SegmentState> segments = [];

    if (item.segments.isNotEmpty) {
      segments.addAll(item.segments);
      for (var i = 0; i < segments.length; i++) {
        final partFile = File(_partPath(i));
        if (await partFile.exists()) {
          final len = await partFile.length();
          final expected = segments[i].end - segments[i].start + 1;
          if (len == expected) {
            segments[i] = SegmentState(
              start: segments[i].start,
              end: segments[i].end,
              done: true,
            );
          }
        }
      }
    } else {
      for (var i = 0; i < n; i++) {
        final start = i * segmentSize;
        final end = i == n - 1 ? total - 1 : (i + 1) * segmentSize - 1;
        segments.add(SegmentState(start: start, end: end, done: false));
      }
      item.segments = segments;
    }

    final pending = <int>[];
    for (var i = 0; i < segments.length; i++) {
      if (!segments[i].done) pending.add(i);
    }

    if (pending.isEmpty) {
      await _mergePartFiles(segments.length);
      item.status = DownloadStatus.completed;
      item.progress = 1.0;
      item.bytesDone = total;
      onProgress(item);
      onComplete(item);
      await storage.saveDownloadList(allItems);
      return;
    }

    item.status = DownloadStatus.downloading;
    onProgress(item);

    await Future.wait(
      pending.map(
        (i) => _downloadSegment(i, segments[i], segments, total, allItems),
      ),
    );

    if (_cancelled) return;

    item.bytesDone = segments.fold<int>(
      0,
      (sum, s) => s.done ? sum + (s.end - s.start + 1) : sum,
    );
    item.progress = total > 0 ? item.bytesDone / total : 1.0;

    final allDone = segments.every((s) => s.done);
    if (allDone) {
      await _mergePartFiles(segments.length);
      item.speedBytesPerSecond = null;
      item.status = DownloadStatus.completed;
      item.progress = 1.0;
      item.bytesDone = total;
      onComplete(item);
    } else {
      item.speedBytesPerSecond = null;
      item.status = DownloadStatus.paused;
      onComplete(item);
    }
    await storage.saveDownloadList(allItems);
  }

  Future<void> _mergePartFiles(int count) async {
    final out = File(item.savePath);
    final sink = out.openWrite();
    for (var i = 0; i < count; i++) {
      final part = File(_partPath(i));
      if (await part.exists()) {
        await sink.addStream(part.openRead());
        await part.delete();
      }
    }
    await sink.close();
  }

  Future<void> _downloadSegment(
    int index,
    SegmentState seg,
    List<SegmentState> segments,
    int total,
    List<DownloadItem> allItems,
  ) async {
    final token = CancelToken();
    _tokens.add(token);
    try {
      final response = await _dio.get<List<int>>(
        item.url,
        cancelToken: token,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          headers: {'Range': 'bytes=${seg.start}-${seg.end}'},
        ),
      );
      if (_cancelled) return;
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return;

      final partFile = File(_partPath(index));
      await partFile.writeAsBytes(bytes);

      final idx = segments.indexWhere(
        (s) => s.start == seg.start && s.end == seg.end,
      );
      if (idx >= 0) {
        segments[idx] = SegmentState(
          start: seg.start,
          end: seg.end,
          done: true,
        );
      }

      item.bytesDone = segments.fold<int>(
        0,
        (sum, s) => s.done ? sum + (s.end - s.start + 1) : sum,
      );
      item.progress = total > 0 ? item.bytesDone / total : 0.0;
      _updateSpeed();
      onProgress(item);
      await storage.saveDownloadList(allItems);
    } catch (e) {
      if (_cancelled) return;
      rethrow;
    }
  }
}
