import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/glass_container.dart';

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
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'MIS RUTINAS', 
                style: AppTextStyles.heading2.copyWith(
                  letterSpacing: 2,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              background: Container(color: AppColors.background),
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
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
        label: Text(
          'NUEVA RUTINA',
          style: AppTextStyles.label.copyWith(
            color: Colors.black, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.5,
          ),
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
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(28),
        borderOpacity: isActive ? 0.4 : 0.1,
        borderColor: isActive ? AppColors.primary : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ACTIVA',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildInfoTag(Icons.calendar_today_rounded, '$daysCount DÍAS / SEM'),
                const SizedBox(width: 12),
                _buildInfoTag(Icons.history_rounded, lastDone.toUpperCase()),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DETALLES DE RUTINA', 
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary, 
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
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
