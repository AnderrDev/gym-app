import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_bottom_sheet.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_catalog_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/exercise_row_card.dart';

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

  Future<void> _showExerciseCatalog(List<Exercise> currentExercises) async {
    final authState = context.read<AuthBloc>().state;
    final userId = (authState is Authenticated) ? authState.user.id : '';
    final bloc = context.read<RoutineManagementBloc>();
    unawaited(HapticFeedback.mediumImpact());

    // Cargar el catálogo si aún no está listo.
    if (bloc.state.catalogStatus != ExerciseCatalogStatus.ready) {
      bloc.add(const LoadExerciseCatalog());
    }

    final result = await AppBottomSheet.showRaw<List<ExerciseCatalogItem>>(
      context,
      builder: (_) =>
          BlocBuilder<RoutineManagementBloc, RoutineManagementState>(
            bloc: bloc,
            builder: (_, state) {
              if (state.catalogStatus == ExerciseCatalogStatus.loading &&
                  state.exerciseCatalog.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return ExerciseCatalogSheet(
                catalog: state.exerciseCatalog,
                alreadySelectedIds:
                    currentExercises.map((e) => e.id).toSet(),
              );
            },
          ),
    );

    if (!mounted || result == null || result.isEmpty) return;

    final dayId = widget.day.id;
    if (dayId.isEmpty) {
      AppSnackBar.error(context, 'Guarda el día primero');
      return;
    }

    bloc.add(
      AddExercisesToDayEvent(
        userId: userId,
        routineId: widget.routineId,
        dayId: dayId,
        items: result
            .map((e) => AddExerciseToDayPayload(exerciseId: e.id))
            .toList(),
      ),
    );
    unawaited(HapticFeedback.mediumImpact());
  }

  Future<bool> _confirmDiscard() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Tienes cambios sin guardar. Si sales ahora se perderán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'DESCARTAR',
              style: AppTextStyles.label.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoutineManagementBloc, RoutineManagementState>(
      listenWhen: (p, c) =>
          p.submissionStatus != c.submissionStatus &&
          (c.submissionStatus == RoutineManagementSubmissionStatus.success ||
              c.submissionStatus == RoutineManagementSubmissionStatus.failure),
      listener: (context, state) {
        if (state.submissionStatus ==
            RoutineManagementSubmissionStatus.success) {
          AppSnackBar.success(context, state.feedbackMessage ?? 'OK');
          context.read<RoutineManagementBloc>().add(
            const AcknowledgeFeedback(),
          );
        } else if (state.submissionStatus ==
            RoutineManagementSubmissionStatus.failure) {
          AppSnackBar.error(context, 'Error: ${state.errorMessage ?? ''}');
          context.read<RoutineManagementBloc>().add(
            const AcknowledgeFeedback(),
          );
        }
      },
      builder: (context, state) {
        final currentDay = state.editingDays.isNotEmpty
            ? state.editingDays.firstWhere(
                (d) => d.id == widget.day.id,
                orElse: () => widget.day,
              )
            : widget.day;

        final exercises = currentDay.exercises;
        final isDirty = state.isDirty;

        return PopScope(
          canPop: !isDirty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final navigator = GoRouter.of(context);
            final shouldPop = await _confirmDiscard();
            if (!mounted) return;
            if (shouldPop) {
              navigator.pop(isDirty);
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 140,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    onPressed: () async {
                      if (!isDirty) {
                        context.pop(isDirty);
                        return;
                      }
                      final navigator = GoRouter.of(context);
                      final shouldPop = await _confirmDiscard();
                      if (!mounted) return;
                      if (shouldPop) navigator.pop(isDirty);
                    },
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: TextButton(
                        onPressed: () {
                          final authState = context.read<AuthBloc>().state;
                          final userId = (authState is Authenticated)
                              ? authState.user.id
                              : '';

                          context.read<RoutineManagementBloc>().add(
                            SaveDay(
                              userId: userId,
                              routineId: widget.routineId,
                              day: currentDay.copyWith(
                                name: _nameController.text,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'GUARDAR',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    title: Text(
                      _nameController.text.toUpperCase(),
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 16,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    background: Container(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                      color: AppColors.background,
                      child: TextField(
                        controller: _nameController,
                        onChanged: (v) {
                          setState(() {});
                          context
                              .read<RoutineManagementBloc>()
                              .add(const MarkRoutineDirty());
                        },
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 24,
                          letterSpacing: -0.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'NOMBRE DEL DÍA',
                          hintStyle: AppTextStyles.heading1.copyWith(
                            color: AppColors.textDisabled,
                            fontSize: 24,
                            letterSpacing: -0.5,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.lgPlus,
                      Spacing.xl,
                      Spacing.lgPlus,
                      Spacing.lg,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'EJERCICIOS ASIGNADOS',
                          style: AppTextStyles.label.copyWith(
                            letterSpacing: 1.2,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.textDisabled,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Arrastra para reordenar',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textDisabled,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (exercises.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Dale a "+" para añadir ejercicios',
                        style: TextStyle(color: AppColors.textDisabled),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    sliver: SliverReorderableList(
                      itemCount: exercises.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final newExercises = List<Exercise>.from(exercises);
                        final item = newExercises.removeAt(oldIndex);
                        newExercises.insert(newIndex, item);

                        final authState = context.read<AuthBloc>().state;
                        final userId = (authState is Authenticated)
                            ? authState.user.id
                            : '';

                        context.read<RoutineManagementBloc>().add(
                          ReorderExercises(
                            userId: userId,
                            routineId: widget.routineId,
                            dayId: currentDay.id,
                            exerciseIds:
                                newExercises.map((e) => e.id).toList(),
                          ),
                        );
                        HapticFeedback.lightImpact();
                      },
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return ReorderableDelayedDragStartListener(
                          key: ValueKey('ex_${exercise.id}_$index'),
                          index: index,
                          child:
                              _buildExerciseRow(index, exercise, currentDay),
                        );
                      },
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),

            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showExerciseCatalog(exercises),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildExerciseRow(
    int index,
    Exercise exercise,
    RoutineDay currentDay,
  ) {
    return ExerciseRowCard(
      exercise: exercise,
      index: index,
      onRemove: () {
        final authState = context.read<AuthBloc>().state;
        final userId = (authState is Authenticated) ? authState.user.id : '';
        context.read<RoutineManagementBloc>().add(
          RemoveExerciseFromDayEvent(
            userId: userId,
            routineId: widget.routineId,
            dayId: currentDay.id,
            exerciseId: exercise.id,
          ),
        );
      },
    );
  }
}
