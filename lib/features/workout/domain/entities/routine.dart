import 'package:equatable/equatable.dart';

class Routine extends Equatable {
  final String id;
  final String name;
  final int exerciseCount;

  const Routine({
    required this.id,
    required this.name,
    required this.exerciseCount,
  });

  @override
  List<Object?> get props => [id, name, exerciseCount];
}
