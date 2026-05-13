import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/presentation/widgets/kinetic_button.dart';
import 'package:gym_flutter/core/routes/args/routing_args.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/delete_routine_dialog.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_day_card.dart';

class RoutineEditorPage extends StatefulWidget {
  final String? routineId;
  const RoutineEditorPage({super.key, this.routineId});

  @override
  State<RoutineEditorPage> createState() => _RoutineEditorPageState();
}

class _RoutineEditorPageState extends State<RoutineEditorPage> {
  late TextEditingController _nameController;
  bool _isInitialized = false;
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    if (widget.routineId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          context.read<RoutineManagementBloc>().add(
            LoadRoutineForEditing(
              userId: authState.user.id,
              routineId: widget.routineId!,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userId = (authState is Authenticated) ? authState.user.id : '';

        return BlocConsumer<RoutineManagementBloc, RoutineManagementState>(
          listenWhen: (p, c) =>
              p.submissionStatus != c.submissionStatus &&
              (c.submissionStatus ==
                      RoutineManagementSubmissionStatus.success ||
                  c.submissionStatus ==
                      RoutineManagementSubmissionStatus.failure),
          listener: (context, state) {
            if (state.submissionStatus ==
                RoutineManagementSubmissionStatus.success) {
              AppSnackBar.success(context, state.feedbackMessage ?? 'OK');
              context.read<RoutineManagementBloc>().add(
                const AcknowledgeFeedback(),
              );
            } else if (state.submissionStatus ==
                RoutineManagementSubmissionStatus.failure) {
              AppSnackBar.error(context, state.errorMessage ?? 'Error');
              context.read<RoutineManagementBloc>().add(
                const AcknowledgeFeedback(),
              );
            }
          },
          builder: (context, state) {
            if (!_isInitialized && state.editingRoutine != null) {
              _nameController.text = state.editingRoutine!.name;
              _isPublic = state.editingRoutine!.isPublic;
              _isInitialized = true;
            }
            // Días ordenados por day_of_week (ya no soporta reordenar).
            final days = List<RoutineDay>.from(state.editingDays)
              ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
            final isDirty = state.isDirty;
            final activeRoutineId =
                widget.routineId ?? state.editingRoutine?.id;

            return PopScope(
              canPop: !isDirty,
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop) return;
                final navigator = GoRouter.of(context);
                final shouldPop = await _confirmDiscard();
                if (!mounted) return;
                if (shouldPop) navigator.pop(true);
              },
              child: Scaffold(
                backgroundColor: AppColors.background,
                body: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 160,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () async {
                          if (!isDirty) {
                            context.pop();
                            return;
                          }
                          final navigator = GoRouter.of(context);
                          final shouldPop = await _confirmDiscard();
                          if (!mounted) return;
                          if (shouldPop) navigator.pop(true);
                        },
                      ),
                      actions: [
                        if (activeRoutineId != null)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                            ),
                            onPressed: () => _confirmDelete(userId),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: TextButton(
                            onPressed: () {
                              context.read<RoutineManagementBloc>().add(
                                SaveRoutine(
                                  userId: userId,
                                  id: activeRoutineId,
                                  name: _nameController.text,
                                  isPublic: _isPublic,
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
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        title: Text(
                          _nameController.text.isEmpty
                              ? 'NUEVA RUTINA'
                              : _nameController.text.toUpperCase(),
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 16,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        background: Container(
                          padding: const EdgeInsets.fromLTRB(24, 70, 24, 0),
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
                              fontSize: 28,
                              letterSpacing: -1,
                            ),
                            decoration: InputDecoration(
                              hintText: 'NOMBRE DE RUTINA',
                              hintStyle: AppTextStyles.heading1.copyWith(
                                color: AppColors.textDisabled,
                                fontSize: 28,
                                letterSpacing: -1,
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
                          Spacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ESTRUCTURA SEMANAL',
                              style: AppTextStyles.label.copyWith(
                                letterSpacing: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${days.length} DÍAS',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'HACER PÚBLICA',
                              style: AppTextStyles.label.copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                                color: _isPublic
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            subtitle: Text(
                              'Otros usuarios podrán ver y usar esta rutina',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                              ),
                            ),
                            value: _isPublic,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() => _isPublic = val);
                              HapticFeedback.selectionClick();
                              context
                                  .read<RoutineManagementBloc>()
                                  .add(const MarkRoutineDirty());
                            },
                          ),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: Spacing.lg),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildDayCard(index, days[index], activeRoutineId),
                          childCount: days.length,
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.lgPlus,
                        ),
                        child: KineticButton(
                          label: 'AÑADIR DÍA',
                          icon: Icons.add_circle_outline_rounded,
                          onTap: () => _onAddDayPressed(
                            userId,
                            activeRoutineId,
                            days.length,
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onAddDayPressed(String userId, String? activeRoutineId, int dayCount) {
    HapticFeedback.heavyImpact();
    if (activeRoutineId == null) {
      // Aún no se ha guardado la rutina; intentamos guardarla con el nombre actual.
      if (_nameController.text.trim().isEmpty) {
        AppSnackBar.warning(context, 'Pon un nombre y pulsa GUARDAR primero');
        return;
      }
      AppSnackBar.info(
        context,
        'Guardando la rutina antes de añadir un día...',
      );
      context.read<RoutineManagementBloc>().add(
        SaveRoutine(
          userId: userId,
          name: _nameController.text,
          isPublic: _isPublic,
        ),
      );
      return;
    }

    context.read<RoutineManagementBloc>().add(
      SaveDay(
        userId: userId,
        routineId: activeRoutineId,
        day: RoutineDay(
          id: '',
          routineId: activeRoutineId,
          name: 'Nuevo Día',
          dayOfWeek: dayCount + 1,
          exercises: const [],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String userId) async {
    final bloc = context.read<RoutineManagementBloc>();
    final routineId =
        widget.routineId ?? bloc.state.editingRoutine?.id;
    if (routineId == null) return;
    final confirmed = await DeleteRoutineDialog.show(context);
    if (confirmed != true) return;
    bloc.add(DeleteRoutine(userId: userId, routineId: routineId));
  }

  Widget _buildDayCard(int index, RoutineDay day, String? activeRoutineId) {
    return RoutineDayCard(
      index: index,
      day: day,
      onTap: () async {
        if (activeRoutineId == null) return;
        final changed = await pushDayEditor(
          context,
          DayEditorArgs(day: day, routineId: activeRoutineId),
        );
        if (!mounted || changed != true) return;
        final authState = context.read<AuthBloc>().state;
        if (authState is! Authenticated) return;
        context.read<RoutineManagementBloc>().add(
          LoadRoutineForEditing(
            userId: authState.user.id,
            routineId: activeRoutineId,
          ),
        );
      },
    );
  }
}
