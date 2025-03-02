import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/download_controller.dart';
import 'download_item.dart';

class DownloadList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DownloadController>();

    return Obx(() => ListView.builder(
          itemCount: controller.downloadTasks.length,
          itemBuilder: (context, index) {
            return DownloadItem(task: controller.downloadTasks[index]);
          },
        ));
  }
}