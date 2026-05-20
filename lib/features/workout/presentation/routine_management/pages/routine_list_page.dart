import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/ui/adaptive/adaptive_scroll_physics.dart';
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
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_list_card.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_list_empty_filter.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_list_error_center.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_list_filter_chips.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_list_search_bar.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_list_skeleton.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_list_summary_header.dart';

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

  void _onForkRoutine(String routineId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      HapticFeedback.mediumImpact();
      context.read<RoutineManagementBloc>().add(
        ForkRoutine(
          userId: authState.user.id,
          sourceRoutineId: routineId,
        ),
      );
    }
  }

  void _refreshRoutines() {
    if (!mounted) return;
    _loadRoutines();
  }

  Widget _buildAppBar() {
    return SliverAppBar(
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
    );
  }

  Widget _buildCreateFab() {
    return FloatingActionButton.extended(
      onPressed: () async {
        unawaited(HapticFeedback.mediumImpact());
        final changed = await pushRoutineEditor(context);
        if (changed == true) _refreshRoutines();
      },
      elevation: 0,
      highlightElevation: 0,
      backgroundColor: AppColors.primary,
      icon:
          const Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 24),
      label: Text(
        'CREAR PROPIA',
        style: AppTextStyles.label.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  void _onSubmissionFeedback(
    BuildContext context,
    RoutineManagementState state,
  ) {
    if (state.submissionStatus == RoutineManagementSubmissionStatus.success) {
      AppSnackBar.success(context, state.feedbackMessage ?? 'OK');
      // Tras un fork desde la lista: abrimos el editor de la copia recién
      // creada para que el usuario pueda renombrar/ajustar inmediatamente.
      if (state.lastAction == RoutineManagementAction.forkRoutine) {
        final newId = state.lastForkedRoutineId;
        context.read<RoutineManagementBloc>().add(const AcknowledgeFeedback());
        if (newId != null) {
          unawaited(pushRoutineEditor(context, routineId: newId)
              .then((_) => _refreshRoutines()));
        }
        return;
      }
      // Solo regresamos al dashboard tras un assign exitoso.
      final shouldPop =
          state.lastAction == RoutineManagementAction.assignRoutine;
      context.read<RoutineManagementBloc>().add(const AcknowledgeFeedback());
      if (shouldPop) {
        // `pop` falla con GoError si la página vive como branch del shell.
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go(AppRoutes.dashboard);
        }
      }
    } else if (state.submissionStatus ==
        RoutineManagementSubmissionStatus.failure) {
      AppSnackBar.error(context, state.errorMessage ?? 'Error');
      context.read<RoutineManagementBloc>().add(const AcknowledgeFeedback());
    }
  }

  Widget _buildFilteredList(
    BuildContext context,
    RoutineManagementState state,
  ) {
    final currentUserId =
        (context.read<AuthBloc>().state as Authenticated).user.id;
    final query = _searchQuery.trim().toLowerCase();
    final filteredRoutines = state.routines.where((r) {
      final passesFilter = switch (_selectedFilter) {
        RoutineListFilter.all => true,
        RoutineListFilter.mine => r.creatorId == currentUserId,
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
        child: RoutineListEmptyFilter(filter: _selectedFilter),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final routine = filteredRoutines[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.lgPlus),
            child: RoutineListCard(
              routine: routine,
              isActive: state.activeRoutineId == routine.id,
              isMine: routine.creatorId == currentUserId,
              onActivate: _onAssignRoutine,
              onEdited: _refreshRoutines,
              onFork: (routine.creatorId != currentUserId && routine.isPublic)
                  ? _onForkRoutine
                  : null,
            ),
          );
        },
        childCount: filteredRoutines.length,
      ),
    );
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
        listener: _onSubmissionFeedback,
        builder: (context, state) {
          final routines = state.routines;

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: _onRefresh,
            child: CustomScrollView(
            physics: AdaptiveScrollPhysics.preferred,
            slivers: [
              _buildAppBar(),

              // Summary header. `firstWhereOrNull` evita el orElse y rompe
              // covarianza con `RoutineModel`; null = sin rutina activa.
              SliverToBoxAdapter(
                child: RoutineListSummaryHeader(
                  totalCount: routines.length,
                  activeRoutine: state.activeRoutineId == null
                      ? null
                      : routines.firstWhereOrNull(
                          (r) => r.id == state.activeRoutineId,
                        ),
                ),
              ),

              // ── Buscador ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: RoutineListSearchBar(
                  controller: _searchController,
                  query: _searchQuery,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),

              // ── Filtros ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  // `md` arriba y abajo: separa visualmente el buscador y el
                  // primer card sin amontonar.
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lgPlus,
                    Spacing.md,
                    Spacing.lgPlus,
                    Spacing.md,
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
                  // Vertical 0 acá; cada card ya trae `bottom: lgPlus`.
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lgPlus,
                    0,
                    Spacing.lgPlus,
                    0,
                  ),
                  sliver: Builder(
                    builder: (context) => _buildFilteredList(context, state),
                  ),
                )
              else if (state.status == RoutineManagementStatus.failure)
                SliverFillRemaining(
                  child: RoutineListErrorCenter(
                    message: state.errorMessage ?? 'Error',
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox.shrink()),

              // Buffer abajo: el FAB ocupa ~56px de alto, dejamos 96 total
              // para que la última card no quede tapada sin sobrar tanto.
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
          );
        },
      ),

      floatingActionButton: _buildCreateFab(),
    );
  }
}

