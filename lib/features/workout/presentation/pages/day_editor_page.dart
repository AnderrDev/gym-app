import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../widgets/exercise_catalog_sheet.dart';
import '../../domain/entities/routine_day.dart';
import '../../domain/entities/exercise.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class DayEditorPage extends StatefulWidget {
  final String routineId;
  final RoutineDay day;

  const DayEditorPage({
    super.key,
    required this.routineId,
    required this.day,
  });

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

  void _showExerciseCatalog(List<Exercise> currentExercises) {
    HapticFeedback.mediumImpact();
    final authState = context.read<AuthBloc>().state;
    final userId = (authState is Authenticated) ? authState.user.id : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseCatalogSheet(
        selectedExerciseIds: currentExercises.map((e) => e.name).toList(),
      ),
    ).then((selected) {
      if (!mounted) return;
      if (selected != null && selected is List<Map<String, String>>) {
        context.read<WorkoutBloc>().add(SaveRoutineDay(
          userId: userId,
          routineId: widget.routineId,
          day: widget.day.copyWith(
            exercises: [
              ...currentExercises,
              ...selected.map((e) => Exercise(
                id: '',
                routineDayId: widget.day.id,
                name: e['name']!,
                targetMuscle: e['target']!,
                targetWeight: 0,
                targetReps: 10,
                targetSets: 3,
                restTimerSeconds: 90,
              )),
            ],
          ),
        ));
        HapticFeedback.mediumImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorkoutBloc, WorkoutState>(
      listener: (context, state) {
        if (state is ManagementSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        if (state is WorkoutError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      child: BlocBuilder<WorkoutBloc, WorkoutState>(
        builder: (context, state) {
          final currentDay = (state is WeeklyPlanLoaded) 
            ? state.days.firstWhere(
                (d) => d.id == widget.day.id,
                orElse: () => widget.day,
              )
            : widget.day;
          
          final exercises = currentDay.exercises;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 160,
                  pinned: true,
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
                    onPressed: () => context.pop(),
                  ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          final authState = context.read<AuthBloc>().state;
                          final userId = (authState is Authenticated) ? authState.user.id : '';
                          
                          context.read<WorkoutBloc>().add(SaveRoutineDay(
                            userId: userId,
                            routineId: widget.routineId,
                            day: currentDay.copyWith(name: _nameController.text),
                          ));
                        },
                        child: Text('GUARDAR', style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                    ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    title: Text(
                      _nameController.text,
                      style: AppTextStyles.heading2.copyWith(fontSize: 18),
                    ),
                    background: Container(
                      padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.background],
                        ),
                      ),
                      child: TextField(
                        controller: _nameController,
                        onChanged: (v) => setState(() {}),
                        style: AppTextStyles.heading1.copyWith(fontSize: 28),
                        decoration: const InputDecoration(
                          hintText: 'Nombre del Día',
                          hintStyle: TextStyle(color: AppColors.textDisabled),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Row(
                      children: [
                        Text('EJERCICIOS ASIGNADOS', style: AppTextStyles.label.copyWith(letterSpacing: 1.2, color: AppColors.textSecondary)),
                        const Spacer(),
                        const Icon(Icons.info_outline, size: 14, color: AppColors.textDisabled),
                        const SizedBox(width: 4),
                        Text('Arrastra para reordenar', style: AppTextStyles.label.copyWith(color: AppColors.textDisabled, fontSize: 10)),
                      ],
                    ),
                  ),
                ),

                if (exercises.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Dale a "+" para añadir ejercicios', style: TextStyle(color: AppColors.textDisabled))),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverReorderableList(
                      itemCount: exercises.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final newExercises = List<Exercise>.from(exercises);
                        final item = newExercises.removeAt(oldIndex);
                        newExercises.insert(newIndex, item);
                        
                        final authState = context.read<AuthBloc>().state;
                        final userId = (authState is Authenticated) ? authState.user.id : '';

                        context.read<WorkoutBloc>().add(ReorderExercises(
                          userId: userId,
                          routineId: widget.routineId,
                          dayId: currentDay.id,
                          exerciseIds: newExercises.map((e) => e.id).toList(),
                        ));
                        HapticFeedback.lightImpact();
                      },
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return ReorderableDelayedDragStartListener(
                          key: ValueKey('ex_${exercise.id}_$index'),
                          index: index,
                          child: _buildExerciseRow(index, exercise, currentDay),
                        );
                      },
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
            
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showExerciseCatalog(exercises),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.search, color: Colors.black),
              label: const Text('CATÁLOGO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseRow(int index, Exercise exercise, RoutineDay currentDay) {
    return Dismissible(
      key: ValueKey('dismiss_${exercise.id}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
         final authState = context.read<AuthBloc>().state;
         final userId = (authState is Authenticated) ? authState.user.id : '';

         context.read<WorkoutBloc>().add(ToggleExerciseInDay(
           userId: userId,
           routineId: widget.routineId,
           dayId: currentDay.id,
           exerciseId: exercise.id,
         ));
         HapticFeedback.vibrate();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceHighlight, width: 0.5),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.fitness_center, color: AppColors.primary, size: 20),
          ),
          title: Text(exercise.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Row(
            children: [
              Text(exercise.targetMuscle, style: AppTextStyles.label.copyWith(color: AppColors.primary)),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: AppColors.textDisabled)),
              const SizedBox(width: 8),
              Text('3 x 10', style: AppTextStyles.label),
            ],
          ),
          trailing: const Icon(Icons.reorder, color: AppColors.textDisabled, size: 20),
        ),
      ),
    );
  }
}
