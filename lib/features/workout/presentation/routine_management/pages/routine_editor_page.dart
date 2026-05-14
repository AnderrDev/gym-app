import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/presentation/widgets/kinetic_button.dart';
import 'package:gym_flutter/core/routes/args/routing_args.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/ui/feedback/discard_changes_dialog.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/delete_routine_dialog.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_day_card.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/section_header.dart';

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
  // Flag para encadenar SaveDay después de SaveRoutine cuando el usuario
  // toca AÑADIR DÍA en una rutina aún no guardada. Se resetea al consumirse.
  bool _addDayAfterSave = false;

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

  Future<bool> _confirmDiscard() => DiscardChangesDialog.show(context);

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
              // Si veníamos de un "AÑADIR DÍA" sobre una rutina nueva, la
              // primera success es la del SaveRoutine: encadenamos SaveDay
              // ya con el id real del state.
              if (_addDayAfterSave &&
                  state.lastAction == RoutineManagementAction.saveRoutine &&
                  state.editingRoutine != null) {
                _addDayAfterSave = false;
                final routine = state.editingRoutine!;
                context.read<RoutineManagementBloc>().add(
                  SaveDay(
                    userId: userId,
                    routineId: routine.id,
                    day: RoutineDay(
                      id: '',
                      routineId: routine.id,
                      name: 'Nuevo Día',
                      dayOfWeek: state.editingDays.length + 1,
                      exercises: const [],
                    ),
                  ),
                );
              }
            } else if (state.submissionStatus ==
                RoutineManagementSubmissionStatus.failure) {
              AppSnackBar.error(context, state.errorMessage ?? 'Error');
              context.read<RoutineManagementBloc>().add(
                const AcknowledgeFeedback(),
              );
              // Si el SaveRoutine inicial falló, descartamos la intención de
              // añadir día — el usuario verá el error y volverá a intentarlo.
              if (_addDayAfterSave) _addDayAfterSave = false;
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
                      pinned: true,
                      titleSpacing: 0,
                      backgroundColor: AppColors.background,
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
                      title: Text(
                        activeRoutineId == null ? 'Nueva rutina' : 'Editar rutina',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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
                            onPressed: isDirty
                                ? () {
                                    context.read<RoutineManagementBloc>().add(
                                      SaveRoutine(
                                        userId: userId,
                                        id: activeRoutineId,
                                        name: _nameController.text,
                                        isPublic: _isPublic,
                                      ),
                                    );
                                  }
                                : null,
                            child: Text(
                              'GUARDAR',
                              style: AppTextStyles.label.copyWith(
                                color: isDirty
                                    ? AppColors.primary
                                    : AppColors.textSecondary
                                        .withValues(alpha: 0.5),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Card unificado: identidad + nombre + switch público.
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Spacing.lgPlus,
                          Spacing.sm,
                          Spacing.lgPlus,
                          Spacing.lg,
                        ),
                        child: _RoutineInfoCard(
                          nameController: _nameController,
                          isPublic: _isPublic,
                          onNameChanged: () => context
                              .read<RoutineManagementBloc>()
                              .add(const MarkRoutineDirty()),
                          onPublicChanged: (val) {
                            setState(() => _isPublic = val);
                            HapticFeedback.selectionClick();
                            context
                                .read<RoutineManagementBloc>()
                                .add(const MarkRoutineDirty());
                          },
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Spacing.lgPlus,
                          Spacing.sm,
                          Spacing.lgPlus,
                          Spacing.md,
                        ),
                        child: SectionHeader(
                          label: 'Estructura semanal',
                          trailing: Text(
                            '${days.length} ${days.length == 1 ? "DÍA" : "DÍAS"}',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.lgPlus,
                      ),
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
                        padding: const EdgeInsets.fromLTRB(
                          Spacing.lgPlus,
                          Spacing.sm,
                          Spacing.lgPlus,
                          Spacing.sm,
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
      // Aún no existe la rutina: la guardamos y dejamos marcado el flag.
      // El listener encadenará SaveDay cuando reciba la success del SaveRoutine.
      if (_nameController.text.trim().isEmpty) {
        AppSnackBar.warning(context, 'Pon un nombre y pulsa GUARDAR primero');
        return;
      }
      _addDayAfterSave = true;
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
      confirmDelete: () => _confirmDeleteDay(day),
      onDelete: () {
        if (activeRoutineId == null) return;
        final authState = context.read<AuthBloc>().state;
        if (authState is! Authenticated) return;
        context.read<RoutineManagementBloc>().add(
          DeleteDay(
            userId: authState.user.id,
            routineId: activeRoutineId,
            dayId: day.id,
          ),
        );
      },
    );
  }

  Future<bool> _confirmDeleteDay(RoutineDay day) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Eliminar día?', style: AppTextStyles.heading2),
        content: Text(
          'Se borrará "${day.name}" y todos sus ejercicios.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCELAR',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'ELIMINAR',
              style: AppTextStyles.label.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return res ?? false;
  }
}

/// Card de información de la rutina: avatar de color (acento por nombre),
/// input grande del nombre, switch público con descripción corta.
class _RoutineInfoCard extends StatefulWidget {
  const _RoutineInfoCard({
    required this.nameController,
    required this.isPublic,
    required this.onNameChanged,
    required this.onPublicChanged,
  });

  final TextEditingController nameController;
  final bool isPublic;
  final VoidCallback onNameChanged;
  final ValueChanged<bool> onPublicChanged;

  @override
  State<_RoutineInfoCard> createState() => _RoutineInfoCardState();
}

class _RoutineInfoCardState extends State<_RoutineInfoCard> {
  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(_onName);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_onName);
    super.dispose();
  }

  void _onName() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final accent = RoutineColor.accentFor(widget.nameController.text);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: TextField(
                  controller: widget.nameController,
                  onChanged: (_) => widget.onNameChanged(),
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nombre de la rutina',
                    hintStyle: AppTextStyles.heading1.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 22,
                      letterSpacing: -0.3,
                    ),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isPublic ? 'PÚBLICA' : 'PRIVADA',
                      style: AppTextStyles.label.copyWith(
                        color: widget.isPublic
                            ? accent
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      widget.isPublic
                          ? 'Visible para toda la comunidad'
                          : 'Solo vos podés usarla',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.isPublic,
                activeThumbColor: accent,
                onChanged: widget.onPublicChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
