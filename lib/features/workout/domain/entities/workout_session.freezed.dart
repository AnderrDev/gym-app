// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkoutSession {

 String get id; String get userId; String get routineDayId; DateTime get sessionDate; DateTime? get completedAt; int get completedSetsCount; int get totalTargetSets; List<CoachingAnalysis>? get coachingAnalysis;
/// Create a copy of WorkoutSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutSessionCopyWith<WorkoutSession> get copyWith => _$WorkoutSessionCopyWithImpl<WorkoutSession>(this as WorkoutSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutSession&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.routineDayId, routineDayId) || other.routineDayId == routineDayId)&&(identical(other.sessionDate, sessionDate) || other.sessionDate == sessionDate)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.completedSetsCount, completedSetsCount) || other.completedSetsCount == completedSetsCount)&&(identical(other.totalTargetSets, totalTargetSets) || other.totalTargetSets == totalTargetSets)&&const DeepCollectionEquality().equals(other.coachingAnalysis, coachingAnalysis));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,routineDayId,sessionDate,completedAt,completedSetsCount,totalTargetSets,const DeepCollectionEquality().hash(coachingAnalysis));

@override
String toString() {
  return 'WorkoutSession(id: $id, userId: $userId, routineDayId: $routineDayId, sessionDate: $sessionDate, completedAt: $completedAt, completedSetsCount: $completedSetsCount, totalTargetSets: $totalTargetSets, coachingAnalysis: $coachingAnalysis)';
}


}

/// @nodoc
abstract mixin class $WorkoutSessionCopyWith<$Res>  {
  factory $WorkoutSessionCopyWith(WorkoutSession value, $Res Function(WorkoutSession) _then) = _$WorkoutSessionCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String routineDayId, DateTime sessionDate, DateTime? completedAt, int completedSetsCount, int totalTargetSets, List<CoachingAnalysis>? coachingAnalysis
});




}
/// @nodoc
class _$WorkoutSessionCopyWithImpl<$Res>
    implements $WorkoutSessionCopyWith<$Res> {
  _$WorkoutSessionCopyWithImpl(this._self, this._then);

  final WorkoutSession _self;
  final $Res Function(WorkoutSession) _then;

/// Create a copy of WorkoutSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? routineDayId = null,Object? sessionDate = null,Object? completedAt = freezed,Object? completedSetsCount = null,Object? totalTargetSets = null,Object? coachingAnalysis = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,routineDayId: null == routineDayId ? _self.routineDayId : routineDayId // ignore: cast_nullable_to_non_nullable
as String,sessionDate: null == sessionDate ? _self.sessionDate : sessionDate // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedSetsCount: null == completedSetsCount ? _self.completedSetsCount : completedSetsCount // ignore: cast_nullable_to_non_nullable
as int,totalTargetSets: null == totalTargetSets ? _self.totalTargetSets : totalTargetSets // ignore: cast_nullable_to_non_nullable
as int,coachingAnalysis: freezed == coachingAnalysis ? _self.coachingAnalysis : coachingAnalysis // ignore: cast_nullable_to_non_nullable
as List<CoachingAnalysis>?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutSession].
extension WorkoutSessionPatterns on WorkoutSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutSession value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutSession value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String routineDayId,  DateTime sessionDate,  DateTime? completedAt,  int completedSetsCount,  int totalTargetSets,  List<CoachingAnalysis>? coachingAnalysis)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutSession() when $default != null:
return $default(_that.id,_that.userId,_that.routineDayId,_that.sessionDate,_that.completedAt,_that.completedSetsCount,_that.totalTargetSets,_that.coachingAnalysis);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String routineDayId,  DateTime sessionDate,  DateTime? completedAt,  int completedSetsCount,  int totalTargetSets,  List<CoachingAnalysis>? coachingAnalysis)  $default,) {final _that = this;
switch (_that) {
case _WorkoutSession():
return $default(_that.id,_that.userId,_that.routineDayId,_that.sessionDate,_that.completedAt,_that.completedSetsCount,_that.totalTargetSets,_that.coachingAnalysis);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String routineDayId,  DateTime sessionDate,  DateTime? completedAt,  int completedSetsCount,  int totalTargetSets,  List<CoachingAnalysis>? coachingAnalysis)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutSession() when $default != null:
return $default(_that.id,_that.userId,_that.routineDayId,_that.sessionDate,_that.completedAt,_that.completedSetsCount,_that.totalTargetSets,_that.coachingAnalysis);case _:
  return null;

}
}

}

