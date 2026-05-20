import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/ui/feedback/discard_changes_dialog.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/day_editor_app_bar.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/day_editor_dialogs.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/day_editor_empty_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/day_name_input.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/day_summary.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/exercise_row_card.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/section_header.dart';

class DayEditorPage extends StatefulWidget {
  final String routineId;
  final RoutineDay day;

  const DayEditorPage({super.key, required this.routineId, required this.day});

  @override
  State<DayEditorPage> createState() => _DayEditorPageState();
}

class _DayEditorPageState extends State<DayEditorPage> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.day.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard() => DiscardChangesDialog.show(context);

  String get _userId {
    final s = context.read<AuthBloc>().state;
    return s is Authenticated ? s.user.id : '';
  }

  void _onSubmissionFeedback(
    BuildContext context,
    RoutineManagementState state,
  ) {
    final wasSaveDay = state.lastAction == RoutineManagementAction.saveDay;
    if (state.submissionStatus == RoutineManagementSubmissionStatus.success) {
      AppSnackBar.success(context, state.feedbackMessage ?? 'OK');
    } else if (state.submissionStatus ==
        RoutineManagementSubmissionStatus.failure) {
      AppSnackBar.error(context, 'Error: ${state.errorMessage ?? ''}');
    }
    context.read<RoutineManagementBloc>().add(const AcknowledgeFeedback());
    // Si el guardar del día fue OK, cerramos el editor y devolvemos `true`
    // al RoutineEditor para que sepa que hubo cambios (mismo contrato que
    // usa `_onBackPressed`).
    if (wasSaveDay &&
        state.submissionStatus == RoutineManagementSubmissionStatus.success) {
      GoRouter.of(context).pop(true);
    }
  }

  bool _isSubmissionTerminal(
    RoutineManagementState prev,
    RoutineManagementState curr,
  ) =>
      prev.submissionStatus != curr.submissionStatus &&
      (curr.submissionStatus == RoutineManagementSubmissionStatus.success ||
          curr.submissionStatus == RoutineManagementSubmissionStatus.failure);

  RoutineDay _resolveCurrentDay(RoutineManagementState state) {
    if (state.editingDays.isEmpty) return widget.day;
    return state.editingDays.firstWhere(
      (d) => d.id == widget.day.id,
      orElse: () => widget.day,
    );
  }

  Future<void> _onPopInvoked(bool didPop, bool isDirty) async {
    if (didPop) return;
    final navigator = GoRouter.of(context);
    final shouldPop = await _confirmDiscard();
    if (!mounted) return;
    if (shouldPop) navigator.pop(isDirty);
  }

  Future<void> _onBackPressed(bool isDirty) async {
    if (!isDirty) {
      context.pop(isDirty);
      return;
    }
    final navigator = GoRouter.of(context);
    final shouldPop = await _confirmDiscard();
    if (!mounted) return;
    if (shouldPop) navigator.pop(isDirty);
  }

  void _onReorder(
    List<Exercise> exercises,
    RoutineDay currentDay,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex -= 1;
    final newExercises = List<Exercise>.from(exercises);
    final item = newExercises.removeAt(oldIndex);
    newExercises.insert(newIndex, item);
    context.read<RoutineManagementBloc>().add(
      ReorderExercises(
        userId: _userId,
        routineId: widget.routineId,
        dayId: currentDay.id,
        exerciseIds: newExercises.map((e) => e.id).toList(),
      ),
    );
    HapticFeedback.lightImpact();
  }

  void _onSavePressed(RoutineDay currentDay) {
    context.read<RoutineManagementBloc>().add(
      SaveDay(
        userId: _userId,
        routineId: widget.routineId,
        day: currentDay.copyWith(name: _nameController.text),
      ),
    );
  }

  void _onRemoveExercise(Exercise exercise, RoutineDay currentDay) {
    context.read<RoutineManagementBloc>().add(
      RemoveExerciseFromDayEvent(
        userId: _userId,
        routineId: widget.routineId,
        dayId: currentDay.id,
        exerciseId: exercise.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoutineManagementBloc, RoutineManagementState>(
      listenWhen: _isSubmissionTerminal,
      listener: _onSubmissionFeedback,
      builder: (context, state) {
        final currentDay = _resolveCurrentDay(state);
        final exercises = currentDay.exercises;
        final isDirty = state.isDirty;
        return PopScope(
          canPop: !isDirty,
          onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop, isDirty),
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                DayEditorAppBar(
                  isDirty: isDirty,
                  onBack: () => _onBackPressed(isDirty),
                  onSave: () => _onSavePressed(currentDay),
                ),
                SliverToBoxAdapter(
                  child: DayNameInput(
                    controller: _nameController,
                    onChanged: (_) => context
                        .read<RoutineManagementBloc>()
                        .add(const MarkRoutineDirty()),
                  ),
                ),
                if (exercises.isNotEmpty)
                  SliverToBoxAdapter(child: DaySummary(exercises: exercises)),
                SliverToBoxAdapter(
                  child: _buildExercisesSectionHeader(exercises),
                ),
                _buildExercisesSliver(exercises, currentDay),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
            floatingActionButton: _buildCatalogFab(currentDay, exercises),
          ),
        );
      },
    );
  }

  Widget _buildExercisesSectionHeader(List<Exercise> exercises) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lgPlus,
        Spacing.md,
        Spacing.lgPlus,
        Spacing.sm,
      ),
      child: SectionHeader(
        label: 'Ejercicios',
        trailing: Text(
          '${exercises.length}',
          style: AppTextStyles.label.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        hint: exercises.length >= 2
            ? 'Mantén para reordenar · toca para editar'
            : (exercises.isNotEmpty ? 'Toca para editar objetivos' : null),
      ),
    );
  }

  Widget _buildExercisesSliver(
    List<Exercise> exercises,
    RoutineDay currentDay,
  ) {
    if (exercises.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: DayEditorEmptyState(
          onTap: () => DayEditorDialogs.showExerciseCatalog(
            context,
            routineId: widget.routineId,
            day: currentDay,
            currentExercises: exercises,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      sliver: SliverReorderableList(
        itemCount: exercises.length,
        onReorder: (oldIdx, newIdx) =>
            _onReorder(exercises, currentDay, oldIdx, newIdx),
        itemBuilder: (context, index) {
          final ex = exercises[index];
          return ReorderableDelayedDragStartListener(
            key: ValueKey('ex_${ex.id}_$index'),
            index: index,
            child: ExerciseRowCard(
              exercise: ex,
              index: index,
              onTap: () => DayEditorDialogs.openEditTargetSheet(
                context,
                routineId: widget.routineId,
                day: currentDay,
                exercise: ex,
              ),
              onRemove: () => _onRemoveExercise(ex, currentDay),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCatalogFab(RoutineDay currentDay, List<Exercise> exercises) {
    return FloatingActionButton.extended(
      onPressed: () => DayEditorDialogs.showExerciseCatalog(
        context,
        routineId: widget.routineId,
        day: currentDay,
        currentExercises: exercises,
      ),
      elevation: 0,
      highlightElevation: 0,
      backgroundColor: AppColors.primary,
      icon: const Icon(
        Icons.search_rounded,
        color: AppColors.onPrimary,
        size: 22,
      ),
      label: Text(
        'CATÁLOGO',
        style: AppTextStyles.label.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

}
