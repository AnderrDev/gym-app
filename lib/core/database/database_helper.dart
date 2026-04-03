import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

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
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(
        filePath,
        version: 6,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      return await openDatabase(
        path,
        version: 6,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future _createDB(Database db, int version) async {
    const textType    = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const doubleType  = 'REAL NOT NULL';
    const boolType    = 'INTEGER NOT NULL';

    // Días de rutina (plantilla: Lunes = Pecho y Tríceps)
    await db.execute('''
      CREATE TABLE routine_days (
        id         TEXT PRIMARY KEY,
        routine_id $textType,
        day_of_week $integerType,
        name       $textType
      )
    ''');

    // Caché de ejercicios por día
    // PK: '{routine_day_id}_{exercise_id}' — evita conflictos cuando el mismo
    // ejercicio aparece en varios días (ej. Press Banca en Lunes Y Viernes)
    await db.execute('''
      CREATE TABLE exercises (
        id             TEXT PRIMARY KEY,
        routine_day_id $textType,
        exercise_id    $textType,
        name           $textType,
        target_weight  $doubleType,
        target_reps    $integerType,
        target_sets    $integerType
      )
    ''');

    // Sesiones de entrenamiento
    await db.execute('''
      CREATE TABLE workouts (
        id             TEXT PRIMARY KEY,
        user_id        $textType,
        routine_day_id $textType,
        session_date   $textType,
        started_at     $textType,
        completed_at   TEXT,
        total_volume   REAL DEFAULT 0.0,
        is_synced      $boolType DEFAULT 0
      )
    ''');

    // Series (set_logs)
    // id es nullable: si no viene de Supabase, SQLite auto-genera un rowid
    // created_at tiene DEFAULT para no requerir valor en inserción
    await db.execute('''
      CREATE TABLE set_logs (
        id            TEXT,
        session_id    $textType,
        exercise_id   $textType,
        actual_weight $doubleType,
        actual_reps   $integerType,
        set_index     $integerType,
        created_at    TEXT DEFAULT (datetime('now')),
        is_synced     $boolType DEFAULT 0
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // En desarrollo: limpiar y recrear todo
    await db.execute('DROP TABLE IF EXISTS routine_days');
    await db.execute('DROP TABLE IF EXISTS exercises');
    await db.execute('DROP TABLE IF EXISTS workouts');
    await db.execute('DROP TABLE IF EXISTS set_logs');
    await db.execute('DROP TABLE IF EXISTS routine_exercises');
    await _createDB(db, newVersion);
  }

  Future<List<Map<String, dynamic>>> getAllRows(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    await db.delete('workouts');
    await db.delete('set_logs');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
