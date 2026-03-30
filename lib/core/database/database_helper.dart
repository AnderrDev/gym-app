import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gym_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL'; // 0 for false, 1 for true

    // Table for Workouts (Sessions)
    await db.execute('''
      CREATE TABLE workouts (
        id $idType,
        user_id $textType,
        name $textType,
        started_at $textType,
        ended_at TEXT,
        is_synced $boolType DEFAULT 0
      )
    ''');

    // Table for Set Logs
    await db.execute('''
      CREATE TABLE set_logs (
        id $idType,
        session_id $textType,
        exercise_id $textType,
        actual_weight $doubleType,
        actual_reps $integerType,
        set_index $integerType,
        created_at $textType,
        is_synced $boolType DEFAULT 0
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