/// @nodoc


class _WorkoutSession implements WorkoutSession {
  const _WorkoutSession({required this.id, required this.userId, required this.routineDayId, required this.sessionDate, this.completedAt, this.completedSetsCount = 0, this.totalTargetSets = 0, final  List<CoachingAnalysis>? coachingAnalysis}): _coachingAnalysis = coachingAnalysis;
  

@override final  String id;
@override final  String userId;
@override final  String routineDayId;
@override final  DateTime sessionDate;
@override final  DateTime? completedAt;
@override@JsonKey() final  int completedSetsCount;
@override@JsonKey() final  int totalTargetSets;
 final  List<CoachingAnalysis>? _coachingAnalysis;
@override List<CoachingAnalysis>? get coachingAnalysis {
  final value = _coachingAnalysis;
  if (value == null) return null;
  if (_coachingAnalysis is EqualUnmodifiableListView) return _coachingAnalysis;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of WorkoutSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutSessionCopyWith<_WorkoutSession> get copyWith => __$WorkoutSessionCopyWithImpl<_WorkoutSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutSession&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.routineDayId, routineDayId) || other.routineDayId == routineDayId)&&(identical(other.sessionDate, sessionDate) || other.sessionDate == sessionDate)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.completedSetsCount, completedSetsCount) || other.completedSetsCount == completedSetsCount)&&(identical(other.totalTargetSets, totalTargetSets) || other.totalTargetSets == totalTargetSets)&&const DeepCollectionEquality().equals(other._coachingAnalysis, _coachingAnalysis));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,routineDayId,sessionDate,completedAt,completedSetsCount,totalTargetSets,const DeepCollectionEquality().hash(_coachingAnalysis));

@override
String toString() {
  return 'WorkoutSession(id: $id, userId: $userId, routineDayId: $routineDayId, sessionDate: $sessionDate, completedAt: $completedAt, completedSetsCount: $completedSetsCount, totalTargetSets: $totalTargetSets, coachingAnalysis: $coachingAnalysis)';
}


}

/// @nodoc
abstract mixin class _$WorkoutSessionCopyWith<$Res> implements $WorkoutSessionCopyWith<$Res> {
  factory _$WorkoutSessionCopyWith(_WorkoutSession value, $Res Function(_WorkoutSession) _then) = __$WorkoutSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String routineDayId, DateTime sessionDate, DateTime? completedAt, int completedSetsCount, int totalTargetSets, List<CoachingAnalysis>? coachingAnalysis
});




}
/// @nodoc
class __$WorkoutSessionCopyWithImpl<$Res>
    implements _$WorkoutSessionCopyWith<$Res> {
  __$WorkoutSessionCopyWithImpl(this._self, this._then);

  final _WorkoutSession _self;
  final $Res Function(_WorkoutSession) _then;

/// Create a copy of WorkoutSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? routineDayId = null,Object? sessionDate = null,Object? completedAt = freezed,Object? completedSetsCount = null,Object? totalTargetSets = null,Object? coachingAnalysis = freezed,}) {
  return _then(_WorkoutSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,routineDayId: null == routineDayId ? _self.routineDayId : routineDayId // ignore: cast_nullable_to_non_nullable
as String,sessionDate: null == sessionDate ? _self.sessionDate : sessionDate // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedSetsCount: null == completedSetsCount ? _self.completedSetsCount : completedSetsCount // ignore: cast_nullable_to_non_nullable
as int,totalTargetSets: null == totalTargetSets ? _self.totalTargetSets : totalTargetSets // ignore: cast_nullable_to_non_nullable
as int,coachingAnalysis: freezed == coachingAnalysis ? _self._coachingAnalysis : coachingAnalysis // ignore: cast_nullable_to_non_nullable
as List<CoachingAnalysis>?,
  ));
}


}

// dart format on
