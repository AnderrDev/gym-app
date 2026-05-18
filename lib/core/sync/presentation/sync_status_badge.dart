import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/sync/presentation/sync_status_bloc.dart';

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
          child: _renderContent(state),
        );
      },
    );
  }

  Widget _renderContent(SyncStatusState state) {
    if (state.draining) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 6),
          Text('Sincronizando…'),
        ],
      );
    }
    final pending = state.pending;
    if (!state.isOnline && pending > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('$pending pendientes'),
        ],
      );
    }
    if (pending > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sync_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('$pending pendientes'),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
