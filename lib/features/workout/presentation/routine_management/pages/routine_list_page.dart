import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_list_card.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_list_filter_chips.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_list_skeleton.dart';

class RoutineListPage extends StatefulWidget {
  const RoutineListPage({super.key});

  @override
  State<RoutineListPage> createState() => _RoutineListPageState();
}

class _RoutineListPageState extends State<RoutineListPage> {
  RoutineListFilter _selectedFilter = RoutineListFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RoutineManagementBloc>().add(const LoadAllRoutines());
    });
  }

  void _onAssignRoutine(String routineId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      HapticFeedback.heavyImpact();
      context.read<RoutineManagementBloc>().add(
        AssignRoutineToUser(userId: authState.user.id, routineId: routineId),
      );
    }
  }

  void _refreshRoutines() {
    if (!mounted) return;
    context.read<RoutineManagementBloc>().add(const LoadAllRoutines());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<RoutineManagementBloc, RoutineManagementState>(
        listenWhen: (p, c) =>
            p.submissionStatus != c.submissionStatus &&
            (c.submissionStatus == RoutineManagementSubmissionStatus.success ||
                c.submissionStatus ==
                    RoutineManagementSubmissionStatus.failure),
        listener: (context, state) {
          if (state.submissionStatus ==
              RoutineManagementSubmissionStatus.success) {
            AppSnackBar.success(context, state.feedbackMessage ?? 'OK');
            // Solo regresamos al dashboard tras un assign exitoso; el resto
            // de mutaciones (delete) actualizan la lista in-situ.
            final shouldPop =
                state.lastAction == RoutineManagementAction.assignRoutine;
            context.read<RoutineManagementBloc>().add(
              const AcknowledgeFeedback(),
            );
            if (shouldPop) {
              context.pop(true);
            }
          } else if (state.submissionStatus ==
              RoutineManagementSubmissionStatus.failure) {
            AppSnackBar.error(context, state.errorMessage ?? 'Error');
            context.read<RoutineManagementBloc>().add(
              const AcknowledgeFeedback(),
            );
          }
        },
        builder: (context, state) {
          final routines = state.routines;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar Premium ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: AppColors.textPrimary),
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
                    horizontal: Spacing.lgPlus,
                    vertical: Spacing.sm,
                  ),
                  child: RoutineListFilterChips(
                    selected: _selectedFilter,
                    onChanged: (f) => setState(() => _selectedFilter = f),
                  ),
                ),
              ),

              if (state.isLoading && routines.isEmpty)
                const SliverFillRemaining(child: RoutineListSkeleton())
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
                          case RoutineListFilter.all:
                            return true;
                          case RoutineListFilter.mine:
                            return r.creatorId == currentUserId;
                          case RoutineListFilter.community:
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
                            padding: const EdgeInsets.only(
                              bottom: Spacing.lgPlus,
                            ),
                            child: RoutineListCard(
                              routine: routine,
                              isActive: false,
                              isMine: isMine,
                              onActivate: _onAssignRoutine,
                              onEdited: _refreshRoutines,
                            ),
                          );
                        }, childCount: filteredRoutines.length),
                      );
                    },
                  ),
                )
              else if (state.status == RoutineManagementStatus.failure)
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
                        Text(
                          state.errorMessage ?? 'Error',
                          style: AppTextStyles.bodyMedium,
                        ),
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
        onPressed: () async {
          unawaited(HapticFeedback.mediumImpact());
          final changed = await pushRoutineEditor(context);
          if (changed == true) _refreshRoutines();
        },
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 24),
        label: Text(
          'CREAR PROPIA',
          style: AppTextStyles.label.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
