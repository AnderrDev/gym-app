import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

class RoutineDayAppBar extends StatelessWidget {
  final RoutineDay routineDay;
  final String dateLabel;
  final WorkoutSession? lastSession;
  final List<SetLog> lastLogs;
  final List<Exercise> exercises;
  final bool isActive;
  final double? totalVolume;
  final int completedSets;
  final int totalSets;
  final VoidCallback onClose;
  final VoidCallback? onFinish;

  /// Si no es `null`, el app bar activo muestra un menú con "Descartar".
  final VoidCallback? onDiscard;

  /// Si no es `null`, el menú activo ofrece "Añadir ejercicio extra".
  final VoidCallback? onAddExercise;
  final void Function(
    WorkoutSession session,
    List<SetLog> logs,
    List<Exercise> exercises,
  )
  onShowLastSessionDetails;

  const RoutineDayAppBar({
    super.key,
    required this.routineDay,
    required this.dateLabel,
    required this.lastSession,
    required this.lastLogs,
    required this.exercises,
    required this.onClose,
    required this.onShowLastSessionDetails,
    this.isActive = false,
    this.totalVolume,
    this.completedSets = 0,
    this.totalSets = 0,
    this.onFinish,
    this.onDiscard,
    this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return SliverAppBar(
        pinned: true,
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: context.colors.textPrimary,
            size: 24,
          ),
          tooltip: 'Salir del entrenamiento',
          onPressed: onClose,
        ),
        title: Text(
          routineDay.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (onDiscard != null || onAddExercise != null)
            PopupMenuButton<_ActiveMenuAction>(
              tooltip: 'Más opciones',
              icon: Icon(
                Icons.more_vert_rounded,
                color: context.colors.textPrimary,
              ),
              onSelected: (action) => switch (action) {
                _ActiveMenuAction.add => onAddExercise?.call(),
                _ActiveMenuAction.discard => onDiscard?.call(),
              },
              itemBuilder: (context) => [
                if (onAddExercise != null)
                  const PopupMenuItem(
                    value: _ActiveMenuAction.add,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.add_rounded),
                      title: Text('Añadir ejercicio extra'),
                    ),
                  ),
                if (onDiscard != null)
                  PopupMenuItem(
                    value: _ActiveMenuAction.discard,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: context.colors.error,
                      ),
                      title: Text(
                        'Descartar entrenamiento',
                        style: TextStyle(color: context.colors.error),
                      ),
                    ),
                  ),
              ],
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: _ActiveBottomBar(
            completedSets: completedSets,
            totalSets: totalSets,
            totalVolume: totalVolume ?? 0,
            hasLastSession: lastSession != null,
            onOpenHistory: lastSession == null
                ? null
                : () => onShowLastSessionDetails(
                    lastSession!,
                    lastLogs,
                    exercises,
                  ),
            onFinish: onFinish,
          ),
        ),
      );
    }
    return SliverAppBar(
      pinned: true,
      backgroundColor: context.colors.background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Volver',
        onPressed: onClose,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            routineDay.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            dateLabel,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        if (lastSession != null)
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Ver sesiones anteriores',
            onPressed: () =>
                onShowLastSessionDetails(lastSession!, lastLogs, exercises),
          ),
      ],
    );
  }
}

enum _ActiveMenuAction { add, discard }

class _ActiveBottomBar extends StatelessWidget {
  const _ActiveBottomBar({
    required this.completedSets,
    required this.totalSets,
    required this.totalVolume,
    required this.hasLastSession,
    required this.onOpenHistory,
    required this.onFinish,
  });

  final int completedSets;
  final int totalSets;
  final double totalVolume;
  final bool hasLastSession;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final progress = totalSets > 0
        ? (completedSets / totalSets).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.sm, Spacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de progreso implícitamente animada. Solo el child
          // (FractionallySizedBox) cambia su widthFactor a 60fps; el
          // resto del app bar no se rebuildea. Es lighter que un
          // TweenAnimationBuilder envolviendo un LinearProgressIndicator
          // porque no recrea el widget cada frame y no paga el paint de
          // un LinearProgressIndicator (que internamente maneja también
          // el modo indeterminado).
          SizedBox(
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                // fit: expand pasa constraints tight a los children no
                // posicionados, así FractionallySizedBox tiene un maxWidth
                // finito contra el que computar el factor.
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: context.colors.divider),
                  AnimatedFractionallySizedBox(
                    widthFactor: progress,
                    alignment: Alignment.centerLeft,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: ColoredBox(color: context.colors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              Text(
                'En curso · $completedSets/$totalSets series',
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (totalVolume > 0) ...[
                const SizedBox(width: Spacing.sm),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  '${totalVolume.toStringAsFixed(0)} kg',
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              if (hasLastSession && onOpenHistory != null)
                IconButton(
                  tooltip: 'Ver la última sesión',
                  icon: Icon(
                    Icons.history_rounded,
                    color: context.colors.primary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onOpenHistory,
                ),
              if (onFinish != null) ...[
                const SizedBox(width: 4),
                TextButton(
                  onPressed: onFinish,
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: context.colors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Text(
                    'Finalizar',
                    style: context.text.labelLarge?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
