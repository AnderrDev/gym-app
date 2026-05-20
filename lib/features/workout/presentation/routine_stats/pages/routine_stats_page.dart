import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_stats/routine_stats_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_stats/routine_stats_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_stats/routine_stats_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_stats/widgets/routine_session_card.dart';
import 'package:gym_flutter/features/workout/presentation/routine_stats/widgets/routine_stats_volume_chart.dart';
import 'package:gym_flutter/injection_container.dart';

class RoutineStatsPage extends StatelessWidget {
  final String userId;
  final String routineId;
  final String routineName;

  const RoutineStatsPage({
    super.key,
    required this.userId,
    required this.routineId,
    required this.routineName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RoutineStatsBloc(repository: sl())
            ..add(FetchRoutineStats(userId: userId, routineId: routineId)),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text('Historial: $routineName', style: AppTextStyles.heading2),
        ),
        body: BlocConsumer<RoutineStatsBloc, RoutineStatsState>(
          listenWhen: (previous, current) => current is RoutineStatsError,
          listener: (context, state) {
            if (state is RoutineStatsError) {
              AppSnackBar.error(context, state.message);
            }
          },
          buildWhen: (previous, current) =>
              current is RoutineStatsLoading ||
              current is RoutineStatsLoaded ||
              current is RoutineStatsError,
          builder: (context, state) {
            if (state is RoutineStatsLoading) {
              return const Center(child: AppSpinner.large());
            }
            if (state is RoutineStatsError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }
            if (state is RoutineStatsLoaded) {
              if (state.stats.isEmpty) return const _EmptyState();
              return _StatsContent(stats: state.stats);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: AppColors.surfaceHighlight,
          ),
          const SizedBox(height: 16),
          Text('Sin datos suficientes', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(
            'Completa sesiones para ver tu evolución.',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.stats});

  final List<RoutineHistorySession> stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        RoutineStatsVolumeChart(stats: stats),
        const SizedBox(height: 24),
        Text(
          'EVOLUCIÓN DE VOLUMEN',
          style: AppTextStyles.label.copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        ...stats.reversed.map((s) => RoutineSessionCard(session: s)),
      ],
    );
  }
}
