import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/routes/args/routing_args.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
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
  });

  final int index;
  final RoutineDay day;
  final String? activeRoutineId;

  @override
  Widget build(BuildContext context) {
    return RoutineDayCard(
      index: index,
      day: day,
      onTap: () => _openDayEditor(context),
      confirmDelete: () => DeleteDayDialog.show(context, dayName: day.name),
      onDelete: () => _deleteDay(context),
    );
  }

  Future<void> _openDayEditor(BuildContext context) async {
    final routineId = activeRoutineId;
    if (routineId == null) return;
    final changed = await pushDayEditor(
      context,
      DayEditorArgs(day: day, routineId: routineId),
    );
    if (!context.mounted || changed != true) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    context.read<RoutineManagementBloc>().add(
      LoadRoutineForEditing(
        userId: authState.user.id,
        routineId: routineId,
      ),
    );
  }

  void _deleteDay(BuildContext context) {
    final routineId = activeRoutineId;
    if (routineId == null) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    context.read<RoutineManagementBloc>().add(
      DeleteDay(
        userId: authState.user.id,
        routineId: routineId,
        dayId: day.id,
      ),
    );
  }
}
