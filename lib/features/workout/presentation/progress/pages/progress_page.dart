import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Stub inicial de la pestaña PROGRESO. Sin lógica por ahora — el hub real
/// (insights semanales, lista de rutinas, etc.) se construye en una task
/// siguiente.
class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'PROGRESO',
          style: AppTextStyles.heading2.copyWith(letterSpacing: 2),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.insights_outlined,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'Próximamente',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
