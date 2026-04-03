import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class RoutineListPage extends StatelessWidget {
  const RoutineListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar Premium ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              title: Text('Mis Rutinas', style: AppTextStyles.heading2),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.background],
                  ),
                ),
              ),
            ),
          ),

          // ── Lista de Rutinas ─────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildRoutineCard(
                  context,
                  title: 'Rutina Ganancia de Fuerza',
                  daysCount: 4,
                  lastDone: 'Ayer',
                  isActive: true,
                ),
                const SizedBox(height: 16),
                _buildRoutineCard(
                  context,
                  title: 'Push Pull Legs (PPL)',
                  daysCount: 3,
                  lastDone: 'Hace 5 días',
                  isActive: false,
                ),
                const SizedBox(height: 16),
                _buildRoutineCard(
                  context,
                  title: 'Full Body A/B',
                  daysCount: 2,
                  lastDone: 'Hace 2 semanas',
                  isActive: false,
                ),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
      
      // Botón Premium para Nueva Rutina
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/routine-editor');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
        label: const Text(
          'NUEVA RUTINA',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildRoutineCard(
    BuildContext context, {
    required String title,
    required int daysCount,
    required String lastDone,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/routine-editor');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.surfaceHighlight,
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACTIVA',
                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildInfoTag(Icons.calendar_today_rounded, '$daysCount días/sem'),
                const SizedBox(width: 12),
                _buildInfoTag(Icons.history_rounded, lastDone),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ver detalles', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textDisabled, size: 14),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
