import 'package:download_manager/controllers/download_controller.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class DownloadManager {
  static Future<void> handleDownloadLink(String url) async {
    try {
      if (!await windowManager.isVisible()) {
        await windowManager.show();
        await windowManager.focus();
      }

      await Future.delayed(Duration(milliseconds: 500));

      DownloadController controller = Get.find();
      controller.startDownload(url);
    } catch (e) {
      print("Error handling download link: $e");
    }
  }
}

class PlatformChannelManager {
  static final PlatformChannelManager _instance =
      PlatformChannelManager._internal();
  factory PlatformChannelManager() => _instance;

  static const MethodChannel platform =
      MethodChannel('com.example.download_manager');

  PlatformChannelManager._internal() {
    _setupMethodCallHandler();
  }

  void _setupMethodCallHandler() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'showUI') {
        print("✅ MethodChannel received: showUI");
        await Future.delayed(
            Duration(milliseconds: 300)); 
        await windowManager.show();
        await windowManager.focus();
      }
    });
  }

  Future<void> invokeShowUI() async {
    try {
      await platform.invokeMethod('showUI');
    } catch (e) {
      print("❌ Error invoking showUI: $e");
    }
  }
}
