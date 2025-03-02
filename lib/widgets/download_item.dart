import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/download_controller.dart';
import '../models/download_task.dart';

class DownloadItem extends StatelessWidget {
  final DownloadTask task;
  
  const DownloadItem({Key? key, required this.task}) : super(key: key);
  
  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _getStatusText(DownloadStatus status) {
    print('Download status id : $status');
    switch (status) {
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      default:
        return 'Pending';
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return Icons.cloud_download;
      case DownloadStatus.paused:
        return Icons.pause_circle_outlined;
      case DownloadStatus.completed:
        return Icons.check_circle_outline;
      case DownloadStatus.failed:
        return Icons.error_outline;
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DownloadController>();
    final theme = Theme.of(context);
    
    return Obx(() {
      
      final progress = task.totalBytes.value > 0
          ? (task.receivedBytes.value / task.totalBytes.value)
          : 0.0;
      
      
      final fileName = task.url.split('/').last;
      
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: _getStatusColor(task.status.value),
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getStatusColor(task.status.value).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getStatusIcon(task.status.value),
                          size: 22,
                          color: _getStatusColor(task.status.value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(task.status.value),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getStatusText(task.status.value),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _getStatusColor(task.status.value),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  
                  if(task.status != DownloadStatus.completed)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(task.status.value),
                            ),
                          ),
                          Text(
                            '${_formatFileSize(task.receivedBytes.value)} / ${_formatFileSize(task.totalBytes.value)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 8,
                            width: MediaQuery.of(context).size.width * progress,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getStatusColor(task.status.value).withOpacity(0.7),
                                  _getStatusColor(task.status.value),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      
                      if (task.status.value == DownloadStatus.downloading)
                        _buildActionButton(
                          icon: Icons.pause_rounded,
                          label: 'Pause',
                          color: Colors.blue,
                          onPressed: () => controller.pauseDownload(task),
                        ),
                      
                      
                      if (task.status.value == DownloadStatus.paused)
                        _buildActionButton(
                          icon: Icons.play_arrow_rounded,
                          label: 'Resume',
                          color: Colors.blue,
                          onPressed: () => controller.resumeDownload(task),
                        ),
                      
                      const SizedBox(width: 8),
                      
                      
                      _buildActionButton(
                        icon: Icons.close_rounded,
                        label:task.status==DownloadStatus.completed?'Delete & Clear': 'Cancel',
                        color: Colors.red,
                        onPressed: () => controller.cancelDownload(task),
                        isOutlined: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: isOutlined
                ? Border.all(color: color.withOpacity(0.5), width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}