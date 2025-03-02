import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; 
import '../models/download_task.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init() {
 
    if (Platform.isWindows) {
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('downloads.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE downloads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL,
            savePath TEXT NOT NULL,
            totalBytes INTEGER,
            receivedBytes INTEGER,
            status TEXT NOT NULL
          )
        ''');
      },
    );
  }

Future<void> insertTask(DownloadTask task) async {
  final db = await database;
  await db.insert(
    'downloads',
    {
      'url': task.url,
      'savePath': task.savePath,
      'totalBytes': task.totalBytes.value,
      'receivedBytes': task.receivedBytes.value,
      'status': task.status.value.toString().split('.').last,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> updateTask(DownloadTask task) async {
  final db = await database;
  await db.update(
    'downloads',
    {
      'totalBytes': task.totalBytes.value, 
      'receivedBytes': task.receivedBytes.value,
      'status': task.status.value.toString().split('.').last,
    },
    where: 'url = ?',
    whereArgs: [task.url],
  );
}

  Future<List<DownloadTask>> getTasks() async {
    final db = await database;
    final result = await db.query('downloads');
    return result.map((map) {
      return DownloadTask(
        url: map['url'] as String,
        savePath: map['savePath'] as String,
        totalBytes: map['totalBytes'] as int? ?? 0,
        receivedBytes: map['receivedBytes'] as int? ?? 0,
        status: DownloadStatus.values.firstWhere(
          (e) => e.toString().split('.').last == map['status'],
        ),
      );
    }).toList();
  }

  Future<void> deleteTask(String url) async {
    final db = await database;
    await db.delete('downloads', where: 'url = ?', whereArgs: [url]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}