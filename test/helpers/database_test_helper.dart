import 'package:drift/native.dart';

import 'package:gym_flutter/core/database/local_database.dart';

/// Abre una [`LocalDatabase`] en memoria (sin tocar disco). Pensado para
/// tests unitarios — corre `onCreate` cada vez, así cada test arranca con un
/// esquema limpio y la fila de bookkeeping `schema_initialized_at` ya
/// sembrada.
LocalDatabase openInMemoryDb() =>
    LocalDatabase.forTesting(NativeDatabase.memory());
