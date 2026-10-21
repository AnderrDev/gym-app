import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_state.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/utils/routine_day_phase_resolver.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_phase.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_prestart_view.dart';

void main() {
  group('resolveRoutineDayPhase al iniciar', () {
    const ready = RoutineDayState(status: RoutineDayStatus.ready);
    RoutineDayPhase resolve(ActiveWorkoutState active, {bool user = false}) =>
        resolveRoutineDayPhase(
          routine: ready,
          active: active,
          fallbackUserId: 'u',
          fallbackRoutineDayId: 'd',
          fallbackSessionDate: DateTime(2026, 10, 20),
          userStarting: user,
        );

    test('tras pulsar "Iniciar" se queda la previa con el botón cargando', () {
      for (final status in [
        ActiveWorkoutStatus.idle,
        ActiveWorkoutStatus.starting,
      ]) {
        final phase = resolve(ActiveWorkoutState(status: status), user: true);
        expect(phase, isA<RoutineDayPrestartPhase>());
        expect((phase as RoutineDayPrestartPhase).isStarting, isTrue);
      }
    });

    test('reanudar (sin pulsar "Iniciar") muestra la pantalla de carga', () {
      final phase = resolve(
        const ActiveWorkoutState(status: ActiveWorkoutStatus.starting),
      );
      expect(phase, isA<RoutineDayLoadingPhase>());
    });

    test('si falla el inicio manda el error aunque se pulsara "Iniciar"', () {
      final phase = resolve(
        const ActiveWorkoutState(
          status: ActiveWorkoutStatus.failure,
          errorMessage: 'boom',
        ),
        user: true,
      );
      expect(phase, isA<RoutineDayErrorPhase>());
    });
  });

  group('estimatedWorkoutMinutes', () {
    Exercise ex(int sets, int rest) => Exercise(
      id: 'e$sets$rest',
      routineDayId: 'd',
      name: 'x',
      targetMuscle: 'x',
      targetWeight: 0,
      targetReps: 10,
      targetSets: sets,
      restTimerSeconds: rest,
    );

    test('vacío o sin series es 0', () {
      expect(estimatedWorkoutMinutes(const []), 0);
      expect(estimatedWorkoutMinutes([ex(0, 90)]), 0);
    });

    test('series + descansos + cambios, redondeado a 5 min', () {
      // 2 × (4·40 s + 3·90 s) + 60 s de cambio = 920 s → 16 min → 20.
      expect(estimatedWorkoutMinutes([ex(4, 90), ex(4, 90)]), 20);
    });
  });
}
