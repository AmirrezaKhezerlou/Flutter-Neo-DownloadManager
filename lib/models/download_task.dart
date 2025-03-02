import 'package:dio/dio.dart';
import 'package:get/get.dart';

class DownloadTask {
  final String url;
  String savePath;
  var totalBytes = 0.obs; 
  var receivedBytes = 0.obs; 
  var status = DownloadStatus.pending.obs; 
  CancelToken? cancelToken;

  DownloadTask({
    required this.url,
    required this.savePath,
    int totalBytes = 0,
    int receivedBytes = 0,
    DownloadStatus status = DownloadStatus.pending,
    this.cancelToken,
  }) {
    this.totalBytes.value = totalBytes;
    this.receivedBytes.value = receivedBytes;
    this.status.value = status;
  }

  DownloadTask copyWith({
    String? savePath,
    int? totalBytes,
    int? receivedBytes,
    DownloadStatus? status,
    CancelToken? cancelToken,
  }) {
    return DownloadTask(
      url: this.url,
      savePath: savePath ?? this.savePath,
      totalBytes: totalBytes ?? this.totalBytes.value,
      receivedBytes: receivedBytes ?? this.receivedBytes.value,
      status: status ?? this.status.value,
      cancelToken: cancelToken ?? this.cancelToken,
    );
  }
}

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
}
