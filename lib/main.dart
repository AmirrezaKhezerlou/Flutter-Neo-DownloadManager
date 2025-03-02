import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:download_manager/download_manager_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import 'controllers/download_controller.dart';
import 'widgets/download_list.dart';


void writeLog(String message) {
  print(message); 
  final logFile = File('C:\\Users\\Public\\download_manager_log.txt');
  final timestamp = DateTime.now().toIso8601String();
  logFile.writeAsStringSync('$timestamp - $message\n', mode: FileMode.append);
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  writeLog("Application arguments: ${args.join(", ")}");
  PlatformChannelManager(); 
  await trayManager.setIcon("assets/app_icon.ico");
  trayManager.setToolTip("Flutter Download Manager");

  Menu menu = Menu(items: [
    MenuItem(key: 'show_window', label: 'Show Window'),
    MenuItem.separator(),
    MenuItem(key: 'exit_app', label: 'Exit App'),
  ]);

  await trayManager.setContextMenu(menu);
  trayManager.addListener(MyTrayListener());

  bool isStartup = args.contains("--silent");

  writeLog("Application started. isStartup: $isStartup");

  addToStartup();
  startServer();
  writeLog("Server started.");
  runApp(MyApp(isStartup: isStartup));
  writeLog("Flutter UI initialized.");
  
}

void addToStartup() {
  String appPath = Platform.resolvedExecutable;

  Process.run('reg', [
    'add',
    r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
    '/v',
    'FlutterDownloadManager',
    '/t',
    'REG_SZ',
    '/d',
    '"$appPath" --silent',
    '/f'
  ]);
}




class MyTrayListener extends TrayListener {
  @override
  void onTrayIconMouseDown() {
    showMainWindow();
  }
  @override
  void onTrayIconRightMouseDown() {
     trayManager.popUpContextMenu();
    super.onTrayIconRightMouseDown();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      showMainWindow();
    } else if (menuItem.key == 'exit_app') {
      exit(0); 
    }
  }
}


void showMainWindow()async {
  writeLog("Try icon clicked showing ui ....");
  try{
   await windowManager.show();
      await windowManager.focus();
  }catch(e){
    writeLog(e.toString());
  }

}



void startServer() async {
  var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 5000);
  print("Listening on port 5000...");

  server.listen((HttpRequest request) async {
    if (request.uri.path == '/download') {
      String? url = request.uri.queryParameters['url'];
      if (url != null) {
        DownloadManager.handleDownloadLink(url);
      }
      request.response.write("Received");
      await request.response.close();
    } else if (request.uri.path == '/ping') {
      request.response.statusCode = 200;
      request.response.write("Running");
      await request.response.close();
    }
  });
}

class MyApp extends StatelessWidget {
  final bool isStartup;

  const MyApp({super.key, required this.isStartup});
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (isStartup) {
        await Future.delayed(Duration(seconds: 2));
        await windowManager.hide();
      }
    });
    Get.put(DownloadController());
    return GetMaterialApp(
      title: 'Download Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shadowColor: Colors.blue.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blue, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIconColor: Colors.blue.shade300,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        dividerTheme: DividerThemeData(
          thickness: 1,
          space: 24,
          color: Colors.grey.shade200,
        ),
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade800,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blue, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIconColor: Colors.blue.shade300,
        ),
        dividerTheme: DividerThemeData(
          thickness: 1,
          space: 24,
          color: Colors.grey.shade800,
        ),
      ),
      themeMode: ThemeMode.system,
      home: DownloadManagerScreen(),
    );
  }
}

