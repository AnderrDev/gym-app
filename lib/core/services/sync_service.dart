import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../network/network_info.dart';
import '../../features/workout/domain/repositories/workout_repository.dart';

class SyncService {
  final NetworkInfo networkInfo;
  final WorkoutRepository workoutRepository;
  final InternetConnection internetConnection;

  SyncService({
    required this.networkInfo,
    required this.workoutRepository,
    required this.internetConnection,
  }) {
    _init();
  }

  void _init() {
    internetConnection.onStatusChange.listen((status) {
      if (status == InternetStatus.connected) {
        _triggerSync();
      }
    });
  }

  Future<void> _triggerSync() async {
    await workoutRepository.syncPendingData();
  }

  // Método manual para forzar sync
  Future<void> forceSync() => _triggerSync();
}
