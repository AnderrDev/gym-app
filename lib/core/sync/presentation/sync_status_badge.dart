import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/sync/presentation/sync_status_bloc.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';

/// Badge compacto que comunica al usuario el estado del sync.
///
/// Reglas visuales (Spanish):
/// - `pending == 0 && online`: oculto.
/// - `draining`: spinner pequeño + "Sincronizando…".
/// - `!online && pending > 0`: icono nube-tachada + "$pending pendientes".
/// - cualquier otro caso con `pending > 0`: "$pending pendientes".
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, this.padding = const EdgeInsets.symmetric(horizontal: 8)});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncStatusBloc, SyncStatusState>(
      builder: (context, state) {
        if (state.pending == 0 && state.isOnline && !state.draining) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: padding,
          child: _renderContent(context, state),
        );
      },
    );
  }

  Widget _renderContent(BuildContext context, SyncStatusState state) {
    if (state.draining) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSpinner(size: 14, color: context.colors.primary),
          const SizedBox(width: 6),
          const Text('Sincronizando…'),
        ],
      );
    }
    final pending = state.pending;
    if (!state.isOnline && pending > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: context.colors.textSecondary),
          const SizedBox(width: 6),
          Text('$pending pendientes'),
        ],
      );
    }
    if (pending > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync_rounded, size: 16, color: context.colors.textSecondary),
          const SizedBox(width: 6),
          Text('$pending pendientes'),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
