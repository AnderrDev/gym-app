import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

/// Snapshot inmutable del estado del timer de descanso. Lo entrega el
/// `ValueNotifier` del padre (`_RoutineDayPageState`) para que solo este botón
/// se rebuildee cada segundo en lugar del scaffold completo.
@immutable
class RestTimerSnapshot {
  const RestTimerSnapshot({
    required this.isResting,
    required this.secondsRemaining,
    required this.totalRestSeconds,
  });

  const RestTimerSnapshot.idle()
    : isResting = false,
      secondsRemaining = 0,
      totalRestSeconds = 60;

  final bool isResting;
  final int secondsRemaining;
  final int totalRestSeconds;
}

class RestTimerButton extends StatelessWidget {
  const RestTimerButton({
    super.key,
    required this.snapshot,
    required this.onTap,
  });

  final ValueListenable<RestTimerSnapshot> snapshot;
  final VoidCallback onTap;

  static String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ValueListenableBuilder<RestTimerSnapshot>(
        valueListenable: snapshot,
        builder: (context, value, _) {
          final progress = value.totalRestSeconds > 0
              ? value.secondsRemaining / value.totalRestSeconds
              : 0.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  value: value.isResting ? progress : 0,
                  strokeWidth: 3,
                  backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                  color: context.colors.primary,
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: value.isResting
                      ? context.colors.primary
                      : context.colors.surfaceHighlight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  value.isResting
                      ? Icons.timer_rounded
                      : Icons.play_arrow_rounded,
                  color: value.isResting ? context.colors.onPrimary : context.colors.textPrimary,
                  size: 20,
                ),
              ),
              if (value.isResting)
                Positioned(
                  bottom: -15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatTime(value.secondsRemaining),
                      style: context.text.labelMedium?.copyWith(
                        color: context.colors.onPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
