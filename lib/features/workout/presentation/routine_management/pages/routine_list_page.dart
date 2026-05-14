import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/routes/app_routes.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadRoutines();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<RoutineManagementBloc>();
    _loadRoutines();
    // Esperamos a que el bloc deje de estar loading para que el indicator
    // se cierre cuando los datos lleguen y no instantáneamente.
    await bloc.stream.firstWhere((s) => !s.isLoading).timeout(
          const Duration(seconds: 8),
          onTimeout: () => bloc.state,
        );
  }

  void _loadRoutines() {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.id : null;
    context.read<RoutineManagementBloc>().add(
      LoadAllRoutines(userId: userId),
    );
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
    _loadRoutines();
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
              // `pop` falla con GoError si la página vive como branch
              // del shell (sin stack para popear). En ese caso navegamos
              // explícitamente al dashboard.
              if (context.canPop()) {
                context.pop(true);
              } else {
                context.go(AppRoutes.dashboard);
              }
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

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: _onRefresh,
            child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── App Bar plana ─────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.background,
                surfaceTintColor: AppColors.background,
                elevation: 0,
                centerTitle: false,
                titleSpacing: Spacing.lgPlus,
                iconTheme: const IconThemeData(color: AppColors.textPrimary),
                title: Text(
                  'MIS RUTINAS',
                  style: AppTextStyles.heading2.copyWith(
                    letterSpacing: 1.8,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              // ── Summary header ────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SummaryHeader(
                  totalCount: routines.length,
                  activeRoutine: state.activeRoutineId == null
                      ? null
                      : routines.firstWhere(
                          (r) => r.id == state.activeRoutineId,
                          orElse: () => routines.first,
                        ),
                ),
              ),

              // ── Buscador ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lgPlus,
                    Spacing.sm,
                    Spacing.lgPlus,
                    0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.divider.withValues(alpha: 0.5),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        icon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textDisabled,
                          size: 20,
                        ),
                        hintText: 'Buscar rutina por nombre…',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDisabled,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.textDisabled,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                      ),
                    ),
                  ),
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
                      final query = _searchQuery.trim().toLowerCase();
                      final filteredRoutines = routines.where((r) {
                        final passesFilter = switch (_selectedFilter) {
                          RoutineListFilter.all => true,
                          RoutineListFilter.mine =>
                            r.creatorId == currentUserId,
                          RoutineListFilter.community =>
                            r.creatorId != currentUserId && r.isPublic,
                        };
                        if (!passesFilter) return false;
                        if (query.isEmpty) return true;
                        return r.name.toLowerCase().contains(query);
                      }).toList();

                      if (filteredRoutines.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyFilter(filter: _selectedFilter),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final routine = filteredRoutines[index];
                          final isMine = routine.creatorId == currentUserId;
                          final isActive =
                              state.activeRoutineId == routine.id;
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: Spacing.lgPlus,
                            ),
                            child: RoutineListCard(
                              routine: routine,
                              isActive: isActive,
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
          ),
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

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter({required this.filter});

  final RoutineListFilter filter;

  String get _title => switch (filter) {
    RoutineListFilter.all => 'Sin rutinas',
    RoutineListFilter.mine => 'No tenés rutinas propias',
    RoutineListFilter.community => 'Sin rutinas de la comunidad',
  };

  String get _subtitle => switch (filter) {
    RoutineListFilter.all =>
      'Creá una rutina propia o explorá el catálogo de la comunidad.',
    RoutineListFilter.mine =>
      'Creá tu primera rutina y armala día por día.',
    RoutineListFilter.community =>
      'Cuando otros usuarios compartan rutinas, aparecerán acá.',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            _title,
            style: AppTextStyles.heading2.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header con resumen visible apenas se entra: "Tenés X rutinas · Activa: Y".
/// Si no hay rutina activa el subtítulo cambia al CTA "Activá una para
/// empezar".
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.totalCount, this.activeRoutine});

  final int totalCount;
  final Routine? activeRoutine;

  @override
  Widget build(BuildContext context) {
    final hasActive = activeRoutine != null;
    final accent = hasActive
        ? RoutineColor.accentFor(activeRoutine!.name)
        : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lgPlus,
        0,
        Spacing.lgPlus,
        Spacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lgPlus,
          Spacing.lg,
          Spacing.lgPlus,
          Spacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: hasActive ? 0.35 : 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasActive ? Icons.bolt_rounded : Icons.list_alt_rounded,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    totalCount == 0
                        ? 'Aún no tenés rutinas'
                        : '$totalCount ${totalCount == 1 ? "rutina" : "rutinas"} disponibles',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasActive
                        ? 'Activa: ${activeRoutine!.name}'
                        : 'Activá una para empezar a entrenar',
                    style: AppTextStyles.label.copyWith(
                      color: hasActive
                          ? accent
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
