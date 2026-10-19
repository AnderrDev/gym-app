import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/routes/args/routing_args.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/injection_container.dart' show sl;
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/delete_day_dialog.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_day_card.dart';

/// Tile usado por el `RoutineEditorPage` para cada día: encapsula la
/// navegación al `DayEditorPage`, la confirmación de borrado y el dispatch
/// al `RoutineManagementBloc`.
class RoutineEditorDayCardTile extends StatelessWidget {
  const RoutineEditorDayCardTile({
    super.key,
    required this.index,
    required this.day,
    required this.activeRoutineId,
    this.isOwner = true,
  });

  final int index;
  final RoutineDay day;
  final String? activeRoutineId;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return RoutineDayCard(
      index: index,
      day: day,
      onTap: () => _openDayEditor(context),
      confirmDelete: isOwner ? () => _confirmDelete(context) : null,
      onDelete: isOwner ? () => _deleteDay(context) : null,
    );
  }

  /// Antes del diálogo (y del swipe): si el día tiene un entreno en curso no
  /// se borra. Rechazarlo después de que el `Dismissible` se descarte lo
  /// dejaría en el árbol.
  Future<bool> _confirmDelete(BuildContext context) async {
    final training = sl.isRegistered<ActiveSessionService>()
        ? sl<ActiveSessionService>().getContext()?.routineDayId
        : null;
    if (training == day.id) {
      AppSnackBar.warning(
        context,
        'Estás entrenando este día. Finaliza el entreno antes de borrarlo.',
      );
      return false;
    }
    return DeleteDayDialog.show(context, dayName: day.name);
  }

  Future<void> _openDayEditor(BuildContext context) async {
    final routineId = activeRoutineId;
    if (routineId == null) return;
    await pushDayEditor(
      context,
      DayEditorArgs(day: day, routineId: routineId, isOwner: isOwner),
    );
    // El editor del día tiene su propio bloc: al volver se recarga siempre.
    // Volver con el gesto del sistema no devuelve resultado aunque se hayan
    // guardado ejercicios.
    if (!context.mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    context.read<RoutineManagementBloc>().add(
      LoadRoutineForEditing(userId: authState.user.id, routineId: routineId),
    );
  }

  void _deleteDay(BuildContext context) {
    final routineId = activeRoutineId;
    if (routineId == null) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    context.read<RoutineManagementBloc>().add(
      DeleteDay(userId: authState.user.id, routineId: routineId, dayId: day.id),
    );
  }
}
