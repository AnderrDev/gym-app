import 'package:freezed_annotation/freezed_annotation.dart';

part 'set_log.freezed.dart';

@freezed
abstract class SetLog with _$SetLog {
  const factory SetLog({
    // Nullable porque lo creamos antes de mandarlo a la DB.
    String? id,
    required String sessionId,
    required String exerciseId,
    required double actualWeight,
    required int actualReps,
    required int setIndex,
    DateTime? createdAt,
  }) = _SetLog;
}
