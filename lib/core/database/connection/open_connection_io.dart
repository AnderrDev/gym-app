import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Impl mobile/desktop: `drift_flutter` abre `gym_local.sqlite` en
/// `getApplicationDocumentsDirectory()` con sqlite3 nativo
/// (`sqlite3_flutter_libs`). Síncrono — devuelve un `LazyDatabase`
/// internamente.
QueryExecutor openConnection() => driftDatabase(name: 'gym_local');
