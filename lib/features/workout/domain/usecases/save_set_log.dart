import '../entities/set_log.dart';
import '../repositories/workout_repository.dart';

class SaveSetLog {
  final WorkoutRepository repository;

  SaveSetLog(this.repository);

  Future<void> call(SetLog setLog) {
    return repository.saveSetLog(setLog);
  }
}
