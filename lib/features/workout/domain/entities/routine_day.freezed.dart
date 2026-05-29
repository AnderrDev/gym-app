// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'routine_day.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoutineDay {

 String get id; String get routineId; int get dayOfWeek;// 1=Lunes, 7=Domingo
 String get name;// "Pecho y Tríceps"
 List<Exercise> get exercises; int get targetSetsCount; WorkoutDayStatus get status;/// Nombres de los ejercicios del día, en orden, sin metadata adicional.
/// Lo popula `getRoutineDays` para que `RoutineDayCard` pueda pintar un
/// preview ("Press banca · Press militar · …") sin tener que cargar el
/// día completo. Vacío cuando el day se construyó desde un contexto que
/// no necesita preview.
 List<String> get exerciseNamesPreview;
/// Create a copy of RoutineDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutineDayCopyWith<RoutineDay> get copyWith => _$RoutineDayCopyWithImpl<RoutineDay>(this as RoutineDay, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutineDay&&(identical(other.id, id) || other.id == id)&&(identical(other.routineId, routineId) || other.routineId == routineId)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.exercises, exercises)&&(identical(other.targetSetsCount, targetSetsCount) || other.targetSetsCount == targetSetsCount)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.exerciseNamesPreview, exerciseNamesPreview));
}


@override
int get hashCode => Object.hash(runtimeType,id,routineId,dayOfWeek,name,const DeepCollectionEquality().hash(exercises),targetSetsCount,status,const DeepCollectionEquality().hash(exerciseNamesPreview));

@override
String toString() {
  return 'RoutineDay(id: $id, routineId: $routineId, dayOfWeek: $dayOfWeek, name: $name, exercises: $exercises, targetSetsCount: $targetSetsCount, status: $status, exerciseNamesPreview: $exerciseNamesPreview)';
}


}

/// @nodoc
abstract mixin class $RoutineDayCopyWith<$Res>  {
  factory $RoutineDayCopyWith(RoutineDay value, $Res Function(RoutineDay) _then) = _$RoutineDayCopyWithImpl;
@useResult
$Res call({
 String id, String routineId, int dayOfWeek, String name, List<Exercise> exercises, int targetSetsCount, WorkoutDayStatus status, List<String> exerciseNamesPreview
});




}
/// @nodoc
class _$RoutineDayCopyWithImpl<$Res>
    implements $RoutineDayCopyWith<$Res> {
  _$RoutineDayCopyWithImpl(this._self, this._then);

  final RoutineDay _self;
  final $Res Function(RoutineDay) _then;

/// Create a copy of RoutineDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? routineId = null,Object? dayOfWeek = null,Object? name = null,Object? exercises = null,Object? targetSetsCount = null,Object? status = null,Object? exerciseNamesPreview = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routineId: null == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<Exercise>,targetSetsCount: null == targetSetsCount ? _self.targetSetsCount : targetSetsCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkoutDayStatus,exerciseNamesPreview: null == exerciseNamesPreview ? _self.exerciseNamesPreview : exerciseNamesPreview // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [RoutineDay].
extension RoutineDayPatterns on RoutineDay {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoutineDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoutineDay() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoutineDay value)  $default,){
final _that = this;
switch (_that) {
case _RoutineDay():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoutineDay value)?  $default,){
final _that = this;
switch (_that) {
case _RoutineDay() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String routineId,  int dayOfWeek,  String name,  List<Exercise> exercises,  int targetSetsCount,  WorkoutDayStatus status,  List<String> exerciseNamesPreview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoutineDay() when $default != null:
return $default(_that.id,_that.routineId,_that.dayOfWeek,_that.name,_that.exercises,_that.targetSetsCount,_that.status,_that.exerciseNamesPreview);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String routineId,  int dayOfWeek,  String name,  List<Exercise> exercises,  int targetSetsCount,  WorkoutDayStatus status,  List<String> exerciseNamesPreview)  $default,) {final _that = this;
switch (_that) {
case _RoutineDay():
return $default(_that.id,_that.routineId,_that.dayOfWeek,_that.name,_that.exercises,_that.targetSetsCount,_that.status,_that.exerciseNamesPreview);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String routineId,  int dayOfWeek,  String name,  List<Exercise> exercises,  int targetSetsCount,  WorkoutDayStatus status,  List<String> exerciseNamesPreview)?  $default,) {final _that = this;
switch (_that) {
case _RoutineDay() when $default != null:
return $default(_that.id,_that.routineId,_that.dayOfWeek,_that.name,_that.exercises,_that.targetSetsCount,_that.status,_that.exerciseNamesPreview);case _:
  return null;

}
}

}

