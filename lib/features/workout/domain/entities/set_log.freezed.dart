// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'set_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SetLog {

// Nullable porque lo creamos antes de mandarlo a la DB.
 String? get id; String get sessionId; String get exerciseId; double get actualWeight; int get actualReps; int get setIndex; DateTime? get createdAt;
/// Create a copy of SetLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetLogCopyWith<SetLog> get copyWith => _$SetLogCopyWithImpl<SetLog>(this as SetLog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetLog&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.actualWeight, actualWeight) || other.actualWeight == actualWeight)&&(identical(other.actualReps, actualReps) || other.actualReps == actualReps)&&(identical(other.setIndex, setIndex) || other.setIndex == setIndex)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,sessionId,exerciseId,actualWeight,actualReps,setIndex,createdAt);

@override
String toString() {
  return 'SetLog(id: $id, sessionId: $sessionId, exerciseId: $exerciseId, actualWeight: $actualWeight, actualReps: $actualReps, setIndex: $setIndex, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SetLogCopyWith<$Res>  {
  factory $SetLogCopyWith(SetLog value, $Res Function(SetLog) _then) = _$SetLogCopyWithImpl;
@useResult
$Res call({
 String? id, String sessionId, String exerciseId, double actualWeight, int actualReps, int setIndex, DateTime? createdAt
});




}
/// @nodoc
class _$SetLogCopyWithImpl<$Res>
    implements $SetLogCopyWith<$Res> {
  _$SetLogCopyWithImpl(this._self, this._then);

  final SetLog _self;
  final $Res Function(SetLog) _then;

/// Create a copy of SetLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? sessionId = null,Object? exerciseId = null,Object? actualWeight = null,Object? actualReps = null,Object? setIndex = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,actualWeight: null == actualWeight ? _self.actualWeight : actualWeight // ignore: cast_nullable_to_non_nullable
as double,actualReps: null == actualReps ? _self.actualReps : actualReps // ignore: cast_nullable_to_non_nullable
as int,setIndex: null == setIndex ? _self.setIndex : setIndex // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SetLog].
extension SetLogPatterns on SetLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetLog value)  $default,){
final _that = this;
switch (_that) {
case _SetLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetLog value)?  $default,){
final _that = this;
switch (_that) {
case _SetLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String sessionId,  String exerciseId,  double actualWeight,  int actualReps,  int setIndex,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetLog() when $default != null:
return $default(_that.id,_that.sessionId,_that.exerciseId,_that.actualWeight,_that.actualReps,_that.setIndex,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String sessionId,  String exerciseId,  double actualWeight,  int actualReps,  int setIndex,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _SetLog():
return $default(_that.id,_that.sessionId,_that.exerciseId,_that.actualWeight,_that.actualReps,_that.setIndex,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String sessionId,  String exerciseId,  double actualWeight,  int actualReps,  int setIndex,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SetLog() when $default != null:
return $default(_that.id,_that.sessionId,_that.exerciseId,_that.actualWeight,_that.actualReps,_that.setIndex,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _SetLog implements SetLog {
  const _SetLog({this.id, required this.sessionId, required this.exerciseId, required this.actualWeight, required this.actualReps, required this.setIndex, this.createdAt});
  

// Nullable porque lo creamos antes de mandarlo a la DB.
@override final  String? id;
@override final  String sessionId;
@override final  String exerciseId;
@override final  double actualWeight;
@override final  int actualReps;
@override final  int setIndex;
@override final  DateTime? createdAt;

/// Create a copy of SetLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetLogCopyWith<_SetLog> get copyWith => __$SetLogCopyWithImpl<_SetLog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetLog&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.actualWeight, actualWeight) || other.actualWeight == actualWeight)&&(identical(other.actualReps, actualReps) || other.actualReps == actualReps)&&(identical(other.setIndex, setIndex) || other.setIndex == setIndex)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,sessionId,exerciseId,actualWeight,actualReps,setIndex,createdAt);

@override
String toString() {
  return 'SetLog(id: $id, sessionId: $sessionId, exerciseId: $exerciseId, actualWeight: $actualWeight, actualReps: $actualReps, setIndex: $setIndex, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SetLogCopyWith<$Res> implements $SetLogCopyWith<$Res> {
  factory _$SetLogCopyWith(_SetLog value, $Res Function(_SetLog) _then) = __$SetLogCopyWithImpl;
@override @useResult
$Res call({
 String? id, String sessionId, String exerciseId, double actualWeight, int actualReps, int setIndex, DateTime? createdAt
});




}
/// @nodoc
class __$SetLogCopyWithImpl<$Res>
    implements _$SetLogCopyWith<$Res> {
  __$SetLogCopyWithImpl(this._self, this._then);

  final _SetLog _self;
  final $Res Function(_SetLog) _then;

/// Create a copy of SetLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? sessionId = null,Object? exerciseId = null,Object? actualWeight = null,Object? actualReps = null,Object? setIndex = null,Object? createdAt = freezed,}) {
  return _then(_SetLog(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,actualWeight: null == actualWeight ? _self.actualWeight : actualWeight // ignore: cast_nullable_to_non_nullable
as double,actualReps: null == actualReps ? _self.actualReps : actualReps // ignore: cast_nullable_to_non_nullable
as int,setIndex: null == setIndex ? _self.setIndex : setIndex // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
