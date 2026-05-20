import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/ui/adaptive/adaptive_scroll_physics.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/presentation/widgets/kinetic_button.dart';
import 'package:gym_flutter/core/routes/app_routes.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/ui/feedback/discard_changes_dialog.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/delete_routine_dialog.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_editor_app_bar.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_editor_day_card_tile.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_editor_week_header.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_info_card.dart';

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

  bool _isSubmissionTerminal(
    RoutineManagementState p,
    RoutineManagementState c,
  ) =>
      p.submissionStatus != c.submissionStatus &&
      (c.submissionStatus == RoutineManagementSubmissionStatus.success ||
          c.submissionStatus == RoutineManagementSubmissionStatus.failure);

  void _onSubmissionFeedback(
    BuildContext context,
    RoutineManagementState state,
    String userId,
  ) {
    final bloc = context.read<RoutineManagementBloc>();
    if (state.submissionStatus == RoutineManagementSubmissionStatus.success) {
      // Caso especial: fork. Antes de hacer ack capturamos el id de la nueva
      // rutina para navegar a su editor. Sin la navegación quedaríamos en la
      // vista previa de la rutina ajena después del fork — confuso.
      if (state.lastAction == RoutineManagementAction.forkRoutine) {
        final newId = state.lastForkedRoutineId;
        AppSnackBar.success(context, state.feedbackMessage ?? 'OK');
        bloc.add(const AcknowledgeFeedback());
        if (newId != null) {
          // `pushReplacement` reemplaza el stack actual del editor: ya no
          // tiene sentido volver a la vista previa de la ajena.
          GoRouter.of(context).pushReplacement(
            AppRoutes.routineEditor,
            extra: newId,
          );
        }
        return;
      }
      // Si encadenamos "AÑADIR DÍA" sobre una rutina nueva, silenciamos el
      // toast del SaveRoutine — el siguiente success (SaveDay) lo mostrará.
      final isChainedSave = _addDayAfterSave &&
          state.lastAction == RoutineManagementAction.saveRoutine;
      if (!isChainedSave) {
        AppSnackBar.success(context, state.feedbackMessage ?? 'OK');
      }
      bloc.add(const AcknowledgeFeedback());
      if (isChainedSave && state.editingRoutine != null) {
        _addDayAfterSave = false;
        final routine = state.editingRoutine!;
        bloc.add(
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
      bloc.add(const AcknowledgeFeedback());
      // Si el SaveRoutine inicial falló, descartamos la intención de añadir
      // día — el usuario verá el error y volverá a intentarlo.
      if (_addDayAfterSave) _addDayAfterSave = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userId = (authState is Authenticated) ? authState.user.id : '';

        return BlocConsumer<RoutineManagementBloc, RoutineManagementState>(
          listenWhen: _isSubmissionTerminal,
          listener: (context, state) =>
              _onSubmissionFeedback(context, state, userId),
          builder: (context, state) {
            if (!_isInitialized && state.editingRoutine != null) {
              _nameController.text = state.editingRoutine!.name;
              _isPublic = state.editingRoutine!.isPublic;
              _isInitialized = true;
            }
            // Días ordenados por day_of_week (no se reordena).
            final days = List<RoutineDay>.from(state.editingDays)
              ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
            final activeRoutineId =
                widget.routineId ?? state.editingRoutine?.id;

            // `isOwner` se decide comparando el creator de la rutina cargada
            // con el usuario actual. Sin routineId estamos creando nueva, así
            // que es "owner" por definición. Mientras no haya llegado el
            // `editingRoutine` consideramos owner=true para no flashear UI de
            // read-only en el primer frame y luego cambiar.
            final loadedCreatorId = state.editingRoutine?.creatorId;
            final isOwner = widget.routineId == null ||
                loadedCreatorId == null ||
                loadedCreatorId == userId;
            final isDirty = state.isDirty && isOwner;

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
                  physics: AdaptiveScrollPhysics.preferred,
                  slivers: [
                    RoutineEditorAppBar(
                      activeRoutineId: activeRoutineId,
                      isDirty: isDirty,
                      isOwner: isOwner,
                      onClose: () => _onClosePressed(isDirty),
                      onDelete: () => _confirmDelete(userId),
                      onSave: () => _onSavePressed(userId, activeRoutineId),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Spacing.lgPlus,
                          Spacing.sm,
                          Spacing.lgPlus,
                          Spacing.lg,
                        ),
                        child: RoutineInfoCard(
                          nameController: _nameController,
                          isPublic: _isPublic,
                          readOnly: !isOwner,
                          creatorName: state.editingRoutine?.creatorName,
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
                    if (!isOwner && activeRoutineId != null)
                      SliverToBoxAdapter(
                        child: _ForkBanner(
                          submitting: state.isSubmitting,
                          onTap: () => _onForkPressed(userId, activeRoutineId),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: RoutineEditorWeekHeader(dayCount: days.length),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.lgPlus,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => RoutineEditorDayCardTile(
                            index: index,
                            day: days[index],
                            activeRoutineId: activeRoutineId,
                            isOwner: isOwner,
                          ),
                          childCount: days.length,
                        ),
                      ),
                    ),
                    if (isOwner)
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

  void _onSavePressed(String userId, String? activeRoutineId) {
    context.read<RoutineManagementBloc>().add(
      SaveRoutine(
        userId: userId,
        id: activeRoutineId,
        name: _nameController.text,
        isPublic: _isPublic,
      ),
    );
  }

  Future<void> _onClosePressed(bool isDirty) async {
    if (!isDirty) {
      context.pop();
      return;
    }
    final navigator = GoRouter.of(context);
    final shouldPop = await _confirmDiscard();
    if (!mounted) return;
    if (shouldPop) navigator.pop(true);
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
    final routineId = widget.routineId ?? bloc.state.editingRoutine?.id;
    if (routineId == null) return;
    final confirmed = await DeleteRoutineDialog.show(context);
    if (confirmed != true) return;
    bloc.add(DeleteRoutine(userId: userId, routineId: routineId));
  }

  void _onForkPressed(String userId, String sourceRoutineId) {
    HapticFeedback.mediumImpact();
    context.read<RoutineManagementBloc>().add(
      ForkRoutine(userId: userId, sourceRoutineId: sourceRoutineId),
    );
  }

}

/// Banner sticky que aparece cuando la rutina abierta no pertenece al
/// usuario. CTA: "CREAR MI COPIA" → dispara `ForkRoutine` y navega al
/// editor de la nueva (privada) rutina.
class _ForkBanner extends StatelessWidget {
  const _ForkBanner({required this.submitting, required this.onTap});

  final bool submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lgPlus,
        0,
        Spacing.lgPlus,
        Spacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RUTINA AJENA',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No podés editarla. Creá tu copia para personalizarla.',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            TextButton(
              onPressed: submitting ? null : onTap,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.4),
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      'CREAR MI COPIA',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
