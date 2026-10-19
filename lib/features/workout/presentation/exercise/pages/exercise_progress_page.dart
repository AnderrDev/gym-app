import 'package:flutter/material.dart';

import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_stats_bottom_sheet.dart';

class ExerciseProgressPage extends StatelessWidget {
  final String userId;
  final String exerciseId;
  final String exerciseName;

  const ExerciseProgressPage({
    super.key,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    // Primera fase: reutilizamos el componente de estadísticas existente
    // para ofrecer una vista completa sin duplicar lógica ni BLoC.
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              color: context.colors.textPrimary,
            ),
            tooltip: 'Cómo se hace',
            onPressed: () => pushExerciseDetail(context, exerciseId),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ExerciseStatsBottomSheet(
          userId: userId,
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          fullscreen: true,
        ),
      ),
    );
  }
}
