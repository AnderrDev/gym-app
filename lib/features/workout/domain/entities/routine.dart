import 'package:equatable/equatable.dart';

class Routine extends Equatable {
  final String id;
  final String name;
  final int exerciseCount;
  final bool isPublic;
  final String? creatorId;
  final String? creatorName;

  const Routine({
    required this.id,
    required this.name,
    required this.exerciseCount,
    this.isPublic = false,
    this.creatorId,
    this.creatorName,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    exerciseCount,
    isPublic,
    creatorId,
    creatorName,
  ];
}