/// @nodoc


class _RoutineDay extends RoutineDay {
  const _RoutineDay({required this.id, required this.routineId, required this.dayOfWeek, required this.name, final  List<Exercise> exercises = const [], this.targetSetsCount = 0, this.status = WorkoutDayStatus.pending, final  List<String> exerciseNamesPreview = const []}): _exercises = exercises,_exerciseNamesPreview = exerciseNamesPreview,super._();
  

@override final  String id;
@override final  String routineId;
@override final  int dayOfWeek;
// 1=Lunes, 7=Domingo
@override final  String name;
// "Pecho y Tríceps"
 final  List<Exercise> _exercises;
// "Pecho y Tríceps"
@override@JsonKey() List<Exercise> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}

@override@JsonKey() final  int targetSetsCount;
@override@JsonKey() final  WorkoutDayStatus status;
/// Nombres de los ejercicios del día, en orden, sin metadata adicional.
/// Lo popula `getRoutineDays` para que `RoutineDayCard` pueda pintar un
/// preview ("Press banca · Press militar · …") sin tener que cargar el
/// día completo. Vacío cuando el day se construyó desde un contexto que
/// no necesita preview.
 final  List<String> _exerciseNamesPreview;
/// Nombres de los ejercicios del día, en orden, sin metadata adicional.
/// Lo popula `getRoutineDays` para que `RoutineDayCard` pueda pintar un
/// preview ("Press banca · Press militar · …") sin tener que cargar el
/// día completo. Vacío cuando el day se construyó desde un contexto que
/// no necesita preview.
@override@JsonKey() List<String> get exerciseNamesPreview {
  if (_exerciseNamesPreview is EqualUnmodifiableListView) return _exerciseNamesPreview;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exerciseNamesPreview);
}


/// Create a copy of RoutineDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoutineDayCopyWith<_RoutineDay> get copyWith => __$RoutineDayCopyWithImpl<_RoutineDay>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoutineDay&&(identical(other.id, id) || other.id == id)&&(identical(other.routineId, routineId) || other.routineId == routineId)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._exercises, _exercises)&&(identical(other.targetSetsCount, targetSetsCount) || other.targetSetsCount == targetSetsCount)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._exerciseNamesPreview, _exerciseNamesPreview));
}


@override
int get hashCode => Object.hash(runtimeType,id,routineId,dayOfWeek,name,const DeepCollectionEquality().hash(_exercises),targetSetsCount,status,const DeepCollectionEquality().hash(_exerciseNamesPreview));

@override
String toString() {
  return 'RoutineDay(id: $id, routineId: $routineId, dayOfWeek: $dayOfWeek, name: $name, exercises: $exercises, targetSetsCount: $targetSetsCount, status: $status, exerciseNamesPreview: $exerciseNamesPreview)';
}


}

/// @nodoc
abstract mixin class _$RoutineDayCopyWith<$Res> implements $RoutineDayCopyWith<$Res> {
  factory _$RoutineDayCopyWith(_RoutineDay value, $Res Function(_RoutineDay) _then) = __$RoutineDayCopyWithImpl;
@override @useResult
$Res call({
 String id, String routineId, int dayOfWeek, String name, List<Exercise> exercises, int targetSetsCount, WorkoutDayStatus status, List<String> exerciseNamesPreview
});




}
/// @nodoc
class __$RoutineDayCopyWithImpl<$Res>
    implements _$RoutineDayCopyWith<$Res> {
  __$RoutineDayCopyWithImpl(this._self, this._then);

  final _RoutineDay _self;
  final $Res Function(_RoutineDay) _then;

/// Create a copy of RoutineDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? routineId = null,Object? dayOfWeek = null,Object? name = null,Object? exercises = null,Object? targetSetsCount = null,Object? status = null,Object? exerciseNamesPreview = null,}) {
  return _then(_RoutineDay(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routineId: null == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<Exercise>,targetSetsCount: null == targetSetsCount ? _self.targetSetsCount : targetSetsCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkoutDayStatus,exerciseNamesPreview: null == exerciseNamesPreview ? _self._exerciseNamesPreview : exerciseNamesPreview // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
