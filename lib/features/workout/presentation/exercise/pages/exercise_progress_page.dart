import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
