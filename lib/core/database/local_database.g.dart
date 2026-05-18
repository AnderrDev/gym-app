// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaRow extends DataClass implements Insertable<AppMetaRow> {
  final String key;
  final String value;

  /// Epoch en milisegundos (UTC) del último write. Usamos INTEGER en lugar de
  /// DateTime para que el formato sea independiente del codec drift y trivial
  /// de inspeccionar desde sqlite3 CLI.
  final int updatedAt;
  const AppMetaRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppMetaRow copyWith({String? key, String? value, int? updatedAt}) =>
      AppMetaRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppMetaRow copyWithCompanion(AppMetaCompanion data) {
    return AppMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedRoutineDaysTable extends CachedRoutineDays
    with TableInfo<$CachedRoutineDaysTable, CachedRoutineDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRoutineDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
    'routine_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetSetsCountMeta = const VerificationMeta(
    'targetSetsCount',
  );
  @override
  late final GeneratedColumn<int> targetSetsCount = GeneratedColumn<int>(
    'target_sets_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    routineId,
    dayOfWeek,
    name,
    targetSetsCount,
    status,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_routine_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedRoutineDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_sets_count')) {
      context.handle(
        _targetSetsCountMeta,
        targetSetsCount.isAcceptableOrUnknown(
          data['target_sets_count']!,
          _targetSetsCountMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedRoutineDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedRoutineDayRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_id'],
      )!,
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      targetSetsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_sets_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedRoutineDaysTable createAlias(String alias) {
    return $CachedRoutineDaysTable(attachedDatabase, alias);
  }
}

class CachedRoutineDayRow extends DataClass
    implements Insertable<CachedRoutineDayRow> {
  final String id;
  final String routineId;
  final int dayOfWeek;
  final String name;
  final int targetSetsCount;
  final String status;

  /// Epoch ms (UTC) del último write desde remote. Usado para invalidar / TTL.
  final int fetchedAt;
  const CachedRoutineDayRow({
    required this.id,
    required this.routineId,
    required this.dayOfWeek,
    required this.name,
    required this.targetSetsCount,
    required this.status,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['routine_id'] = Variable<String>(routineId);
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['name'] = Variable<String>(name);
    map['target_sets_count'] = Variable<int>(targetSetsCount);
    map['status'] = Variable<String>(status);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  CachedRoutineDaysCompanion toCompanion(bool nullToAbsent) {
    return CachedRoutineDaysCompanion(
      id: Value(id),
      routineId: Value(routineId),
      dayOfWeek: Value(dayOfWeek),
      name: Value(name),
      targetSetsCount: Value(targetSetsCount),
      status: Value(status),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedRoutineDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedRoutineDayRow(
      id: serializer.fromJson<String>(json['id']),
      routineId: serializer.fromJson<String>(json['routineId']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      name: serializer.fromJson<String>(json['name']),
      targetSetsCount: serializer.fromJson<int>(json['targetSetsCount']),
      status: serializer.fromJson<String>(json['status']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'routineId': serializer.toJson<String>(routineId),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'name': serializer.toJson<String>(name),
      'targetSetsCount': serializer.toJson<int>(targetSetsCount),
      'status': serializer.toJson<String>(status),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  CachedRoutineDayRow copyWith({
    String? id,
    String? routineId,
    int? dayOfWeek,
    String? name,
    int? targetSetsCount,
    String? status,
    int? fetchedAt,
  }) => CachedRoutineDayRow(
    id: id ?? this.id,
    routineId: routineId ?? this.routineId,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    name: name ?? this.name,
    targetSetsCount: targetSetsCount ?? this.targetSetsCount,
    status: status ?? this.status,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedRoutineDayRow copyWithCompanion(CachedRoutineDaysCompanion data) {
    return CachedRoutineDayRow(
      id: data.id.present ? data.id.value : this.id,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      name: data.name.present ? data.name.value : this.name,
      targetSetsCount: data.targetSetsCount.present
          ? data.targetSetsCount.value
          : this.targetSetsCount,
      status: data.status.present ? data.status.value : this.status,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedRoutineDayRow(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('name: $name, ')
          ..write('targetSetsCount: $targetSetsCount, ')
          ..write('status: $status, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    routineId,
    dayOfWeek,
    name,
    targetSetsCount,
    status,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedRoutineDayRow &&
          other.id == this.id &&
          other.routineId == this.routineId &&
          other.dayOfWeek == this.dayOfWeek &&
          other.name == this.name &&
          other.targetSetsCount == this.targetSetsCount &&
          other.status == this.status &&
          other.fetchedAt == this.fetchedAt);
}

class CachedRoutineDaysCompanion extends UpdateCompanion<CachedRoutineDayRow> {
  final Value<String> id;
  final Value<String> routineId;
  final Value<int> dayOfWeek;
  final Value<String> name;
  final Value<int> targetSetsCount;
  final Value<String> status;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const CachedRoutineDaysCompanion({
    this.id = const Value.absent(),
    this.routineId = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.name = const Value.absent(),
    this.targetSetsCount = const Value.absent(),
    this.status = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedRoutineDaysCompanion.insert({
    required String id,
    required String routineId,
    required int dayOfWeek,
    required String name,
    this.targetSetsCount = const Value.absent(),
    this.status = const Value.absent(),
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       routineId = Value(routineId),
       dayOfWeek = Value(dayOfWeek),
       name = Value(name),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedRoutineDayRow> custom({
    Expression<String>? id,
    Expression<String>? routineId,
    Expression<int>? dayOfWeek,
    Expression<String>? name,
    Expression<int>? targetSetsCount,
    Expression<String>? status,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routineId != null) 'routine_id': routineId,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (name != null) 'name': name,
      if (targetSetsCount != null) 'target_sets_count': targetSetsCount,
      if (status != null) 'status': status,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedRoutineDaysCompanion copyWith({
    Value<String>? id,
    Value<String>? routineId,
    Value<int>? dayOfWeek,
    Value<String>? name,
    Value<int>? targetSetsCount,
    Value<String>? status,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedRoutineDaysCompanion(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      name: name ?? this.name,
      targetSetsCount: targetSetsCount ?? this.targetSetsCount,
      status: status ?? this.status,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetSetsCount.present) {
      map['target_sets_count'] = Variable<int>(targetSetsCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedRoutineDaysCompanion(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('name: $name, ')
          ..write('targetSetsCount: $targetSetsCount, ')
          ..write('status: $status, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedRoutineExercisesTable extends CachedRoutineExercises
    with TableInfo<$CachedRoutineExercisesTable, CachedRoutineExerciseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRoutineExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _routineDayIdMeta = const VerificationMeta(
    'routineDayId',
  );
  @override
  late final GeneratedColumn<String> routineDayId = GeneratedColumn<String>(
    'routine_day_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetSetsMeta = const VerificationMeta(
    'targetSets',
  );
  @override
  late final GeneratedColumn<int> targetSets = GeneratedColumn<int>(
    'target_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetRepsMeta = const VerificationMeta(
    'targetReps',
  );
  @override
  late final GeneratedColumn<int> targetReps = GeneratedColumn<int>(
    'target_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetWeightMeta = const VerificationMeta(
    'targetWeight',
  );
  @override
  late final GeneratedColumn<double> targetWeight = GeneratedColumn<double>(
    'target_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restTimerSecondsMeta = const VerificationMeta(
    'restTimerSeconds',
  );
  @override
  late final GeneratedColumn<int> restTimerSeconds = GeneratedColumn<int>(
    'rest_timer_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(90),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    routineDayId,
    exerciseId,
    position,
    targetSets,
    targetReps,
    targetWeight,
    restTimerSeconds,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_routine_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedRoutineExerciseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('routine_day_id')) {
      context.handle(
        _routineDayIdMeta,
        routineDayId.isAcceptableOrUnknown(
          data['routine_day_id']!,
          _routineDayIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_routineDayIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('target_sets')) {
      context.handle(
        _targetSetsMeta,
        targetSets.isAcceptableOrUnknown(data['target_sets']!, _targetSetsMeta),
      );
    } else if (isInserting) {
      context.missing(_targetSetsMeta);
    }
    if (data.containsKey('target_reps')) {
      context.handle(
        _targetRepsMeta,
        targetReps.isAcceptableOrUnknown(data['target_reps']!, _targetRepsMeta),
      );
    } else if (isInserting) {
      context.missing(_targetRepsMeta);
    }
    if (data.containsKey('target_weight')) {
      context.handle(
        _targetWeightMeta,
        targetWeight.isAcceptableOrUnknown(
          data['target_weight']!,
          _targetWeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetWeightMeta);
    }
    if (data.containsKey('rest_timer_seconds')) {
      context.handle(
        _restTimerSecondsMeta,
        restTimerSeconds.isAcceptableOrUnknown(
          data['rest_timer_seconds']!,
          _restTimerSecondsMeta,
        ),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {routineDayId, exerciseId};
  @override
  CachedRoutineExerciseRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedRoutineExerciseRow(
      routineDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_day_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      targetSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_sets'],
      )!,
      targetReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_reps'],
      )!,
      targetWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_weight'],
      )!,
      restTimerSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_timer_seconds'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedRoutineExercisesTable createAlias(String alias) {
    return $CachedRoutineExercisesTable(attachedDatabase, alias);
  }
}

class CachedRoutineExerciseRow extends DataClass
    implements Insertable<CachedRoutineExerciseRow> {
  final String routineDayId;
  final String exerciseId;
  final int position;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int restTimerSeconds;

  /// Epoch ms (UTC) del último write desde remote.
  final int fetchedAt;
  const CachedRoutineExerciseRow({
    required this.routineDayId,
    required this.exerciseId,
    required this.position,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.restTimerSeconds,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['routine_day_id'] = Variable<String>(routineDayId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['position'] = Variable<int>(position);
    map['target_sets'] = Variable<int>(targetSets);
    map['target_reps'] = Variable<int>(targetReps);
    map['target_weight'] = Variable<double>(targetWeight);
    map['rest_timer_seconds'] = Variable<int>(restTimerSeconds);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  CachedRoutineExercisesCompanion toCompanion(bool nullToAbsent) {
    return CachedRoutineExercisesCompanion(
      routineDayId: Value(routineDayId),
      exerciseId: Value(exerciseId),
      position: Value(position),
      targetSets: Value(targetSets),
      targetReps: Value(targetReps),
      targetWeight: Value(targetWeight),
      restTimerSeconds: Value(restTimerSeconds),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedRoutineExerciseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedRoutineExerciseRow(
      routineDayId: serializer.fromJson<String>(json['routineDayId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      targetSets: serializer.fromJson<int>(json['targetSets']),
      targetReps: serializer.fromJson<int>(json['targetReps']),
      targetWeight: serializer.fromJson<double>(json['targetWeight']),
      restTimerSeconds: serializer.fromJson<int>(json['restTimerSeconds']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'routineDayId': serializer.toJson<String>(routineDayId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'position': serializer.toJson<int>(position),
      'targetSets': serializer.toJson<int>(targetSets),
      'targetReps': serializer.toJson<int>(targetReps),
      'targetWeight': serializer.toJson<double>(targetWeight),
      'restTimerSeconds': serializer.toJson<int>(restTimerSeconds),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  CachedRoutineExerciseRow copyWith({
    String? routineDayId,
    String? exerciseId,
    int? position,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    int? restTimerSeconds,
    int? fetchedAt,
  }) => CachedRoutineExerciseRow(
    routineDayId: routineDayId ?? this.routineDayId,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    targetSets: targetSets ?? this.targetSets,
    targetReps: targetReps ?? this.targetReps,
    targetWeight: targetWeight ?? this.targetWeight,
    restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedRoutineExerciseRow copyWithCompanion(
    CachedRoutineExercisesCompanion data,
  ) {
    return CachedRoutineExerciseRow(
      routineDayId: data.routineDayId.present
          ? data.routineDayId.value
          : this.routineDayId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      targetSets: data.targetSets.present
          ? data.targetSets.value
          : this.targetSets,
      targetReps: data.targetReps.present
          ? data.targetReps.value
          : this.targetReps,
      targetWeight: data.targetWeight.present
          ? data.targetWeight.value
          : this.targetWeight,
      restTimerSeconds: data.restTimerSeconds.present
          ? data.restTimerSeconds.value
          : this.restTimerSeconds,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedRoutineExerciseRow(')
          ..write('routineDayId: $routineDayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('restTimerSeconds: $restTimerSeconds, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    routineDayId,
    exerciseId,
    position,
    targetSets,
    targetReps,
    targetWeight,
    restTimerSeconds,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedRoutineExerciseRow &&
          other.routineDayId == this.routineDayId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.targetSets == this.targetSets &&
          other.targetReps == this.targetReps &&
          other.targetWeight == this.targetWeight &&
          other.restTimerSeconds == this.restTimerSeconds &&
          other.fetchedAt == this.fetchedAt);
}

class CachedRoutineExercisesCompanion
    extends UpdateCompanion<CachedRoutineExerciseRow> {
  final Value<String> routineDayId;
  final Value<String> exerciseId;
  final Value<int> position;
  final Value<int> targetSets;
  final Value<int> targetReps;
  final Value<double> targetWeight;
  final Value<int> restTimerSeconds;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const CachedRoutineExercisesCompanion({
    this.routineDayId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.targetWeight = const Value.absent(),
    this.restTimerSeconds = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedRoutineExercisesCompanion.insert({
    required String routineDayId,
    required String exerciseId,
    required int position,
    required int targetSets,
    required int targetReps,
    required double targetWeight,
    this.restTimerSeconds = const Value.absent(),
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : routineDayId = Value(routineDayId),
       exerciseId = Value(exerciseId),
       position = Value(position),
       targetSets = Value(targetSets),
       targetReps = Value(targetReps),
       targetWeight = Value(targetWeight),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedRoutineExerciseRow> custom({
    Expression<String>? routineDayId,
    Expression<String>? exerciseId,
    Expression<int>? position,
    Expression<int>? targetSets,
    Expression<int>? targetReps,
    Expression<double>? targetWeight,
    Expression<int>? restTimerSeconds,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (routineDayId != null) 'routine_day_id': routineDayId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (targetSets != null) 'target_sets': targetSets,
      if (targetReps != null) 'target_reps': targetReps,
      if (targetWeight != null) 'target_weight': targetWeight,
      if (restTimerSeconds != null) 'rest_timer_seconds': restTimerSeconds,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedRoutineExercisesCompanion copyWith({
    Value<String>? routineDayId,
    Value<String>? exerciseId,
    Value<int>? position,
    Value<int>? targetSets,
    Value<int>? targetReps,
    Value<double>? targetWeight,
    Value<int>? restTimerSeconds,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedRoutineExercisesCompanion(
      routineDayId: routineDayId ?? this.routineDayId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (routineDayId.present) {
      map['routine_day_id'] = Variable<String>(routineDayId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (targetSets.present) {
      map['target_sets'] = Variable<int>(targetSets.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<int>(targetReps.value);
    }
    if (targetWeight.present) {
      map['target_weight'] = Variable<double>(targetWeight.value);
    }
    if (restTimerSeconds.present) {
      map['rest_timer_seconds'] = Variable<int>(restTimerSeconds.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedRoutineExercisesCompanion(')
          ..write('routineDayId: $routineDayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('restTimerSeconds: $restTimerSeconds, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedExercisesTable extends CachedExercises
    with TableInfo<$CachedExercisesTable, CachedExerciseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _muscleGroupMeta = const VerificationMeta(
    'muscleGroup',
  );
  @override
  late final GeneratedColumn<String> muscleGroup = GeneratedColumn<String>(
    'muscle_group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    muscleGroup,
    imageUrl,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedExerciseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('muscle_group')) {
      context.handle(
        _muscleGroupMeta,
        muscleGroup.isAcceptableOrUnknown(
          data['muscle_group']!,
          _muscleGroupMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedExerciseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedExerciseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      muscleGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}muscle_group'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedExercisesTable createAlias(String alias) {
    return $CachedExercisesTable(attachedDatabase, alias);
  }
}

class CachedExerciseRow extends DataClass
    implements Insertable<CachedExerciseRow> {
  final String id;
  final String name;
  final String muscleGroup;
  final String? imageUrl;

  /// Epoch ms (UTC) del último write desde remote.
  final int fetchedAt;
  const CachedExerciseRow({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.imageUrl,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['muscle_group'] = Variable<String>(muscleGroup);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  CachedExercisesCompanion toCompanion(bool nullToAbsent) {
    return CachedExercisesCompanion(
      id: Value(id),
      name: Value(name),
      muscleGroup: Value(muscleGroup),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedExerciseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedExerciseRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      muscleGroup: serializer.fromJson<String>(json['muscleGroup']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'muscleGroup': serializer.toJson<String>(muscleGroup),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  CachedExerciseRow copyWith({
    String? id,
    String? name,
    String? muscleGroup,
    Value<String?> imageUrl = const Value.absent(),
    int? fetchedAt,
  }) => CachedExerciseRow(
    id: id ?? this.id,
    name: name ?? this.name,
    muscleGroup: muscleGroup ?? this.muscleGroup,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedExerciseRow copyWithCompanion(CachedExercisesCompanion data) {
    return CachedExerciseRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      muscleGroup: data.muscleGroup.present
          ? data.muscleGroup.value
          : this.muscleGroup,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedExerciseRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, muscleGroup, imageUrl, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedExerciseRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.muscleGroup == this.muscleGroup &&
          other.imageUrl == this.imageUrl &&
          other.fetchedAt == this.fetchedAt);
}

class CachedExercisesCompanion extends UpdateCompanion<CachedExerciseRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> muscleGroup;
  final Value<String?> imageUrl;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const CachedExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.muscleGroup = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedExercisesCompanion.insert({
    required String id,
    required String name,
    this.muscleGroup = const Value.absent(),
    this.imageUrl = const Value.absent(),
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedExerciseRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? muscleGroup,
    Expression<String>? imageUrl,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (muscleGroup != null) 'muscle_group': muscleGroup,
      if (imageUrl != null) 'image_url': imageUrl,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? muscleGroup,
    Value<String?>? imageUrl,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      imageUrl: imageUrl ?? this.imageUrl,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (muscleGroup.present) {
      map['muscle_group'] = Variable<String>(muscleGroup.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedLastPerformancesTable extends CachedLastPerformances
    with TableInfo<$CachedLastPerformancesTable, CachedLastPerformanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedLastPerformancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setLogIdMeta = const VerificationMeta(
    'setLogId',
  );
  @override
  late final GeneratedColumn<String> setLogId = GeneratedColumn<String>(
    'set_log_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualWeightMeta = const VerificationMeta(
    'actualWeight',
  );
  @override
  late final GeneratedColumn<double> actualWeight = GeneratedColumn<double>(
    'actual_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualRepsMeta = const VerificationMeta(
    'actualReps',
  );
  @override
  late final GeneratedColumn<int> actualReps = GeneratedColumn<int>(
    'actual_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setIndexMeta = const VerificationMeta(
    'setIndex',
  );
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _performedAtMeta = const VerificationMeta(
    'performedAt',
  );
  @override
  late final GeneratedColumn<int> performedAt = GeneratedColumn<int>(
    'performed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    exerciseId,
    setLogId,
    sessionId,
    actualWeight,
    actualReps,
    setIndex,
    performedAt,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_last_performances';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedLastPerformanceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('set_log_id')) {
      context.handle(
        _setLogIdMeta,
        setLogId.isAcceptableOrUnknown(data['set_log_id']!, _setLogIdMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('actual_weight')) {
      context.handle(
        _actualWeightMeta,
        actualWeight.isAcceptableOrUnknown(
          data['actual_weight']!,
          _actualWeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualWeightMeta);
    }
    if (data.containsKey('actual_reps')) {
      context.handle(
        _actualRepsMeta,
        actualReps.isAcceptableOrUnknown(data['actual_reps']!, _actualRepsMeta),
      );
    } else if (isInserting) {
      context.missing(_actualRepsMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('performed_at')) {
      context.handle(
        _performedAtMeta,
        performedAt.isAcceptableOrUnknown(
          data['performed_at']!,
          _performedAtMeta,
        ),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, exerciseId};
  @override
  CachedLastPerformanceRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedLastPerformanceRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      setLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_log_id'],
      ),
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      actualWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}actual_weight'],
      )!,
      actualReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_reps'],
      )!,
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_index'],
      )!,
      performedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}performed_at'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedLastPerformancesTable createAlias(String alias) {
    return $CachedLastPerformancesTable(attachedDatabase, alias);
  }
}

class CachedLastPerformanceRow extends DataClass
    implements Insertable<CachedLastPerformanceRow> {
  final String userId;
  final String exerciseId;
  final String? setLogId;
  final String sessionId;
  final double actualWeight;
  final int actualReps;
  final int setIndex;

  /// Epoch ms (UTC) del `created_at` del set_log original (cuándo se realizó).
  /// Nullable si el remote no lo devolvió.
  final int? performedAt;

  /// Epoch ms (UTC) del último write desde remote.
  final int fetchedAt;
  const CachedLastPerformanceRow({
    required this.userId,
    required this.exerciseId,
    this.setLogId,
    required this.sessionId,
    required this.actualWeight,
    required this.actualReps,
    required this.setIndex,
    this.performedAt,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['exercise_id'] = Variable<String>(exerciseId);
    if (!nullToAbsent || setLogId != null) {
      map['set_log_id'] = Variable<String>(setLogId);
    }
    map['session_id'] = Variable<String>(sessionId);
    map['actual_weight'] = Variable<double>(actualWeight);
    map['actual_reps'] = Variable<int>(actualReps);
    map['set_index'] = Variable<int>(setIndex);
    if (!nullToAbsent || performedAt != null) {
      map['performed_at'] = Variable<int>(performedAt);
    }
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  CachedLastPerformancesCompanion toCompanion(bool nullToAbsent) {
    return CachedLastPerformancesCompanion(
      userId: Value(userId),
      exerciseId: Value(exerciseId),
      setLogId: setLogId == null && nullToAbsent
          ? const Value.absent()
          : Value(setLogId),
      sessionId: Value(sessionId),
      actualWeight: Value(actualWeight),
      actualReps: Value(actualReps),
      setIndex: Value(setIndex),
      performedAt: performedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(performedAt),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedLastPerformanceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedLastPerformanceRow(
      userId: serializer.fromJson<String>(json['userId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      setLogId: serializer.fromJson<String?>(json['setLogId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      actualWeight: serializer.fromJson<double>(json['actualWeight']),
      actualReps: serializer.fromJson<int>(json['actualReps']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      performedAt: serializer.fromJson<int?>(json['performedAt']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'setLogId': serializer.toJson<String?>(setLogId),
      'sessionId': serializer.toJson<String>(sessionId),
      'actualWeight': serializer.toJson<double>(actualWeight),
      'actualReps': serializer.toJson<int>(actualReps),
      'setIndex': serializer.toJson<int>(setIndex),
      'performedAt': serializer.toJson<int?>(performedAt),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  CachedLastPerformanceRow copyWith({
    String? userId,
    String? exerciseId,
    Value<String?> setLogId = const Value.absent(),
    String? sessionId,
    double? actualWeight,
    int? actualReps,
    int? setIndex,
    Value<int?> performedAt = const Value.absent(),
    int? fetchedAt,
  }) => CachedLastPerformanceRow(
    userId: userId ?? this.userId,
    exerciseId: exerciseId ?? this.exerciseId,
    setLogId: setLogId.present ? setLogId.value : this.setLogId,
    sessionId: sessionId ?? this.sessionId,
    actualWeight: actualWeight ?? this.actualWeight,
    actualReps: actualReps ?? this.actualReps,
    setIndex: setIndex ?? this.setIndex,
    performedAt: performedAt.present ? performedAt.value : this.performedAt,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedLastPerformanceRow copyWithCompanion(
    CachedLastPerformancesCompanion data,
  ) {
    return CachedLastPerformanceRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      setLogId: data.setLogId.present ? data.setLogId.value : this.setLogId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      actualWeight: data.actualWeight.present
          ? data.actualWeight.value
          : this.actualWeight,
      actualReps: data.actualReps.present
          ? data.actualReps.value
          : this.actualReps,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      performedAt: data.performedAt.present
          ? data.performedAt.value
          : this.performedAt,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedLastPerformanceRow(')
          ..write('userId: $userId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setLogId: $setLogId, ')
          ..write('sessionId: $sessionId, ')
          ..write('actualWeight: $actualWeight, ')
          ..write('actualReps: $actualReps, ')
          ..write('setIndex: $setIndex, ')
          ..write('performedAt: $performedAt, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    exerciseId,
    setLogId,
    sessionId,
    actualWeight,
    actualReps,
    setIndex,
    performedAt,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedLastPerformanceRow &&
          other.userId == this.userId &&
          other.exerciseId == this.exerciseId &&
          other.setLogId == this.setLogId &&
          other.sessionId == this.sessionId &&
          other.actualWeight == this.actualWeight &&
          other.actualReps == this.actualReps &&
          other.setIndex == this.setIndex &&
          other.performedAt == this.performedAt &&
          other.fetchedAt == this.fetchedAt);
}

class CachedLastPerformancesCompanion
    extends UpdateCompanion<CachedLastPerformanceRow> {
  final Value<String> userId;
  final Value<String> exerciseId;
  final Value<String?> setLogId;
  final Value<String> sessionId;
  final Value<double> actualWeight;
  final Value<int> actualReps;
  final Value<int> setIndex;
  final Value<int?> performedAt;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const CachedLastPerformancesCompanion({
    this.userId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.setLogId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.actualWeight = const Value.absent(),
    this.actualReps = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.performedAt = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedLastPerformancesCompanion.insert({
    required String userId,
    required String exerciseId,
    this.setLogId = const Value.absent(),
    required String sessionId,
    required double actualWeight,
    required int actualReps,
    required int setIndex,
    this.performedAt = const Value.absent(),
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       exerciseId = Value(exerciseId),
       sessionId = Value(sessionId),
       actualWeight = Value(actualWeight),
       actualReps = Value(actualReps),
       setIndex = Value(setIndex),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedLastPerformanceRow> custom({
    Expression<String>? userId,
    Expression<String>? exerciseId,
    Expression<String>? setLogId,
    Expression<String>? sessionId,
    Expression<double>? actualWeight,
    Expression<int>? actualReps,
    Expression<int>? setIndex,
    Expression<int>? performedAt,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (setLogId != null) 'set_log_id': setLogId,
      if (sessionId != null) 'session_id': sessionId,
      if (actualWeight != null) 'actual_weight': actualWeight,
      if (actualReps != null) 'actual_reps': actualReps,
      if (setIndex != null) 'set_index': setIndex,
      if (performedAt != null) 'performed_at': performedAt,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedLastPerformancesCompanion copyWith({
    Value<String>? userId,
    Value<String>? exerciseId,
    Value<String?>? setLogId,
    Value<String>? sessionId,
    Value<double>? actualWeight,
    Value<int>? actualReps,
    Value<int>? setIndex,
    Value<int?>? performedAt,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedLastPerformancesCompanion(
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      setLogId: setLogId ?? this.setLogId,
      sessionId: sessionId ?? this.sessionId,
      actualWeight: actualWeight ?? this.actualWeight,
      actualReps: actualReps ?? this.actualReps,
      setIndex: setIndex ?? this.setIndex,
      performedAt: performedAt ?? this.performedAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (setLogId.present) {
      map['set_log_id'] = Variable<String>(setLogId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (actualWeight.present) {
      map['actual_weight'] = Variable<double>(actualWeight.value);
    }
    if (actualReps.present) {
      map['actual_reps'] = Variable<int>(actualReps.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (performedAt.present) {
      map['performed_at'] = Variable<int>(performedAt.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedLastPerformancesCompanion(')
          ..write('userId: $userId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setLogId: $setLogId, ')
          ..write('sessionId: $sessionId, ')
          ..write('actualWeight: $actualWeight, ')
          ..write('actualReps: $actualReps, ')
          ..write('setIndex: $setIndex, ')
          ..write('performedAt: $performedAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedWorkoutSessionsTable extends CachedWorkoutSessions
    with TableInfo<$CachedWorkoutSessionsTable, CachedWorkoutSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedWorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routineDayIdMeta = const VerificationMeta(
    'routineDayId',
  );
  @override
  late final GeneratedColumn<String> routineDayId = GeneratedColumn<String>(
    'routine_day_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionDateMeta = const VerificationMeta(
    'sessionDate',
  );
  @override
  late final GeneratedColumn<String> sessionDate = GeneratedColumn<String>(
    'session_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalTargetSetsMeta = const VerificationMeta(
    'totalTargetSets',
  );
  @override
  late final GeneratedColumn<int> totalTargetSets = GeneratedColumn<int>(
    'total_target_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedSetsCountMeta =
      const VerificationMeta('completedSetsCount');
  @override
  late final GeneratedColumn<int> completedSetsCount = GeneratedColumn<int>(
    'completed_sets_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coachingAnalysisJsonMeta =
      const VerificationMeta('coachingAnalysisJson');
  @override
  late final GeneratedColumn<String> coachingAnalysisJson =
      GeneratedColumn<String>(
        'coaching_analysis_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    routineDayId,
    sessionDate,
    startedAt,
    completedAt,
    totalTargetSets,
    completedSetsCount,
    coachingAnalysisJson,
    syncStatus,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_workout_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedWorkoutSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('routine_day_id')) {
      context.handle(
        _routineDayIdMeta,
        routineDayId.isAcceptableOrUnknown(
          data['routine_day_id']!,
          _routineDayIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_routineDayIdMeta);
    }
    if (data.containsKey('session_date')) {
      context.handle(
        _sessionDateMeta,
        sessionDate.isAcceptableOrUnknown(
          data['session_date']!,
          _sessionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionDateMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('total_target_sets')) {
      context.handle(
        _totalTargetSetsMeta,
        totalTargetSets.isAcceptableOrUnknown(
          data['total_target_sets']!,
          _totalTargetSetsMeta,
        ),
      );
    }
    if (data.containsKey('completed_sets_count')) {
      context.handle(
        _completedSetsCountMeta,
        completedSetsCount.isAcceptableOrUnknown(
          data['completed_sets_count']!,
          _completedSetsCountMeta,
        ),
      );
    }
    if (data.containsKey('coaching_analysis_json')) {
      context.handle(
        _coachingAnalysisJsonMeta,
        coachingAnalysisJson.isAcceptableOrUnknown(
          data['coaching_analysis_json']!,
          _coachingAnalysisJsonMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedWorkoutSessionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedWorkoutSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      routineDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_day_id'],
      )!,
      sessionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_date'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      totalTargetSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_target_sets'],
      )!,
      completedSetsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_sets_count'],
      )!,
      coachingAnalysisJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coaching_analysis_json'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedWorkoutSessionsTable createAlias(String alias) {
    return $CachedWorkoutSessionsTable(attachedDatabase, alias);
  }
}

class CachedWorkoutSessionRow extends DataClass
    implements Insertable<CachedWorkoutSessionRow> {
  final String id;
  final String userId;
  final String routineDayId;

  /// ISO `yyyy-MM-dd`.
  final String sessionDate;

  /// Epoch ms (UTC) del momento en que se inició la sesión localmente.
  final int startedAt;

  /// Epoch ms (UTC). `null` mientras la sesión esté abierta.
  final int? completedAt;
  final int totalTargetSets;
  final int completedSetsCount;

  /// JSON serializado de `List<CoachingAnalysis>` cuando el remote ya
  /// devolvió el coaching final. Null si aún no se ha generado.
  final String? coachingAnalysisJson;

  /// Estado de sincronización: `pending`, `syncing`, `synced`, `error`.
  final String syncStatus;

  /// Epoch ms (UTC) del último write local (insert o update).
  final int fetchedAt;
  const CachedWorkoutSessionRow({
    required this.id,
    required this.userId,
    required this.routineDayId,
    required this.sessionDate,
    required this.startedAt,
    this.completedAt,
    required this.totalTargetSets,
    required this.completedSetsCount,
    this.coachingAnalysisJson,
    required this.syncStatus,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['routine_day_id'] = Variable<String>(routineDayId);
    map['session_date'] = Variable<String>(sessionDate);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    map['total_target_sets'] = Variable<int>(totalTargetSets);
    map['completed_sets_count'] = Variable<int>(completedSetsCount);
    if (!nullToAbsent || coachingAnalysisJson != null) {
      map['coaching_analysis_json'] = Variable<String>(coachingAnalysisJson);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  CachedWorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return CachedWorkoutSessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      routineDayId: Value(routineDayId),
      sessionDate: Value(sessionDate),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      totalTargetSets: Value(totalTargetSets),
      completedSetsCount: Value(completedSetsCount),
      coachingAnalysisJson: coachingAnalysisJson == null && nullToAbsent
          ? const Value.absent()
          : Value(coachingAnalysisJson),
      syncStatus: Value(syncStatus),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedWorkoutSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedWorkoutSessionRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      routineDayId: serializer.fromJson<String>(json['routineDayId']),
      sessionDate: serializer.fromJson<String>(json['sessionDate']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      totalTargetSets: serializer.fromJson<int>(json['totalTargetSets']),
      completedSetsCount: serializer.fromJson<int>(json['completedSetsCount']),
      coachingAnalysisJson: serializer.fromJson<String?>(
        json['coachingAnalysisJson'],
      ),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'routineDayId': serializer.toJson<String>(routineDayId),
      'sessionDate': serializer.toJson<String>(sessionDate),
      'startedAt': serializer.toJson<int>(startedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
      'totalTargetSets': serializer.toJson<int>(totalTargetSets),
      'completedSetsCount': serializer.toJson<int>(completedSetsCount),
      'coachingAnalysisJson': serializer.toJson<String?>(coachingAnalysisJson),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  CachedWorkoutSessionRow copyWith({
    String? id,
    String? userId,
    String? routineDayId,
    String? sessionDate,
    int? startedAt,
    Value<int?> completedAt = const Value.absent(),
    int? totalTargetSets,
    int? completedSetsCount,
    Value<String?> coachingAnalysisJson = const Value.absent(),
    String? syncStatus,
    int? fetchedAt,
  }) => CachedWorkoutSessionRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    routineDayId: routineDayId ?? this.routineDayId,
    sessionDate: sessionDate ?? this.sessionDate,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    totalTargetSets: totalTargetSets ?? this.totalTargetSets,
    completedSetsCount: completedSetsCount ?? this.completedSetsCount,
    coachingAnalysisJson: coachingAnalysisJson.present
        ? coachingAnalysisJson.value
        : this.coachingAnalysisJson,
    syncStatus: syncStatus ?? this.syncStatus,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedWorkoutSessionRow copyWithCompanion(
    CachedWorkoutSessionsCompanion data,
  ) {
    return CachedWorkoutSessionRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      routineDayId: data.routineDayId.present
          ? data.routineDayId.value
          : this.routineDayId,
      sessionDate: data.sessionDate.present
          ? data.sessionDate.value
          : this.sessionDate,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      totalTargetSets: data.totalTargetSets.present
          ? data.totalTargetSets.value
          : this.totalTargetSets,
      completedSetsCount: data.completedSetsCount.present
          ? data.completedSetsCount.value
          : this.completedSetsCount,
      coachingAnalysisJson: data.coachingAnalysisJson.present
          ? data.coachingAnalysisJson.value
          : this.coachingAnalysisJson,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedWorkoutSessionRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('routineDayId: $routineDayId, ')
          ..write('sessionDate: $sessionDate, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('totalTargetSets: $totalTargetSets, ')
          ..write('completedSetsCount: $completedSetsCount, ')
          ..write('coachingAnalysisJson: $coachingAnalysisJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    routineDayId,
    sessionDate,
    startedAt,
    completedAt,
    totalTargetSets,
    completedSetsCount,
    coachingAnalysisJson,
    syncStatus,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedWorkoutSessionRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.routineDayId == this.routineDayId &&
          other.sessionDate == this.sessionDate &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.totalTargetSets == this.totalTargetSets &&
          other.completedSetsCount == this.completedSetsCount &&
          other.coachingAnalysisJson == this.coachingAnalysisJson &&
          other.syncStatus == this.syncStatus &&
          other.fetchedAt == this.fetchedAt);
}

class CachedWorkoutSessionsCompanion
    extends UpdateCompanion<CachedWorkoutSessionRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> routineDayId;
  final Value<String> sessionDate;
  final Value<int> startedAt;
  final Value<int?> completedAt;
  final Value<int> totalTargetSets;
  final Value<int> completedSetsCount;
  final Value<String?> coachingAnalysisJson;
  final Value<String> syncStatus;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const CachedWorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.routineDayId = const Value.absent(),
    this.sessionDate = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.totalTargetSets = const Value.absent(),
    this.completedSetsCount = const Value.absent(),
    this.coachingAnalysisJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedWorkoutSessionsCompanion.insert({
    required String id,
    required String userId,
    required String routineDayId,
    required String sessionDate,
    required int startedAt,
    this.completedAt = const Value.absent(),
    this.totalTargetSets = const Value.absent(),
    this.completedSetsCount = const Value.absent(),
    this.coachingAnalysisJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       routineDayId = Value(routineDayId),
       sessionDate = Value(sessionDate),
       startedAt = Value(startedAt),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedWorkoutSessionRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? routineDayId,
    Expression<String>? sessionDate,
    Expression<int>? startedAt,
    Expression<int>? completedAt,
    Expression<int>? totalTargetSets,
    Expression<int>? completedSetsCount,
    Expression<String>? coachingAnalysisJson,
    Expression<String>? syncStatus,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (routineDayId != null) 'routine_day_id': routineDayId,
      if (sessionDate != null) 'session_date': sessionDate,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (totalTargetSets != null) 'total_target_sets': totalTargetSets,
      if (completedSetsCount != null)
        'completed_sets_count': completedSetsCount,
      if (coachingAnalysisJson != null)
        'coaching_analysis_json': coachingAnalysisJson,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedWorkoutSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? routineDayId,
    Value<String>? sessionDate,
    Value<int>? startedAt,
    Value<int?>? completedAt,
    Value<int>? totalTargetSets,
    Value<int>? completedSetsCount,
    Value<String?>? coachingAnalysisJson,
    Value<String>? syncStatus,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedWorkoutSessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      routineDayId: routineDayId ?? this.routineDayId,
      sessionDate: sessionDate ?? this.sessionDate,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      totalTargetSets: totalTargetSets ?? this.totalTargetSets,
      completedSetsCount: completedSetsCount ?? this.completedSetsCount,
      coachingAnalysisJson: coachingAnalysisJson ?? this.coachingAnalysisJson,
      syncStatus: syncStatus ?? this.syncStatus,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (routineDayId.present) {
      map['routine_day_id'] = Variable<String>(routineDayId.value);
    }
    if (sessionDate.present) {
      map['session_date'] = Variable<String>(sessionDate.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (totalTargetSets.present) {
      map['total_target_sets'] = Variable<int>(totalTargetSets.value);
    }
    if (completedSetsCount.present) {
      map['completed_sets_count'] = Variable<int>(completedSetsCount.value);
    }
    if (coachingAnalysisJson.present) {
      map['coaching_analysis_json'] = Variable<String>(
        coachingAnalysisJson.value,
      );
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedWorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('routineDayId: $routineDayId, ')
          ..write('sessionDate: $sessionDate, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('totalTargetSets: $totalTargetSets, ')
          ..write('completedSetsCount: $completedSetsCount, ')
          ..write('coachingAnalysisJson: $coachingAnalysisJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedSetLogsTable extends CachedSetLogs
    with TableInfo<$CachedSetLogsTable, CachedSetLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSetLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setIndexMeta = const VerificationMeta(
    'setIndex',
  );
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualWeightMeta = const VerificationMeta(
    'actualWeight',
  );
  @override
  late final GeneratedColumn<double> actualWeight = GeneratedColumn<double>(
    'actual_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualRepsMeta = const VerificationMeta(
    'actualReps',
  );
  @override
  late final GeneratedColumn<int> actualReps = GeneratedColumn<int>(
    'actual_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    exerciseId,
    setIndex,
    actualWeight,
    actualReps,
    createdAt,
    remoteId,
    syncStatus,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_set_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSetLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('actual_weight')) {
      context.handle(
        _actualWeightMeta,
        actualWeight.isAcceptableOrUnknown(
          data['actual_weight']!,
          _actualWeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualWeightMeta);
    }
    if (data.containsKey('actual_reps')) {
      context.handle(
        _actualRepsMeta,
        actualReps.isAcceptableOrUnknown(data['actual_reps']!, _actualRepsMeta),
      );
    } else if (isInserting) {
      context.missing(_actualRepsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, exerciseId, setIndex};
  @override
  CachedSetLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSetLogRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_index'],
      )!,
      actualWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}actual_weight'],
      )!,
      actualReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_reps'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedSetLogsTable createAlias(String alias) {
    return $CachedSetLogsTable(attachedDatabase, alias);
  }
}

class CachedSetLogRow extends DataClass implements Insertable<CachedSetLogRow> {
  final String sessionId;
  final String exerciseId;
  final int setIndex;
  final double actualWeight;
  final int actualReps;

  /// Epoch ms (UTC) — cuándo se registró el set localmente.
  final int createdAt;

  /// Id remoto asignado tras el primer upsert exitoso (cuando el backend lo
  /// devuelve). Hasta entonces el log se identifica solo por la PK compuesta.
  final String? remoteId;

  /// Estado de sincronización: `pending`, `syncing`, `synced`, `error`.
  final String syncStatus;

  /// Epoch ms (UTC) del último write local.
  final int fetchedAt;
  const CachedSetLogRow({
    required this.sessionId,
    required this.exerciseId,
    required this.setIndex,
    required this.actualWeight,
    required this.actualReps,
    required this.createdAt,
    this.remoteId,
    required this.syncStatus,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['set_index'] = Variable<int>(setIndex);
    map['actual_weight'] = Variable<double>(actualWeight);
    map['actual_reps'] = Variable<int>(actualReps);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  CachedSetLogsCompanion toCompanion(bool nullToAbsent) {
    return CachedSetLogsCompanion(
      sessionId: Value(sessionId),
      exerciseId: Value(exerciseId),
      setIndex: Value(setIndex),
      actualWeight: Value(actualWeight),
      actualReps: Value(actualReps),
      createdAt: Value(createdAt),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      syncStatus: Value(syncStatus),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedSetLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSetLogRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      actualWeight: serializer.fromJson<double>(json['actualWeight']),
      actualReps: serializer.fromJson<int>(json['actualReps']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'setIndex': serializer.toJson<int>(setIndex),
      'actualWeight': serializer.toJson<double>(actualWeight),
      'actualReps': serializer.toJson<int>(actualReps),
      'createdAt': serializer.toJson<int>(createdAt),
      'remoteId': serializer.toJson<String?>(remoteId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  CachedSetLogRow copyWith({
    String? sessionId,
    String? exerciseId,
    int? setIndex,
    double? actualWeight,
    int? actualReps,
    int? createdAt,
    Value<String?> remoteId = const Value.absent(),
    String? syncStatus,
    int? fetchedAt,
  }) => CachedSetLogRow(
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId ?? this.exerciseId,
    setIndex: setIndex ?? this.setIndex,
    actualWeight: actualWeight ?? this.actualWeight,
    actualReps: actualReps ?? this.actualReps,
    createdAt: createdAt ?? this.createdAt,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    syncStatus: syncStatus ?? this.syncStatus,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedSetLogRow copyWithCompanion(CachedSetLogsCompanion data) {
    return CachedSetLogRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      actualWeight: data.actualWeight.present
          ? data.actualWeight.value
          : this.actualWeight,
      actualReps: data.actualReps.present
          ? data.actualReps.value
          : this.actualReps,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSetLogRow(')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('actualWeight: $actualWeight, ')
          ..write('actualReps: $actualReps, ')
          ..write('createdAt: $createdAt, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    exerciseId,
    setIndex,
    actualWeight,
    actualReps,
    createdAt,
    remoteId,
    syncStatus,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSetLogRow &&
          other.sessionId == this.sessionId &&
          other.exerciseId == this.exerciseId &&
          other.setIndex == this.setIndex &&
          other.actualWeight == this.actualWeight &&
          other.actualReps == this.actualReps &&
          other.createdAt == this.createdAt &&
          other.remoteId == this.remoteId &&
          other.syncStatus == this.syncStatus &&
          other.fetchedAt == this.fetchedAt);
}

class CachedSetLogsCompanion extends UpdateCompanion<CachedSetLogRow> {
  final Value<String> sessionId;
  final Value<String> exerciseId;
  final Value<int> setIndex;
  final Value<double> actualWeight;
  final Value<int> actualReps;
  final Value<int> createdAt;
  final Value<String?> remoteId;
  final Value<String> syncStatus;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const CachedSetLogsCompanion({
    this.sessionId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.actualWeight = const Value.absent(),
    this.actualReps = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSetLogsCompanion.insert({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
    required double actualWeight,
    required int actualReps,
    required int createdAt,
    this.remoteId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       exerciseId = Value(exerciseId),
       setIndex = Value(setIndex),
       actualWeight = Value(actualWeight),
       actualReps = Value(actualReps),
       createdAt = Value(createdAt),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedSetLogRow> custom({
    Expression<String>? sessionId,
    Expression<String>? exerciseId,
    Expression<int>? setIndex,
    Expression<double>? actualWeight,
    Expression<int>? actualReps,
    Expression<int>? createdAt,
    Expression<String>? remoteId,
    Expression<String>? syncStatus,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (setIndex != null) 'set_index': setIndex,
      if (actualWeight != null) 'actual_weight': actualWeight,
      if (actualReps != null) 'actual_reps': actualReps,
      if (createdAt != null) 'created_at': createdAt,
      if (remoteId != null) 'remote_id': remoteId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSetLogsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? exerciseId,
    Value<int>? setIndex,
    Value<double>? actualWeight,
    Value<int>? actualReps,
    Value<int>? createdAt,
    Value<String?>? remoteId,
    Value<String>? syncStatus,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedSetLogsCompanion(
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      setIndex: setIndex ?? this.setIndex,
      actualWeight: actualWeight ?? this.actualWeight,
      actualReps: actualReps ?? this.actualReps,
      createdAt: createdAt ?? this.createdAt,
      remoteId: remoteId ?? this.remoteId,
      syncStatus: syncStatus ?? this.syncStatus,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (actualWeight.present) {
      map['actual_weight'] = Variable<double>(actualWeight.value);
    }
    if (actualReps.present) {
      map['actual_reps'] = Variable<int>(actualReps.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSetLogsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('actualWeight: $actualWeight, ')
          ..write('actualReps: $actualReps, ')
          ..write('createdAt: $createdAt, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingMutationsTable extends PendingMutations
    with TableInfo<$PendingMutationsTable, PendingMutationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingMutationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<int> lastAttemptAt = GeneratedColumn<int>(
    'last_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lockTokenMeta = const VerificationMeta(
    'lockToken',
  );
  @override
  late final GeneratedColumn<String> lockToken = GeneratedColumn<String>(
    'lock_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    payloadJson,
    attempts,
    lastError,
    lastAttemptAt,
    createdAt,
    nextAttemptAt,
    lockToken,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_mutations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingMutationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('lock_token')) {
      context.handle(
        _lockTokenMeta,
        lockToken.isAcceptableOrUnknown(data['lock_token']!, _lockTokenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingMutationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingMutationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_attempt_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lockToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lock_token'],
      ),
    );
  }

  @override
  $PendingMutationsTable createAlias(String alias) {
    return $PendingMutationsTable(attachedDatabase, alias);
  }
}

class PendingMutationRow extends DataClass
    implements Insertable<PendingMutationRow> {
  final int id;

  /// Tipo de mutación (string del enum MutationKind). Determina el shape
  /// de `payloadJson` y a qué método del remote llamar.
  final String kind;

  /// Payload serializado (JSON). Snapshot inmutable: el SyncWorker no
  /// reabre la entidad desde la cache local — usa este blob como contrato.
  final String payloadJson;

  /// Intentos acumulados. Solo incrementa en fallos retriable (no en pausas
  /// por auth ni en éxitos).
  final int attempts;

  /// Último error capturado en formato textual. Solo para diagnóstico /
  /// observabilidad — nunca lo lee la UI.
  final String? lastError;

  /// Epoch ms (UTC) del último intento (éxito o fallo).
  final int? lastAttemptAt;

  /// Epoch ms (UTC) cuándo se encoló.
  final int createdAt;

  /// Epoch ms (UTC) — punto a partir del cual la mutación es retomable. La
  /// query de `peekReady` filtra `next_attempt_at IS NULL OR next_attempt_at <= now`.
  final int? nextAttemptAt;

  /// Token opaco para señalizar que un worker la está procesando. Se libera
  /// en éxito/fallo y por `releaseStaleLocks` al arrancar.
  final String? lockToken;
  const PendingMutationRow({
    required this.id,
    required this.kind,
    required this.payloadJson,
    required this.attempts,
    this.lastError,
    this.lastAttemptAt,
    required this.createdAt,
    this.nextAttemptAt,
    this.lockToken,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['payload_json'] = Variable<String>(payloadJson);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    }
    if (!nullToAbsent || lockToken != null) {
      map['lock_token'] = Variable<String>(lockToken);
    }
    return map;
  }

  PendingMutationsCompanion toCompanion(bool nullToAbsent) {
    return PendingMutationsCompanion(
      id: Value(id),
      kind: Value(kind),
      payloadJson: Value(payloadJson),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      createdAt: Value(createdAt),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lockToken: lockToken == null && nullToAbsent
          ? const Value.absent()
          : Value(lockToken),
    );
  }

  factory PendingMutationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingMutationRow(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      lastAttemptAt: serializer.fromJson<int?>(json['lastAttemptAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      nextAttemptAt: serializer.fromJson<int?>(json['nextAttemptAt']),
      lockToken: serializer.fromJson<String?>(json['lockToken']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'lastAttemptAt': serializer.toJson<int?>(lastAttemptAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'nextAttemptAt': serializer.toJson<int?>(nextAttemptAt),
      'lockToken': serializer.toJson<String?>(lockToken),
    };
  }

  PendingMutationRow copyWith({
    int? id,
    String? kind,
    String? payloadJson,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    Value<int?> lastAttemptAt = const Value.absent(),
    int? createdAt,
    Value<int?> nextAttemptAt = const Value.absent(),
    Value<String?> lockToken = const Value.absent(),
  }) => PendingMutationRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    payloadJson: payloadJson ?? this.payloadJson,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    createdAt: createdAt ?? this.createdAt,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lockToken: lockToken.present ? lockToken.value : this.lockToken,
  );
  PendingMutationRow copyWithCompanion(PendingMutationsCompanion data) {
    return PendingMutationRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lockToken: data.lockToken.present ? data.lockToken.value : this.lockToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingMutationRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lockToken: $lockToken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    payloadJson,
    attempts,
    lastError,
    lastAttemptAt,
    createdAt,
    nextAttemptAt,
    lockToken,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingMutationRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.payloadJson == this.payloadJson &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.createdAt == this.createdAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lockToken == this.lockToken);
}

class PendingMutationsCompanion extends UpdateCompanion<PendingMutationRow> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> payloadJson;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<int?> lastAttemptAt;
  final Value<int> createdAt;
  final Value<int?> nextAttemptAt;
  final Value<String?> lockToken;
  const PendingMutationsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lockToken = const Value.absent(),
  });
  PendingMutationsCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String payloadJson,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    required int createdAt,
    this.nextAttemptAt = const Value.absent(),
    this.lockToken = const Value.absent(),
  }) : kind = Value(kind),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<PendingMutationRow> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? payloadJson,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? lastAttemptAt,
    Expression<int>? createdAt,
    Expression<int>? nextAttemptAt,
    Expression<String>? lockToken,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (createdAt != null) 'created_at': createdAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lockToken != null) 'lock_token': lockToken,
    });
  }

  PendingMutationsCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? payloadJson,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<int?>? lastAttemptAt,
    Value<int>? createdAt,
    Value<int?>? nextAttemptAt,
    Value<String?>? lockToken,
  }) {
    return PendingMutationsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      payloadJson: payloadJson ?? this.payloadJson,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      createdAt: createdAt ?? this.createdAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lockToken: lockToken ?? this.lockToken,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (lockToken.present) {
      map['lock_token'] = Variable<String>(lockToken.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingMutationsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lockToken: $lockToken')
          ..write(')'))
        .toString();
  }
}

class $CachedAssignedRoutinesTable extends CachedAssignedRoutines
    with TableInfo<$CachedAssignedRoutinesTable, CachedAssignedRoutineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAssignedRoutinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
    'routine_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routineNameMeta = const VerificationMeta(
    'routineName',
  );
  @override
  late final GeneratedColumn<String> routineName = GeneratedColumn<String>(
    'routine_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPublicMeta = const VerificationMeta(
    'isPublic',
  );
  @override
  late final GeneratedColumn<bool> isPublic = GeneratedColumn<bool>(
    'is_public',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_public" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _creatorIdMeta = const VerificationMeta(
    'creatorId',
  );
  @override
  late final GeneratedColumn<String> creatorId = GeneratedColumn<String>(
    'creator_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creatorNameMeta = const VerificationMeta(
    'creatorName',
  );
  @override
  late final GeneratedColumn<String> creatorName = GeneratedColumn<String>(
    'creator_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exerciseCountMeta = const VerificationMeta(
    'exerciseCount',
  );
  @override
  late final GeneratedColumn<int> exerciseCount = GeneratedColumn<int>(
    'exercise_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    routineId,
    routineName,
    isPublic,
    creatorId,
    creatorName,
    exerciseCount,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_assigned_routines';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAssignedRoutineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('routine_name')) {
      context.handle(
        _routineNameMeta,
        routineName.isAcceptableOrUnknown(
          data['routine_name']!,
          _routineNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_routineNameMeta);
    }
    if (data.containsKey('is_public')) {
      context.handle(
        _isPublicMeta,
        isPublic.isAcceptableOrUnknown(data['is_public']!, _isPublicMeta),
      );
    }
    if (data.containsKey('creator_id')) {
      context.handle(
        _creatorIdMeta,
        creatorId.isAcceptableOrUnknown(data['creator_id']!, _creatorIdMeta),
      );
    }
    if (data.containsKey('creator_name')) {
      context.handle(
        _creatorNameMeta,
        creatorName.isAcceptableOrUnknown(
          data['creator_name']!,
          _creatorNameMeta,
        ),
      );
    }
    if (data.containsKey('exercise_count')) {
      context.handle(
        _exerciseCountMeta,
        exerciseCount.isAcceptableOrUnknown(
          data['exercise_count']!,
          _exerciseCountMeta,
        ),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, routineId};
  @override
  CachedAssignedRoutineRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAssignedRoutineRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_id'],
      )!,
      routineName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_name'],
      )!,
      isPublic: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_public'],
      )!,
      creatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_id'],
      ),
      creatorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_name'],
      ),
      exerciseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_count'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedAssignedRoutinesTable createAlias(String alias) {
    return $CachedAssignedRoutinesTable(attachedDatabase, alias);
  }
}

class CachedAssignedRoutineRow extends DataClass
    implements Insertable<CachedAssignedRoutineRow> {
  final String userId;
  final String routineId;
  final String routineName;
  final bool isPublic;
  final String? creatorId;
  final String? creatorName;
  final int exerciseCount;

  /// Epoch ms (UTC) del último write desde remote. Usado para invalidar / TTL.
  final int fetchedAt;
  const CachedAssignedRoutineRow({
    required this.userId,
    required this.routineId,
    required this.routineName,
    required this.isPublic,
    this.creatorId,
    this.creatorName,
    required this.exerciseCount,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['routine_id'] = Variable<String>(routineId);
    map['routine_name'] = Variable<String>(routineName);
    map['is_public'] = Variable<bool>(isPublic);
    if (!nullToAbsent || creatorId != null) {
      map['creator_id'] = Variable<String>(creatorId);
    }
    if (!nullToAbsent || creatorName != null) {
      map['creator_name'] = Variable<String>(creatorName);
    }
    map['exercise_count'] = Variable<int>(exerciseCount);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  CachedAssignedRoutinesCompanion toCompanion(bool nullToAbsent) {
    return CachedAssignedRoutinesCompanion(
      userId: Value(userId),
      routineId: Value(routineId),
      routineName: Value(routineName),
      isPublic: Value(isPublic),
      creatorId: creatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorId),
      creatorName: creatorName == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorName),
      exerciseCount: Value(exerciseCount),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedAssignedRoutineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAssignedRoutineRow(
      userId: serializer.fromJson<String>(json['userId']),
      routineId: serializer.fromJson<String>(json['routineId']),
      routineName: serializer.fromJson<String>(json['routineName']),
      isPublic: serializer.fromJson<bool>(json['isPublic']),
      creatorId: serializer.fromJson<String?>(json['creatorId']),
      creatorName: serializer.fromJson<String?>(json['creatorName']),
      exerciseCount: serializer.fromJson<int>(json['exerciseCount']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'routineId': serializer.toJson<String>(routineId),
      'routineName': serializer.toJson<String>(routineName),
      'isPublic': serializer.toJson<bool>(isPublic),
      'creatorId': serializer.toJson<String?>(creatorId),
      'creatorName': serializer.toJson<String?>(creatorName),
      'exerciseCount': serializer.toJson<int>(exerciseCount),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  CachedAssignedRoutineRow copyWith({
    String? userId,
    String? routineId,
    String? routineName,
    bool? isPublic,
    Value<String?> creatorId = const Value.absent(),
    Value<String?> creatorName = const Value.absent(),
    int? exerciseCount,
    int? fetchedAt,
  }) => CachedAssignedRoutineRow(
    userId: userId ?? this.userId,
    routineId: routineId ?? this.routineId,
    routineName: routineName ?? this.routineName,
    isPublic: isPublic ?? this.isPublic,
    creatorId: creatorId.present ? creatorId.value : this.creatorId,
    creatorName: creatorName.present ? creatorName.value : this.creatorName,
    exerciseCount: exerciseCount ?? this.exerciseCount,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedAssignedRoutineRow copyWithCompanion(
    CachedAssignedRoutinesCompanion data,
  ) {
    return CachedAssignedRoutineRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      routineName: data.routineName.present
          ? data.routineName.value
          : this.routineName,
      isPublic: data.isPublic.present ? data.isPublic.value : this.isPublic,
      creatorId: data.creatorId.present ? data.creatorId.value : this.creatorId,
      creatorName: data.creatorName.present
          ? data.creatorName.value
          : this.creatorName,
      exerciseCount: data.exerciseCount.present
          ? data.exerciseCount.value
          : this.exerciseCount,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAssignedRoutineRow(')
          ..write('userId: $userId, ')
          ..write('routineId: $routineId, ')
          ..write('routineName: $routineName, ')
          ..write('isPublic: $isPublic, ')
          ..write('creatorId: $creatorId, ')
          ..write('creatorName: $creatorName, ')
          ..write('exerciseCount: $exerciseCount, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    routineId,
    routineName,
    isPublic,
    creatorId,
    creatorName,
    exerciseCount,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAssignedRoutineRow &&
          other.userId == this.userId &&
          other.routineId == this.routineId &&
          other.routineName == this.routineName &&
          other.isPublic == this.isPublic &&
          other.creatorId == this.creatorId &&
          other.creatorName == this.creatorName &&
          other.exerciseCount == this.exerciseCount &&
          other.fetchedAt == this.fetchedAt);
}

class CachedAssignedRoutinesCompanion
    extends UpdateCompanion<CachedAssignedRoutineRow> {
  final Value<String> userId;
  final Value<String> routineId;
  final Value<String> routineName;
  final Value<bool> isPublic;
  final Value<String?> creatorId;
  final Value<String?> creatorName;
  final Value<int> exerciseCount;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const CachedAssignedRoutinesCompanion({
    this.userId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.routineName = const Value.absent(),
    this.isPublic = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.creatorName = const Value.absent(),
    this.exerciseCount = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAssignedRoutinesCompanion.insert({
    required String userId,
    required String routineId,
    required String routineName,
    this.isPublic = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.creatorName = const Value.absent(),
    this.exerciseCount = const Value.absent(),
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       routineId = Value(routineId),
       routineName = Value(routineName),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedAssignedRoutineRow> custom({
    Expression<String>? userId,
    Expression<String>? routineId,
    Expression<String>? routineName,
    Expression<bool>? isPublic,
    Expression<String>? creatorId,
    Expression<String>? creatorName,
    Expression<int>? exerciseCount,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (routineId != null) 'routine_id': routineId,
      if (routineName != null) 'routine_name': routineName,
      if (isPublic != null) 'is_public': isPublic,
      if (creatorId != null) 'creator_id': creatorId,
      if (creatorName != null) 'creator_name': creatorName,
      if (exerciseCount != null) 'exercise_count': exerciseCount,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAssignedRoutinesCompanion copyWith({
    Value<String>? userId,
    Value<String>? routineId,
    Value<String>? routineName,
    Value<bool>? isPublic,
    Value<String?>? creatorId,
    Value<String?>? creatorName,
    Value<int>? exerciseCount,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedAssignedRoutinesCompanion(
      userId: userId ?? this.userId,
      routineId: routineId ?? this.routineId,
      routineName: routineName ?? this.routineName,
      isPublic: isPublic ?? this.isPublic,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      exerciseCount: exerciseCount ?? this.exerciseCount,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (routineName.present) {
      map['routine_name'] = Variable<String>(routineName.value);
    }
    if (isPublic.present) {
      map['is_public'] = Variable<bool>(isPublic.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
    }
    if (creatorName.present) {
      map['creator_name'] = Variable<String>(creatorName.value);
    }
    if (exerciseCount.present) {
      map['exercise_count'] = Variable<int>(exerciseCount.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAssignedRoutinesCompanion(')
          ..write('userId: $userId, ')
          ..write('routineId: $routineId, ')
          ..write('routineName: $routineName, ')
          ..write('isPublic: $isPublic, ')
          ..write('creatorId: $creatorId, ')
          ..write('creatorName: $creatorName, ')
          ..write('exerciseCount: $exerciseCount, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedWeeklyInsightsTable extends CachedWeeklyInsights
    with TableInfo<$CachedWeeklyInsightsTable, CachedWeeklyInsightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedWeeklyInsightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
    'routine_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekStartMeta = const VerificationMeta(
    'weekStart',
  );
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
    'week_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    routineId,
    weekStart,
    payloadJson,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_weekly_insights';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedWeeklyInsightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('week_start')) {
      context.handle(
        _weekStartMeta,
        weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta),
      );
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, routineId, weekStart};
  @override
  CachedWeeklyInsightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedWeeklyInsightRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_id'],
      )!,
      weekStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}week_start'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedWeeklyInsightsTable createAlias(String alias) {
    return $CachedWeeklyInsightsTable(attachedDatabase, alias);
  }
}

class CachedWeeklyInsightRow extends DataClass
    implements Insertable<CachedWeeklyInsightRow> {
  final String userId;
  final String routineId;

  /// ISO `yyyy-MM-dd`.
  final String weekStart;
  final String payloadJson;

  /// Epoch ms (UTC) del último write desde remote.
  final int fetchedAt;
  const CachedWeeklyInsightRow({
    required this.userId,
    required this.routineId,
    required this.weekStart,
    required this.payloadJson,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['routine_id'] = Variable<String>(routineId);
    map['week_start'] = Variable<String>(weekStart);
    map['payload_json'] = Variable<String>(payloadJson);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  CachedWeeklyInsightsCompanion toCompanion(bool nullToAbsent) {
    return CachedWeeklyInsightsCompanion(
      userId: Value(userId),
      routineId: Value(routineId),
      weekStart: Value(weekStart),
      payloadJson: Value(payloadJson),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedWeeklyInsightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedWeeklyInsightRow(
      userId: serializer.fromJson<String>(json['userId']),
      routineId: serializer.fromJson<String>(json['routineId']),
      weekStart: serializer.fromJson<String>(json['weekStart']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'routineId': serializer.toJson<String>(routineId),
      'weekStart': serializer.toJson<String>(weekStart),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  CachedWeeklyInsightRow copyWith({
    String? userId,
    String? routineId,
    String? weekStart,
    String? payloadJson,
    int? fetchedAt,
  }) => CachedWeeklyInsightRow(
    userId: userId ?? this.userId,
    routineId: routineId ?? this.routineId,
    weekStart: weekStart ?? this.weekStart,
    payloadJson: payloadJson ?? this.payloadJson,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedWeeklyInsightRow copyWithCompanion(CachedWeeklyInsightsCompanion data) {
    return CachedWeeklyInsightRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedWeeklyInsightRow(')
          ..write('userId: $userId, ')
          ..write('routineId: $routineId, ')
          ..write('weekStart: $weekStart, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, routineId, weekStart, payloadJson, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedWeeklyInsightRow &&
          other.userId == this.userId &&
          other.routineId == this.routineId &&
          other.weekStart == this.weekStart &&
          other.payloadJson == this.payloadJson &&
          other.fetchedAt == this.fetchedAt);
}

class CachedWeeklyInsightsCompanion
    extends UpdateCompanion<CachedWeeklyInsightRow> {
  final Value<String> userId;
  final Value<String> routineId;
  final Value<String> weekStart;
  final Value<String> payloadJson;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const CachedWeeklyInsightsCompanion({
    this.userId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedWeeklyInsightsCompanion.insert({
    required String userId,
    required String routineId,
    required String weekStart,
    required String payloadJson,
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       routineId = Value(routineId),
       weekStart = Value(weekStart),
       payloadJson = Value(payloadJson),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedWeeklyInsightRow> custom({
    Expression<String>? userId,
    Expression<String>? routineId,
    Expression<String>? weekStart,
    Expression<String>? payloadJson,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (routineId != null) 'routine_id': routineId,
      if (weekStart != null) 'week_start': weekStart,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedWeeklyInsightsCompanion copyWith({
    Value<String>? userId,
    Value<String>? routineId,
    Value<String>? weekStart,
    Value<String>? payloadJson,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedWeeklyInsightsCompanion(
      userId: userId ?? this.userId,
      routineId: routineId ?? this.routineId,
      weekStart: weekStart ?? this.weekStart,
      payloadJson: payloadJson ?? this.payloadJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedWeeklyInsightsCompanion(')
          ..write('userId: $userId, ')
          ..write('routineId: $routineId, ')
          ..write('weekStart: $weekStart, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final $CachedRoutineDaysTable cachedRoutineDays =
      $CachedRoutineDaysTable(this);
  late final $CachedRoutineExercisesTable cachedRoutineExercises =
      $CachedRoutineExercisesTable(this);
  late final $CachedExercisesTable cachedExercises = $CachedExercisesTable(
    this,
  );
  late final $CachedLastPerformancesTable cachedLastPerformances =
      $CachedLastPerformancesTable(this);
  late final $CachedWorkoutSessionsTable cachedWorkoutSessions =
      $CachedWorkoutSessionsTable(this);
  late final $CachedSetLogsTable cachedSetLogs = $CachedSetLogsTable(this);
  late final $PendingMutationsTable pendingMutations = $PendingMutationsTable(
    this,
  );
  late final $CachedAssignedRoutinesTable cachedAssignedRoutines =
      $CachedAssignedRoutinesTable(this);
  late final $CachedWeeklyInsightsTable cachedWeeklyInsights =
      $CachedWeeklyInsightsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appMeta,
    cachedRoutineDays,
    cachedRoutineExercises,
    cachedExercises,
    cachedLastPerformances,
    cachedWorkoutSessions,
    cachedSetLogs,
    pendingMutations,
    cachedAssignedRoutines,
    cachedWeeklyInsights,
  ];
}

typedef $$AppMetaTableCreateCompanionBuilder =
    AppMetaCompanion Function({
      required String key,
      required String value,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AppMetaTableUpdateCompanionBuilder =
    AppMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$AppMetaTableFilterComposer
    extends Composer<_$LocalDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$LocalDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$LocalDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $AppMetaTable,
          AppMetaRow,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaRow,
            BaseReferences<_$LocalDatabase, $AppMetaTable, AppMetaRow>,
          ),
          AppMetaRow,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$LocalDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $AppMetaTable,
      AppMetaRow,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaRow, BaseReferences<_$LocalDatabase, $AppMetaTable, AppMetaRow>),
      AppMetaRow,
      PrefetchHooks Function()
    >;
typedef $$CachedRoutineDaysTableCreateCompanionBuilder =
    CachedRoutineDaysCompanion Function({
      required String id,
      required String routineId,
      required int dayOfWeek,
      required String name,
      Value<int> targetSetsCount,
      Value<String> status,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedRoutineDaysTableUpdateCompanionBuilder =
    CachedRoutineDaysCompanion Function({
      Value<String> id,
      Value<String> routineId,
      Value<int> dayOfWeek,
      Value<String> name,
      Value<int> targetSetsCount,
      Value<String> status,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$CachedRoutineDaysTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedRoutineDaysTable> {
  $$CachedRoutineDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSetsCount => $composableBuilder(
    column: $table.targetSetsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedRoutineDaysTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedRoutineDaysTable> {
  $$CachedRoutineDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSetsCount => $composableBuilder(
    column: $table.targetSetsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedRoutineDaysTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedRoutineDaysTable> {
  $$CachedRoutineDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get targetSetsCount => $composableBuilder(
    column: $table.targetSetsCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedRoutineDaysTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedRoutineDaysTable,
          CachedRoutineDayRow,
          $$CachedRoutineDaysTableFilterComposer,
          $$CachedRoutineDaysTableOrderingComposer,
          $$CachedRoutineDaysTableAnnotationComposer,
          $$CachedRoutineDaysTableCreateCompanionBuilder,
          $$CachedRoutineDaysTableUpdateCompanionBuilder,
          (
            CachedRoutineDayRow,
            BaseReferences<
              _$LocalDatabase,
              $CachedRoutineDaysTable,
              CachedRoutineDayRow
            >,
          ),
          CachedRoutineDayRow,
          PrefetchHooks Function()
        > {
  $$CachedRoutineDaysTableTableManager(
    _$LocalDatabase db,
    $CachedRoutineDaysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRoutineDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedRoutineDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedRoutineDaysTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> routineId = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> targetSetsCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedRoutineDaysCompanion(
                id: id,
                routineId: routineId,
                dayOfWeek: dayOfWeek,
                name: name,
                targetSetsCount: targetSetsCount,
                status: status,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String routineId,
                required int dayOfWeek,
                required String name,
                Value<int> targetSetsCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedRoutineDaysCompanion.insert(
                id: id,
                routineId: routineId,
                dayOfWeek: dayOfWeek,
                name: name,
                targetSetsCount: targetSetsCount,
                status: status,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedRoutineDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedRoutineDaysTable,
      CachedRoutineDayRow,
      $$CachedRoutineDaysTableFilterComposer,
      $$CachedRoutineDaysTableOrderingComposer,
      $$CachedRoutineDaysTableAnnotationComposer,
      $$CachedRoutineDaysTableCreateCompanionBuilder,
      $$CachedRoutineDaysTableUpdateCompanionBuilder,
      (
        CachedRoutineDayRow,
        BaseReferences<
          _$LocalDatabase,
          $CachedRoutineDaysTable,
          CachedRoutineDayRow
        >,
      ),
      CachedRoutineDayRow,
      PrefetchHooks Function()
    >;
typedef $$CachedRoutineExercisesTableCreateCompanionBuilder =
    CachedRoutineExercisesCompanion Function({
      required String routineDayId,
      required String exerciseId,
      required int position,
      required int targetSets,
      required int targetReps,
      required double targetWeight,
      Value<int> restTimerSeconds,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedRoutineExercisesTableUpdateCompanionBuilder =
    CachedRoutineExercisesCompanion Function({
      Value<String> routineDayId,
      Value<String> exerciseId,
      Value<int> position,
      Value<int> targetSets,
      Value<int> targetReps,
      Value<double> targetWeight,
      Value<int> restTimerSeconds,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$CachedRoutineExercisesTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedRoutineExercisesTable> {
  $$CachedRoutineExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get routineDayId => $composableBuilder(
    column: $table.routineDayId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restTimerSeconds => $composableBuilder(
    column: $table.restTimerSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedRoutineExercisesTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedRoutineExercisesTable> {
  $$CachedRoutineExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get routineDayId => $composableBuilder(
    column: $table.routineDayId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restTimerSeconds => $composableBuilder(
    column: $table.restTimerSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedRoutineExercisesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedRoutineExercisesTable> {
  $$CachedRoutineExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get routineDayId => $composableBuilder(
    column: $table.routineDayId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restTimerSeconds => $composableBuilder(
    column: $table.restTimerSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedRoutineExercisesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedRoutineExercisesTable,
          CachedRoutineExerciseRow,
          $$CachedRoutineExercisesTableFilterComposer,
          $$CachedRoutineExercisesTableOrderingComposer,
          $$CachedRoutineExercisesTableAnnotationComposer,
          $$CachedRoutineExercisesTableCreateCompanionBuilder,
          $$CachedRoutineExercisesTableUpdateCompanionBuilder,
          (
            CachedRoutineExerciseRow,
            BaseReferences<
              _$LocalDatabase,
              $CachedRoutineExercisesTable,
              CachedRoutineExerciseRow
            >,
          ),
          CachedRoutineExerciseRow,
          PrefetchHooks Function()
        > {
  $$CachedRoutineExercisesTableTableManager(
    _$LocalDatabase db,
    $CachedRoutineExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRoutineExercisesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedRoutineExercisesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedRoutineExercisesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> routineDayId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> targetSets = const Value.absent(),
                Value<int> targetReps = const Value.absent(),
                Value<double> targetWeight = const Value.absent(),
                Value<int> restTimerSeconds = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedRoutineExercisesCompanion(
                routineDayId: routineDayId,
                exerciseId: exerciseId,
                position: position,
                targetSets: targetSets,
                targetReps: targetReps,
                targetWeight: targetWeight,
                restTimerSeconds: restTimerSeconds,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String routineDayId,
                required String exerciseId,
                required int position,
                required int targetSets,
                required int targetReps,
                required double targetWeight,
                Value<int> restTimerSeconds = const Value.absent(),
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedRoutineExercisesCompanion.insert(
                routineDayId: routineDayId,
                exerciseId: exerciseId,
                position: position,
                targetSets: targetSets,
                targetReps: targetReps,
                targetWeight: targetWeight,
                restTimerSeconds: restTimerSeconds,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedRoutineExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedRoutineExercisesTable,
      CachedRoutineExerciseRow,
      $$CachedRoutineExercisesTableFilterComposer,
      $$CachedRoutineExercisesTableOrderingComposer,
      $$CachedRoutineExercisesTableAnnotationComposer,
      $$CachedRoutineExercisesTableCreateCompanionBuilder,
      $$CachedRoutineExercisesTableUpdateCompanionBuilder,
      (
        CachedRoutineExerciseRow,
        BaseReferences<
          _$LocalDatabase,
          $CachedRoutineExercisesTable,
          CachedRoutineExerciseRow
        >,
      ),
      CachedRoutineExerciseRow,
      PrefetchHooks Function()
    >;
typedef $$CachedExercisesTableCreateCompanionBuilder =
    CachedExercisesCompanion Function({
      required String id,
      required String name,
      Value<String> muscleGroup,
      Value<String?> imageUrl,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedExercisesTableUpdateCompanionBuilder =
    CachedExercisesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> muscleGroup,
      Value<String?> imageUrl,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$CachedExercisesTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedExercisesTable> {
  $$CachedExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedExercisesTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedExercisesTable> {
  $$CachedExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedExercisesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedExercisesTable> {
  $$CachedExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedExercisesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedExercisesTable,
          CachedExerciseRow,
          $$CachedExercisesTableFilterComposer,
          $$CachedExercisesTableOrderingComposer,
          $$CachedExercisesTableAnnotationComposer,
          $$CachedExercisesTableCreateCompanionBuilder,
          $$CachedExercisesTableUpdateCompanionBuilder,
          (
            CachedExerciseRow,
            BaseReferences<
              _$LocalDatabase,
              $CachedExercisesTable,
              CachedExerciseRow
            >,
          ),
          CachedExerciseRow,
          PrefetchHooks Function()
        > {
  $$CachedExercisesTableTableManager(
    _$LocalDatabase db,
    $CachedExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> muscleGroup = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedExercisesCompanion(
                id: id,
                name: name,
                muscleGroup: muscleGroup,
                imageUrl: imageUrl,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> muscleGroup = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedExercisesCompanion.insert(
                id: id,
                name: name,
                muscleGroup: muscleGroup,
                imageUrl: imageUrl,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedExercisesTable,
      CachedExerciseRow,
      $$CachedExercisesTableFilterComposer,
      $$CachedExercisesTableOrderingComposer,
      $$CachedExercisesTableAnnotationComposer,
      $$CachedExercisesTableCreateCompanionBuilder,
      $$CachedExercisesTableUpdateCompanionBuilder,
      (
        CachedExerciseRow,
        BaseReferences<
          _$LocalDatabase,
          $CachedExercisesTable,
          CachedExerciseRow
        >,
      ),
      CachedExerciseRow,
      PrefetchHooks Function()
    >;
typedef $$CachedLastPerformancesTableCreateCompanionBuilder =
    CachedLastPerformancesCompanion Function({
      required String userId,
      required String exerciseId,
      Value<String?> setLogId,
      required String sessionId,
      required double actualWeight,
      required int actualReps,
      required int setIndex,
      Value<int?> performedAt,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedLastPerformancesTableUpdateCompanionBuilder =
    CachedLastPerformancesCompanion Function({
      Value<String> userId,
      Value<String> exerciseId,
      Value<String?> setLogId,
      Value<String> sessionId,
      Value<double> actualWeight,
      Value<int> actualReps,
      Value<int> setIndex,
      Value<int?> performedAt,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$CachedLastPerformancesTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedLastPerformancesTable> {
  $$CachedLastPerformancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setLogId => $composableBuilder(
    column: $table.setLogId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get actualWeight => $composableBuilder(
    column: $table.actualWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedLastPerformancesTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedLastPerformancesTable> {
  $$CachedLastPerformancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setLogId => $composableBuilder(
    column: $table.setLogId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get actualWeight => $composableBuilder(
    column: $table.actualWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedLastPerformancesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedLastPerformancesTable> {
  $$CachedLastPerformancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get setLogId =>
      $composableBuilder(column: $table.setLogId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<double> get actualWeight => $composableBuilder(
    column: $table.actualWeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<int> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedLastPerformancesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedLastPerformancesTable,
          CachedLastPerformanceRow,
          $$CachedLastPerformancesTableFilterComposer,
          $$CachedLastPerformancesTableOrderingComposer,
          $$CachedLastPerformancesTableAnnotationComposer,
          $$CachedLastPerformancesTableCreateCompanionBuilder,
          $$CachedLastPerformancesTableUpdateCompanionBuilder,
          (
            CachedLastPerformanceRow,
            BaseReferences<
              _$LocalDatabase,
              $CachedLastPerformancesTable,
              CachedLastPerformanceRow
            >,
          ),
          CachedLastPerformanceRow,
          PrefetchHooks Function()
        > {
  $$CachedLastPerformancesTableTableManager(
    _$LocalDatabase db,
    $CachedLastPerformancesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedLastPerformancesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedLastPerformancesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedLastPerformancesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<String?> setLogId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<double> actualWeight = const Value.absent(),
                Value<int> actualReps = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<int?> performedAt = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedLastPerformancesCompanion(
                userId: userId,
                exerciseId: exerciseId,
                setLogId: setLogId,
                sessionId: sessionId,
                actualWeight: actualWeight,
                actualReps: actualReps,
                setIndex: setIndex,
                performedAt: performedAt,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String exerciseId,
                Value<String?> setLogId = const Value.absent(),
                required String sessionId,
                required double actualWeight,
                required int actualReps,
                required int setIndex,
                Value<int?> performedAt = const Value.absent(),
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedLastPerformancesCompanion.insert(
                userId: userId,
                exerciseId: exerciseId,
                setLogId: setLogId,
                sessionId: sessionId,
                actualWeight: actualWeight,
                actualReps: actualReps,
                setIndex: setIndex,
                performedAt: performedAt,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedLastPerformancesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedLastPerformancesTable,
      CachedLastPerformanceRow,
      $$CachedLastPerformancesTableFilterComposer,
      $$CachedLastPerformancesTableOrderingComposer,
      $$CachedLastPerformancesTableAnnotationComposer,
      $$CachedLastPerformancesTableCreateCompanionBuilder,
      $$CachedLastPerformancesTableUpdateCompanionBuilder,
      (
        CachedLastPerformanceRow,
        BaseReferences<
          _$LocalDatabase,
          $CachedLastPerformancesTable,
          CachedLastPerformanceRow
        >,
      ),
      CachedLastPerformanceRow,
      PrefetchHooks Function()
    >;
typedef $$CachedWorkoutSessionsTableCreateCompanionBuilder =
    CachedWorkoutSessionsCompanion Function({
      required String id,
      required String userId,
      required String routineDayId,
      required String sessionDate,
      required int startedAt,
      Value<int?> completedAt,
      Value<int> totalTargetSets,
      Value<int> completedSetsCount,
      Value<String?> coachingAnalysisJson,
      Value<String> syncStatus,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedWorkoutSessionsTableUpdateCompanionBuilder =
    CachedWorkoutSessionsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> routineDayId,
      Value<String> sessionDate,
      Value<int> startedAt,
      Value<int?> completedAt,
      Value<int> totalTargetSets,
      Value<int> completedSetsCount,
      Value<String?> coachingAnalysisJson,
      Value<String> syncStatus,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$CachedWorkoutSessionsTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedWorkoutSessionsTable> {
  $$CachedWorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routineDayId => $composableBuilder(
    column: $table.routineDayId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionDate => $composableBuilder(
    column: $table.sessionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTargetSets => $composableBuilder(
    column: $table.totalTargetSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedSetsCount => $composableBuilder(
    column: $table.completedSetsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coachingAnalysisJson => $composableBuilder(
    column: $table.coachingAnalysisJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedWorkoutSessionsTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedWorkoutSessionsTable> {
  $$CachedWorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routineDayId => $composableBuilder(
    column: $table.routineDayId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionDate => $composableBuilder(
    column: $table.sessionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTargetSets => $composableBuilder(
    column: $table.totalTargetSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedSetsCount => $composableBuilder(
    column: $table.completedSetsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coachingAnalysisJson => $composableBuilder(
    column: $table.coachingAnalysisJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedWorkoutSessionsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedWorkoutSessionsTable> {
  $$CachedWorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get routineDayId => $composableBuilder(
    column: $table.routineDayId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionDate => $composableBuilder(
    column: $table.sessionDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalTargetSets => $composableBuilder(
    column: $table.totalTargetSets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedSetsCount => $composableBuilder(
    column: $table.completedSetsCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coachingAnalysisJson => $composableBuilder(
    column: $table.coachingAnalysisJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedWorkoutSessionsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedWorkoutSessionsTable,
          CachedWorkoutSessionRow,
          $$CachedWorkoutSessionsTableFilterComposer,
          $$CachedWorkoutSessionsTableOrderingComposer,
          $$CachedWorkoutSessionsTableAnnotationComposer,
          $$CachedWorkoutSessionsTableCreateCompanionBuilder,
          $$CachedWorkoutSessionsTableUpdateCompanionBuilder,
          (
            CachedWorkoutSessionRow,
            BaseReferences<
              _$LocalDatabase,
              $CachedWorkoutSessionsTable,
              CachedWorkoutSessionRow
            >,
          ),
          CachedWorkoutSessionRow,
          PrefetchHooks Function()
        > {
  $$CachedWorkoutSessionsTableTableManager(
    _$LocalDatabase db,
    $CachedWorkoutSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedWorkoutSessionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedWorkoutSessionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedWorkoutSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> routineDayId = const Value.absent(),
                Value<String> sessionDate = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> totalTargetSets = const Value.absent(),
                Value<int> completedSetsCount = const Value.absent(),
                Value<String?> coachingAnalysisJson = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedWorkoutSessionsCompanion(
                id: id,
                userId: userId,
                routineDayId: routineDayId,
                sessionDate: sessionDate,
                startedAt: startedAt,
                completedAt: completedAt,
                totalTargetSets: totalTargetSets,
                completedSetsCount: completedSetsCount,
                coachingAnalysisJson: coachingAnalysisJson,
                syncStatus: syncStatus,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String routineDayId,
                required String sessionDate,
                required int startedAt,
                Value<int?> completedAt = const Value.absent(),
                Value<int> totalTargetSets = const Value.absent(),
                Value<int> completedSetsCount = const Value.absent(),
                Value<String?> coachingAnalysisJson = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedWorkoutSessionsCompanion.insert(
                id: id,
                userId: userId,
                routineDayId: routineDayId,
                sessionDate: sessionDate,
                startedAt: startedAt,
                completedAt: completedAt,
                totalTargetSets: totalTargetSets,
                completedSetsCount: completedSetsCount,
                coachingAnalysisJson: coachingAnalysisJson,
                syncStatus: syncStatus,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedWorkoutSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedWorkoutSessionsTable,
      CachedWorkoutSessionRow,
      $$CachedWorkoutSessionsTableFilterComposer,
      $$CachedWorkoutSessionsTableOrderingComposer,
      $$CachedWorkoutSessionsTableAnnotationComposer,
      $$CachedWorkoutSessionsTableCreateCompanionBuilder,
      $$CachedWorkoutSessionsTableUpdateCompanionBuilder,
      (
        CachedWorkoutSessionRow,
        BaseReferences<
          _$LocalDatabase,
          $CachedWorkoutSessionsTable,
          CachedWorkoutSessionRow
        >,
      ),
      CachedWorkoutSessionRow,
      PrefetchHooks Function()
    >;
typedef $$CachedSetLogsTableCreateCompanionBuilder =
    CachedSetLogsCompanion Function({
      required String sessionId,
      required String exerciseId,
      required int setIndex,
      required double actualWeight,
      required int actualReps,
      required int createdAt,
      Value<String?> remoteId,
      Value<String> syncStatus,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedSetLogsTableUpdateCompanionBuilder =
    CachedSetLogsCompanion Function({
      Value<String> sessionId,
      Value<String> exerciseId,
      Value<int> setIndex,
      Value<double> actualWeight,
      Value<int> actualReps,
      Value<int> createdAt,
      Value<String?> remoteId,
      Value<String> syncStatus,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$CachedSetLogsTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedSetLogsTable> {
  $$CachedSetLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get actualWeight => $composableBuilder(
    column: $table.actualWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSetLogsTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedSetLogsTable> {
  $$CachedSetLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get actualWeight => $composableBuilder(
    column: $table.actualWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSetLogsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedSetLogsTable> {
  $$CachedSetLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<double> get actualWeight => $composableBuilder(
    column: $table.actualWeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedSetLogsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedSetLogsTable,
          CachedSetLogRow,
          $$CachedSetLogsTableFilterComposer,
          $$CachedSetLogsTableOrderingComposer,
          $$CachedSetLogsTableAnnotationComposer,
          $$CachedSetLogsTableCreateCompanionBuilder,
          $$CachedSetLogsTableUpdateCompanionBuilder,
          (
            CachedSetLogRow,
            BaseReferences<
              _$LocalDatabase,
              $CachedSetLogsTable,
              CachedSetLogRow
            >,
          ),
          CachedSetLogRow,
          PrefetchHooks Function()
        > {
  $$CachedSetLogsTableTableManager(
    _$LocalDatabase db,
    $CachedSetLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSetLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSetLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSetLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<double> actualWeight = const Value.absent(),
                Value<int> actualReps = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSetLogsCompanion(
                sessionId: sessionId,
                exerciseId: exerciseId,
                setIndex: setIndex,
                actualWeight: actualWeight,
                actualReps: actualReps,
                createdAt: createdAt,
                remoteId: remoteId,
                syncStatus: syncStatus,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String exerciseId,
                required int setIndex,
                required double actualWeight,
                required int actualReps,
                required int createdAt,
                Value<String?> remoteId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedSetLogsCompanion.insert(
                sessionId: sessionId,
                exerciseId: exerciseId,
                setIndex: setIndex,
                actualWeight: actualWeight,
                actualReps: actualReps,
                createdAt: createdAt,
                remoteId: remoteId,
                syncStatus: syncStatus,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSetLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedSetLogsTable,
      CachedSetLogRow,
      $$CachedSetLogsTableFilterComposer,
      $$CachedSetLogsTableOrderingComposer,
      $$CachedSetLogsTableAnnotationComposer,
      $$CachedSetLogsTableCreateCompanionBuilder,
      $$CachedSetLogsTableUpdateCompanionBuilder,
      (
        CachedSetLogRow,
        BaseReferences<_$LocalDatabase, $CachedSetLogsTable, CachedSetLogRow>,
      ),
      CachedSetLogRow,
      PrefetchHooks Function()
    >;
typedef $$PendingMutationsTableCreateCompanionBuilder =
    PendingMutationsCompanion Function({
      Value<int> id,
      required String kind,
      required String payloadJson,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int?> lastAttemptAt,
      required int createdAt,
      Value<int?> nextAttemptAt,
      Value<String?> lockToken,
    });
typedef $$PendingMutationsTableUpdateCompanionBuilder =
    PendingMutationsCompanion Function({
      Value<int> id,
      Value<String> kind,
      Value<String> payloadJson,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int?> lastAttemptAt,
      Value<int> createdAt,
      Value<int?> nextAttemptAt,
      Value<String?> lockToken,
    });

class $$PendingMutationsTableFilterComposer
    extends Composer<_$LocalDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lockToken => $composableBuilder(
    column: $table.lockToken,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingMutationsTableOrderingComposer
    extends Composer<_$LocalDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lockToken => $composableBuilder(
    column: $table.lockToken,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingMutationsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lockToken =>
      $composableBuilder(column: $table.lockToken, builder: (column) => column);
}

class $$PendingMutationsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $PendingMutationsTable,
          PendingMutationRow,
          $$PendingMutationsTableFilterComposer,
          $$PendingMutationsTableOrderingComposer,
          $$PendingMutationsTableAnnotationComposer,
          $$PendingMutationsTableCreateCompanionBuilder,
          $$PendingMutationsTableUpdateCompanionBuilder,
          (
            PendingMutationRow,
            BaseReferences<
              _$LocalDatabase,
              $PendingMutationsTable,
              PendingMutationRow
            >,
          ),
          PendingMutationRow,
          PrefetchHooks Function()
        > {
  $$PendingMutationsTableTableManager(
    _$LocalDatabase db,
    $PendingMutationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingMutationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingMutationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingMutationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int?> lastAttemptAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> nextAttemptAt = const Value.absent(),
                Value<String?> lockToken = const Value.absent(),
              }) => PendingMutationsCompanion(
                id: id,
                kind: kind,
                payloadJson: payloadJson,
                attempts: attempts,
                lastError: lastError,
                lastAttemptAt: lastAttemptAt,
                createdAt: createdAt,
                nextAttemptAt: nextAttemptAt,
                lockToken: lockToken,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String payloadJson,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int?> lastAttemptAt = const Value.absent(),
                required int createdAt,
                Value<int?> nextAttemptAt = const Value.absent(),
                Value<String?> lockToken = const Value.absent(),
              }) => PendingMutationsCompanion.insert(
                id: id,
                kind: kind,
                payloadJson: payloadJson,
                attempts: attempts,
                lastError: lastError,
                lastAttemptAt: lastAttemptAt,
                createdAt: createdAt,
                nextAttemptAt: nextAttemptAt,
                lockToken: lockToken,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingMutationsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $PendingMutationsTable,
      PendingMutationRow,
      $$PendingMutationsTableFilterComposer,
      $$PendingMutationsTableOrderingComposer,
      $$PendingMutationsTableAnnotationComposer,
      $$PendingMutationsTableCreateCompanionBuilder,
      $$PendingMutationsTableUpdateCompanionBuilder,
      (
        PendingMutationRow,
        BaseReferences<
          _$LocalDatabase,
          $PendingMutationsTable,
          PendingMutationRow
        >,
      ),
      PendingMutationRow,
      PrefetchHooks Function()
    >;
typedef $$CachedAssignedRoutinesTableCreateCompanionBuilder =
    CachedAssignedRoutinesCompanion Function({
      required String userId,
      required String routineId,
      required String routineName,
      Value<bool> isPublic,
      Value<String?> creatorId,
      Value<String?> creatorName,
      Value<int> exerciseCount,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedAssignedRoutinesTableUpdateCompanionBuilder =
    CachedAssignedRoutinesCompanion Function({
      Value<String> userId,
      Value<String> routineId,
      Value<String> routineName,
      Value<bool> isPublic,
      Value<String?> creatorId,
      Value<String?> creatorName,
      Value<int> exerciseCount,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$CachedAssignedRoutinesTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedAssignedRoutinesTable> {
  $$CachedAssignedRoutinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routineName => $composableBuilder(
    column: $table.routineName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorName => $composableBuilder(
    column: $table.creatorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseCount => $composableBuilder(
    column: $table.exerciseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedAssignedRoutinesTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedAssignedRoutinesTable> {
  $$CachedAssignedRoutinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routineName => $composableBuilder(
    column: $table.routineName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorName => $composableBuilder(
    column: $table.creatorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseCount => $composableBuilder(
    column: $table.exerciseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAssignedRoutinesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedAssignedRoutinesTable> {
  $$CachedAssignedRoutinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<String> get routineName => $composableBuilder(
    column: $table.routineName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPublic =>
      $composableBuilder(column: $table.isPublic, builder: (column) => column);

  GeneratedColumn<String> get creatorId =>
      $composableBuilder(column: $table.creatorId, builder: (column) => column);

  GeneratedColumn<String> get creatorName => $composableBuilder(
    column: $table.creatorName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exerciseCount => $composableBuilder(
    column: $table.exerciseCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedAssignedRoutinesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedAssignedRoutinesTable,
          CachedAssignedRoutineRow,
          $$CachedAssignedRoutinesTableFilterComposer,
          $$CachedAssignedRoutinesTableOrderingComposer,
          $$CachedAssignedRoutinesTableAnnotationComposer,
          $$CachedAssignedRoutinesTableCreateCompanionBuilder,
          $$CachedAssignedRoutinesTableUpdateCompanionBuilder,
          (
            CachedAssignedRoutineRow,
            BaseReferences<
              _$LocalDatabase,
              $CachedAssignedRoutinesTable,
              CachedAssignedRoutineRow
            >,
          ),
          CachedAssignedRoutineRow,
          PrefetchHooks Function()
        > {
  $$CachedAssignedRoutinesTableTableManager(
    _$LocalDatabase db,
    $CachedAssignedRoutinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAssignedRoutinesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedAssignedRoutinesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedAssignedRoutinesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> routineId = const Value.absent(),
                Value<String> routineName = const Value.absent(),
                Value<bool> isPublic = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<String?> creatorName = const Value.absent(),
                Value<int> exerciseCount = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAssignedRoutinesCompanion(
                userId: userId,
                routineId: routineId,
                routineName: routineName,
                isPublic: isPublic,
                creatorId: creatorId,
                creatorName: creatorName,
                exerciseCount: exerciseCount,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String routineId,
                required String routineName,
                Value<bool> isPublic = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<String?> creatorName = const Value.absent(),
                Value<int> exerciseCount = const Value.absent(),
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedAssignedRoutinesCompanion.insert(
                userId: userId,
                routineId: routineId,
                routineName: routineName,
                isPublic: isPublic,
                creatorId: creatorId,
                creatorName: creatorName,
                exerciseCount: exerciseCount,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedAssignedRoutinesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedAssignedRoutinesTable,
      CachedAssignedRoutineRow,
      $$CachedAssignedRoutinesTableFilterComposer,
      $$CachedAssignedRoutinesTableOrderingComposer,
      $$CachedAssignedRoutinesTableAnnotationComposer,
      $$CachedAssignedRoutinesTableCreateCompanionBuilder,
      $$CachedAssignedRoutinesTableUpdateCompanionBuilder,
      (
        CachedAssignedRoutineRow,
        BaseReferences<
          _$LocalDatabase,
          $CachedAssignedRoutinesTable,
          CachedAssignedRoutineRow
        >,
      ),
      CachedAssignedRoutineRow,
      PrefetchHooks Function()
    >;
typedef $$CachedWeeklyInsightsTableCreateCompanionBuilder =
    CachedWeeklyInsightsCompanion Function({
      required String userId,
      required String routineId,
      required String weekStart,
      required String payloadJson,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedWeeklyInsightsTableUpdateCompanionBuilder =
    CachedWeeklyInsightsCompanion Function({
      Value<String> userId,
      Value<String> routineId,
      Value<String> weekStart,
      Value<String> payloadJson,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$CachedWeeklyInsightsTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedWeeklyInsightsTable> {
  $$CachedWeeklyInsightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedWeeklyInsightsTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedWeeklyInsightsTable> {
  $$CachedWeeklyInsightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedWeeklyInsightsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedWeeklyInsightsTable> {
  $$CachedWeeklyInsightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedWeeklyInsightsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedWeeklyInsightsTable,
          CachedWeeklyInsightRow,
          $$CachedWeeklyInsightsTableFilterComposer,
          $$CachedWeeklyInsightsTableOrderingComposer,
          $$CachedWeeklyInsightsTableAnnotationComposer,
          $$CachedWeeklyInsightsTableCreateCompanionBuilder,
          $$CachedWeeklyInsightsTableUpdateCompanionBuilder,
          (
            CachedWeeklyInsightRow,
            BaseReferences<
              _$LocalDatabase,
              $CachedWeeklyInsightsTable,
              CachedWeeklyInsightRow
            >,
          ),
          CachedWeeklyInsightRow,
          PrefetchHooks Function()
        > {
  $$CachedWeeklyInsightsTableTableManager(
    _$LocalDatabase db,
    $CachedWeeklyInsightsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedWeeklyInsightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedWeeklyInsightsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedWeeklyInsightsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> routineId = const Value.absent(),
                Value<String> weekStart = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedWeeklyInsightsCompanion(
                userId: userId,
                routineId: routineId,
                weekStart: weekStart,
                payloadJson: payloadJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String routineId,
                required String weekStart,
                required String payloadJson,
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedWeeklyInsightsCompanion.insert(
                userId: userId,
                routineId: routineId,
                weekStart: weekStart,
                payloadJson: payloadJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedWeeklyInsightsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedWeeklyInsightsTable,
      CachedWeeklyInsightRow,
      $$CachedWeeklyInsightsTableFilterComposer,
      $$CachedWeeklyInsightsTableOrderingComposer,
      $$CachedWeeklyInsightsTableAnnotationComposer,
      $$CachedWeeklyInsightsTableCreateCompanionBuilder,
      $$CachedWeeklyInsightsTableUpdateCompanionBuilder,
      (
        CachedWeeklyInsightRow,
        BaseReferences<
          _$LocalDatabase,
          $CachedWeeklyInsightsTable,
          CachedWeeklyInsightRow
        >,
      ),
      CachedWeeklyInsightRow,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
  $$CachedRoutineDaysTableTableManager get cachedRoutineDays =>
      $$CachedRoutineDaysTableTableManager(_db, _db.cachedRoutineDays);
  $$CachedRoutineExercisesTableTableManager get cachedRoutineExercises =>
      $$CachedRoutineExercisesTableTableManager(
        _db,
        _db.cachedRoutineExercises,
      );
  $$CachedExercisesTableTableManager get cachedExercises =>
      $$CachedExercisesTableTableManager(_db, _db.cachedExercises);
  $$CachedLastPerformancesTableTableManager get cachedLastPerformances =>
      $$CachedLastPerformancesTableTableManager(
        _db,
        _db.cachedLastPerformances,
      );
  $$CachedWorkoutSessionsTableTableManager get cachedWorkoutSessions =>
      $$CachedWorkoutSessionsTableTableManager(_db, _db.cachedWorkoutSessions);
  $$CachedSetLogsTableTableManager get cachedSetLogs =>
      $$CachedSetLogsTableTableManager(_db, _db.cachedSetLogs);
  $$PendingMutationsTableTableManager get pendingMutations =>
      $$PendingMutationsTableTableManager(_db, _db.pendingMutations);
  $$CachedAssignedRoutinesTableTableManager get cachedAssignedRoutines =>
      $$CachedAssignedRoutinesTableTableManager(
        _db,
        _db.cachedAssignedRoutines,
      );
  $$CachedWeeklyInsightsTableTableManager get cachedWeeklyInsights =>
      $$CachedWeeklyInsightsTableTableManager(_db, _db.cachedWeeklyInsights);
}