class DownloadManagerScreen extends StatelessWidget {
  final TextEditingController _urlController = TextEditingController();
  final controller = Get.find<DownloadController>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_rounded, size: 24),
            SizedBox(width: 12),
            Text("Download Manager"),
          ],
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded),
            tooltip: 'Add New Download',
            onPressed: () => _showAddLinkDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.folder_rounded),
            tooltip: 'Open Download Folder',
            onPressed: () => controller.openDownloadFolder(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _showClearConfirmDialog(context);
                  break;
                case 'settings':
                  
                  break;
              }
            },
            icon: Icon(Icons.more_vert_rounded),
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 3,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded,
                        color: colorScheme.error, size: 20),
                    SizedBox(width: 12),
                    Text('Clear All Downloads',
                        style: TextStyle(color: colorScheme.error)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.2),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
            child: Column(
              children: [
                Card(
                  elevation: 3,
                  shadowColor: colorScheme.primary.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: colorScheme.surfaceVariant,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: isSmallScreen
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _urlController,
                                decoration: InputDecoration(
                                  hintText: 'Paste download link here...',
                                  prefixIcon: Icon(Icons.link_rounded),
                                ),
                              ),
                              SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _handleDownload(),
                                icon: Icon(Icons.download_rounded),
                                label: Text('Download'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  minimumSize: Size(double.infinity, 48),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _urlController,
                                  decoration: InputDecoration(
                                    hintText: 'Paste download link here...',
                                    prefixIcon: Icon(Icons.link_rounded),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () => _handleDownload(),
                                icon: Icon(Icons.download_rounded),
                                label: Text('Download'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  minimumSize: Size(140, 56),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shadowColor: colorScheme.shadow.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: colorScheme.surfaceVariant.withOpacity(0.7),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.download_done_rounded,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Downloads',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer
                                        .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Obx(() => Text(
                                        '${controller.downloadTasks.length} files',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      )),
                                ),
                              ],
                            ),
                          ),
                          Divider(),
                          Expanded(
                            child: DownloadList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ), 
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLinkDialog(context),
        icon: Icon(Icons.add_rounded),
        label: Text("Add"),
        tooltip: 'Add New Download',
        elevation: 3,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Built with ❤ by AmirrezaKhezerlou',style: TextStyle(color: Colors.white),)
        ],
      ),
    );
  }

  void _handleDownload() {
    if (_urlController.text.trim().isNotEmpty) {
      controller.startDownload(_urlController.text.trim());
      _urlController.clear();
    } else {
      Get.snackbar(
        'Invalid URL',
        'Please enter a valid download link',
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
        icon: Icon(Icons.error_outline_rounded, color: Colors.red),
        duration: Duration(seconds: 3),
      );
    }
  }

  void _showAddLinkDialog(BuildContext context) {
    final dialogController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_link_rounded,
                  color: colorScheme.primary, size: 24),
              SizedBox(width: 12),
              Text('Add New Download'),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 8),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the URL of the file you want to download:',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: dialogController,
                  decoration: InputDecoration(
                     hintText: 'https://example.com/file.zip',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (dialogController.text.trim().isNotEmpty) {
                  controller.startDownload(dialogController.text.trim());
                  Navigator.pop(context);
                }
              },
              icon: Icon(Icons.download_rounded, size: 18),
              label: Text('Start Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          buttonPadding: EdgeInsets.zero,
        );
      },
    );
  }

  void _showClearConfirmDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded,
              color: colorScheme.error, size: 28),
          title: Text('Clear All Downloads'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Text(
            'Are you sure you want to clear all downloads? This action cannot be undone.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                controller.clearAllTasks();
                Navigator.pop(context);
                Get.snackbar(
                  'Downloads Cleared',
                  'All download tasks have been removed',
                  snackPosition: SnackPosition.BOTTOM,
                  margin: EdgeInsets.all(16),
                  borderRadius: 12,
                  icon: Icon(Icons.check_circle_outline_rounded,
                      color: Colors.green),
                  duration: Duration(seconds: 3),
                );
              },
              icon: Icon(Icons.delete_outline_rounded, size: 18),
              label: Text('Clear All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          buttonPadding: EdgeInsets.zero,
        );
      },
    );
  }
}
