import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../models/download_task.dart';
import '../services/database_service.dart';
import 'package:open_file/open_file.dart'; 

class DownloadController extends GetxController {
  RxList<DownloadTask> downloadTasks = <DownloadTask>[].obs;
  final Dio _dio = Dio();
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  void onInit() {
    super.onInit();
    _loadTasksFromDB();
  }

  Future<void> _loadTasksFromDB() async {
    final tasks = await _dbService.getTasks();
    downloadTasks.assignAll(tasks);
  }

  Future<String> _getDownloadPath(String url) async {
    final dir = await getDownloadsDirectory();
    final fileName = url.split('/').last;
    return '${dir!.path}\\${fileName}';
  }

  void startDownload(String url) async {
    if (url.isEmpty || !Uri.parse(url).isAbsolute) {
      Get.snackbar('Error', 'Invalid URL');
      return;
    }
    final savePath = await _getDownloadPath(url);
    final task = DownloadTask(
      url: url,
      savePath: savePath,
      cancelToken: CancelToken(),
    );

    downloadTasks.add(task);
    await _dbService.insertTask(task);
    _downloadFile(task);
  }

  void _downloadFile(DownloadTask task) async {
    try {
      final file = File(task.savePath);
      int startByte = task.receivedBytes.value;

      if (await file.exists()) {
        startByte = await file.length();
      }

      _updateTask(task, status: DownloadStatus.pending);

      await _dio.download(
        task.url,
        task.savePath,
        cancelToken: task.cancelToken,
        options: Options(
          headers: {'range': 'bytes=$startByte-'},
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final updatedTask = task.copyWith(
              receivedBytes: startByte + received,
              totalBytes: startByte + total,
            );
            _updateTask(updatedTask,status: DownloadStatus.downloading);
          }
        },
      );

      _updateTask(task,
          status: DownloadStatus.completed, receivedBytes: task.totalBytes.value);
    } catch (e) {
      if (!task.cancelToken!.isCancelled) {
        _updateTask(task, status: DownloadStatus.failed);
      }
      Get.snackbar('Error', 'Download failed: $e');
    }
  }

  void pauseDownload(DownloadTask task) {
    if (task.status == DownloadStatus.downloading) {
      task.cancelToken?.cancel();
      _updateTask(task, status: DownloadStatus.paused);
    }
  }

  void resumeDownload(DownloadTask task) {
    if (task.status == DownloadStatus.paused) {
      final newTask = task.copyWith(
        status: DownloadStatus.downloading,
        cancelToken: CancelToken(),
      );
      _updateTask(newTask);
      _downloadFile(newTask);
    }
  }

  void cancelDownload(DownloadTask task) {
    task.cancelToken?.cancel();
    downloadTasks.remove(task);
    _dbService.deleteTask(task.url);
    try{
   File(task.savePath).deleteSync();
    }catch(e){
      print(e.toString());
    }
 
  }

  void handleCustomProtocol(String rawUrl) {
   final url = rawUrl.replaceFirst("myapp://", "");
    startDownload(Uri.decodeFull(url));
  }

  void _updateTask(DownloadTask task, {DownloadStatus? status, int? receivedBytes}) {
    final index = downloadTasks.indexWhere((t) => t.url == task.url);
    if (index != -1) {
      downloadTasks[index] = task.copyWith(
        status: status ?? task.status.value,
        receivedBytes: receivedBytes ?? task.receivedBytes.value,
      );
      _dbService.updateTask(downloadTasks[index]);
    }
  }

  void clearAllTasks() async {
    for (var task in downloadTasks) {
      task.cancelToken?.cancel();
      File(task.savePath).deleteSync();
    }
    downloadTasks.clear();
    final db = await _dbService.database;
    await db.delete('downloads');
    Get.snackbar('Success', 'All tasks cleared');
  }

  void openDownloadFolder() async {
    final dir = await getDownloadsDirectory();
    if (dir != null) {
      await OpenFile.open(dir.path);
    } else {
      Get.snackbar('Error', 'Could not open download folder');
    }
  }
}