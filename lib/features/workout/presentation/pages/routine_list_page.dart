import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import '../../domain/entities/routine.dart';

class RoutineListPage extends StatefulWidget {
  const RoutineListPage({super.key});

  @override
  State<RoutineListPage> createState() => _RoutineListPageState();
}

enum _FilterType { all, mine, community }

class _RoutineListPageState extends State<RoutineListPage> {
  _FilterType _selectedFilter = _FilterType.all;
  List<Routine> _cachedRoutines = [];

  @override
  void initState() {
    super.initState();
    context.read<WorkoutBloc>().add(const FetchAllRoutines());
  }

  void _onAssignRoutine(String routineId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      HapticFeedback.heavyImpact();
      context.read<WorkoutBloc>().add(
        AssignRoutineEvent(userId: authState.user.id, routineId: routineId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<WorkoutBloc, WorkoutState>(
        listenWhen: (previous, current) =>
            current is ManagementSuccess || current is WorkoutError,
        listener: (context, state) {
          if (state is ManagementSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            // Redirigir al dashboard para ver la rutina activa
            context.pop(true);
          } else if (state is WorkoutError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AllRoutinesLoaded) {
            _cachedRoutines = state.routines;
          } else if (state is RoutinesLoaded) {
            _cachedRoutines = state.routines;
          }

          final routines = (state is AllRoutinesLoaded)
              ? state.routines
              : (state is RoutinesLoaded)
              ? state.routines
              : _cachedRoutines;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar Premium ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  title: Text(
                    'DESCUBRIR RUTINAS',
                    style: AppTextStyles.heading2.copyWith(
                      letterSpacing: 2,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  background: Container(color: AppColors.background),
                ),
              ),

              // ── Filtros ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(_FilterType.all, 'TODAS'),
                        const SizedBox(width: 8),
                        _filterChip(_FilterType.mine, 'MIS RUTINAS'),
                        const SizedBox(width: 8),
                        _filterChip(_FilterType.community, 'COMUNIDAD'),
                      ],
                    ),
                  ),
                ),
              ),

              if ((state is WorkoutLoading ||
                      state is WorkoutInitial ||
                      state is SavingSetLog) &&
                  routines.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (routines.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  sliver: Builder(
                    builder: (context) {
                      final currentUserId =
                          (context.read<AuthBloc>().state as Authenticated)
                              .user
                              .id;
                      final filteredRoutines = routines.where((r) {
                        switch (_selectedFilter) {
                          case _FilterType.all:
                            return true;
                          case _FilterType.mine:
                            return r.creatorId == currentUserId;
                          case _FilterType.community:
                            return r.creatorId != currentUserId && r.isPublic;
                        }
                      }).toList();

                      if (filteredRoutines.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'No se encontraron rutinas en esta categoría',
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final routine = filteredRoutines[index];
                          final isMine = routine.creatorId == currentUserId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildRoutineCard(
                              context,
                              routine: routine,
                              isActive: false,
                              isMine: isMine,
                            ),
                          );
                        }, childCount: filteredRoutines.length),
                      );
                    },
                  ),
                )
              else if (state is WorkoutError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(state.message, style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                )
              else if (state is ManagementSuccess ||
                  state is WorkoutFinishedSuccess ||
                  state is SetLogSuccess)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.success,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        CircularProgressIndicator(color: AppColors.primary),
                      ],
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox.shrink()),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),

      // Botón Premium para Nueva Rutina
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.routineEditor);
        },
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
        label: Text(
          'CREAR PROPIA',
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
    required Routine routine,
    required bool isActive,
    required bool isMine,
  }) {
    return GlassContainer(
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
                  routine.name.toUpperCase(),
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
              _buildInfoTag(
                Icons.fitness_center_rounded,
                '${routine.exerciseCount} EJERCICIOS',
              ),
              const SizedBox(width: 12),
              _buildInfoTag(
                isMine ? Icons.person_rounded : Icons.public_rounded,
                isMine ? 'MI RUTINA' : (routine.creatorName ?? 'COMUNIDAD'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  // Pasar solo el ID para que coincida con el router
                  context.push(AppRoutes.routineEditor, extra: routine.id);
                },
                child: Text(
                  'DETALLES',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _onAssignRoutine(routine.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'ACTIVAR',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary.withValues(alpha: 0.7), size: 14),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(_FilterType type, String label) {
    final isSelected = _selectedFilter == type;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
