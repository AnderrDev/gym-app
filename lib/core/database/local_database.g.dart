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
}
