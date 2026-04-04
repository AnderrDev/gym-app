import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
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
                    expandedHeight: 140,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: TextButton(
                          onPressed: () {
                            final authState = context.read<AuthBloc>().state;
                            final userId = (authState is Authenticated) ? authState.user.id : '';
                            
                            context.read<WorkoutBloc>().add(SaveRoutineDay(
                              userId: userId,
                              routineId: widget.routineId,
                              day: currentDay.copyWith(name: _nameController.text),
                            ));
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
                      titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          onChanged: (v) => setState(() {}),
                          style: AppTextStyles.heading1.copyWith(fontSize: 24, letterSpacing: -0.5),
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
              elevation: 0,
              highlightElevation: 0,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.search_rounded, color: Colors.black, size: 22),
              label: Text(
                'CATÁLOGO', 
                style: AppTextStyles.label.copyWith(
                  color: Colors.black, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1.5,
                ),
              ),
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
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.8), borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
      ),
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(22),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 20),
          ),
          title: Text(
            exercise.name.toUpperCase(), 
            style: AppTextStyles.heading2.copyWith(
              fontSize: 14, 
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                exercise.targetMuscle.toUpperCase(), 
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary, 
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: AppColors.textDisabled)),
              const SizedBox(width: 8),
              Text(
                '${exercise.targetSets} X ${exercise.targetReps}', 
                style: AppTextStyles.label.copyWith(fontSize: 10),
              ),
            ],
          ),
          trailing: const Icon(Icons.drag_indicator_rounded, color: AppColors.textDisabled, size: 20),
        ),
      ),
    );
  }
}
