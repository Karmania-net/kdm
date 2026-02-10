import 'dart:convert';

enum DownloadStatus { pending, downloading, paused, completed, error }

class SegmentState {
  const SegmentState({
    required this.start,
    required this.end,
    this.done = false,
  });
  final int start;
  final int end;
  final bool done;

  Map<String, dynamic> toJson() => {'start': start, 'end': end, 'done': done};

  factory SegmentState.fromJson(Map<String, dynamic> json) {
    return SegmentState(
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
      done: json['done'] as bool? ?? false,
    );
  }
}

class DownloadItem {
  DownloadItem({
    required this.id,
    required this.url,
    required this.savePath,
    required this.filename,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.bytesTotal = 0,
    this.bytesDone = 0,
    this.speedBytesPerSecond,
    this.errorMessage,
    List<SegmentState>? segments,
  }) : segments = segments ?? [];

  final String id;
  final String url;
  final String savePath;
  final String filename;
  DownloadStatus status;
  double progress;
  int bytesTotal;
  int bytesDone;
  int? speedBytesPerSecond;
  String? errorMessage;
  List<SegmentState> segments;

  String get displayName => filename.isNotEmpty
      ? filename
      : Uri.tryParse(url)?.pathSegments.last ?? url;

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'savePath': savePath,
    'filename': filename,
    'status': status.name,
    'progress': progress,
    'bytesTotal': bytesTotal,
    'bytesDone': bytesDone,
    'speedBytesPerSecond': speedBytesPerSecond,
    'errorMessage': errorMessage,
    'segments': segments.map((s) => s.toJson()).toList(),
  };

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] as String,
      url: json['url'] as String,
      savePath: json['savePath'] as String,
      filename: json['filename'] as String? ?? '',
      status: DownloadStatus.values.byName(
        (json['status'] as String?) ?? 'pending',
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      bytesTotal: (json['bytesTotal'] as num?)?.toInt() ?? 0,
      bytesDone: (json['bytesDone'] as num?)?.toInt() ?? 0,
      speedBytesPerSecond: (json['speedBytesPerSecond'] as num?)?.toInt(),
      errorMessage: json['errorMessage'] as String?,
      segments:
          (json['segments'] as List<dynamic>?)
              ?.map((e) => SegmentState.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static String listToJson(List<DownloadItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  static List<DownloadItem> listFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    final list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map((e) => DownloadItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
