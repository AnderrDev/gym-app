import 'package:freezed_annotation/freezed_annotation.dart';

part 'routine.freezed.dart';

@freezed
abstract class Routine with _$Routine {
  const factory Routine({
    required String id,
    required String name,
    required int exerciseCount,
    @Default(false) bool isPublic,
    String? creatorId,
    String? creatorName,
  }) = _Routine;
}
