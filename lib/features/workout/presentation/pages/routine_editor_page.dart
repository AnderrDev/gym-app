import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/routine_day.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class RoutineEditorPage extends StatefulWidget {
  final String? routineId;
  const RoutineEditorPage({super.key, this.routineId});

  @override
  State<RoutineEditorPage> createState() => _RoutineEditorPageState();
}

class _RoutineEditorPageState extends State<RoutineEditorPage> {
  late TextEditingController _nameController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    if (widget.routineId != null) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        context.read<WorkoutBloc>().add(FetchWeeklyPlan(
          userId: authState.user.id, 
          routineId: widget.routineId!, 
          weekStart: DateTime.now(),
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userId = (authState is Authenticated) ? authState.user.id : '';
        
        return BlocBuilder<WorkoutBloc, WorkoutState>(
          builder: (context, state) {
            List<RoutineDay> days = [];

            if (state is WeeklyPlanLoaded && !_isInitialized) {
              _nameController.text = "Rutina"; 
              days = state.days;
              _isInitialized = true;
            } else if (state is WeeklyPlanLoaded) {
              days = state.days;
            }

            return Scaffold(
              backgroundColor: AppColors.background,
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 180,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.background,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    actions: [
                      if (widget.routineId != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _showDeleteConfirmation(context, userId),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: TextButton(
                          onPressed: () {
                            context.read<WorkoutBloc>().add(CreateOrUpdateRoutine(
                              userId: userId,
                              id: widget.routineId,
                              name: _nameController.text,
                            ));
                            context.pop();
                          },
                          child: Text(
                            'GUARDAR',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      title: Text(
                        _nameController.text.isEmpty ? 'Nueva Rutina' : _nameController.text,
                        style: AppTextStyles.heading2.copyWith(fontSize: 20),
                      ),
                      background: Container(
                        padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.background,
                            ],
                          ),
                        ),
                        child: TextField(
                          controller: _nameController,
                          onChanged: (v) => setState(() {}),
                          style: AppTextStyles.heading1.copyWith(fontSize: 32),
                          decoration: InputDecoration(
                            hintText: 'Nombre de la Rutina',
                            hintStyle: AppTextStyles.heading1.copyWith(color: AppColors.textDisabled, fontSize: 32),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ESTRUCTURA SEMANAL',
                            style: AppTextStyles.label.copyWith(letterSpacing: 1.5, color: AppColors.textSecondary),
                          ),
                          Text(
                            '${days.length} DÍAS',
                            style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverReorderableList(
                      itemCount: days.length,
                      onReorder: (oldIdx, newIdx) {
                        HapticFeedback.lightImpact();
                      },
                      itemBuilder: (context, index) {
                        final day = days[index];
                        return ReorderableDelayedDragStartListener(
                          key: ValueKey(day.id),
                          index: index,
                          child: _buildDayCard(index, day),
                        );
                      },
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: GestureDetector(
                        onTap: () {
                          if (widget.routineId != null) {
                            context.read<WorkoutBloc>().add(SaveRoutineDay(
                              userId: userId,
                              routineId: widget.routineId!,
                              day: RoutineDay(
                                id: '',
                                routineId: widget.routineId!,
                                name: 'Nuevo Día',
                                dayOfWeek: days.length + 1,
                                exercises: const [],
                              ),
                            ));
                          }
                          HapticFeedback.heavyImpact();
                        },
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'AÑADIR DÍA',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('¿Eliminar Rutina?', style: AppTextStyles.heading2),
          content: Text(
            'Esta acción no se puede deshacer. Se borrarán todos los días y configuraciones asociadas.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCELAR', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<WorkoutBloc>().add(DeleteRoutine(
                  userId: userId,
                  routineId: widget.routineId!,
                ));
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('ELIMINAR', style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayCard(int index, RoutineDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceHighlight, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          onTap: () => context.push('/day-editor', extra: {
            'day': day,
            'routineId': widget.routineId ?? '',
          }),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${index + 1}',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            day.name,
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${day.exercises.length} ejercicios',
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
          ),
          trailing: const Icon(Icons.reorder, color: AppColors.textDisabled),
        ),
      ),
    );
  }
}
