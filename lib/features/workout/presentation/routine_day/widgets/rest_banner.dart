import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/rest_timer_button.dart';

/// Banner sticky de descanso. Aparece animado en el tope de la página activa
/// mientras el timer corre y se colapsa cuando termina/se salta.
class RestBanner extends StatelessWidget {
  const RestBanner({
    super.key,
    required this.snapshot,
    required this.onSkip,
    required this.onAdjust,
  });

  final ValueListenable<RestTimerSnapshot> snapshot;
  final VoidCallback onSkip;
  final void Function(int deltaSeconds) onAdjust;

  static String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RestTimerSnapshot>(
      valueListenable: snapshot,
      builder: (context, value, _) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: value.isResting
              ? _Body(
                  snapshot: value,
                  onSkip: onSkip,
                  onAdjust: onAdjust,
                  formattedTime: _formatTime(value.secondsRemaining),
                )
              : const SizedBox(width: double.infinity),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.snapshot,
    required this.onSkip,
    required this.onAdjust,
    required this.formattedTime,
  });

  final RestTimerSnapshot snapshot;
  final VoidCallback onSkip;
  final void Function(int) onAdjust;
  final String formattedTime;

  @override
  Widget build(BuildContext context) {
    final progress = snapshot.totalRestSeconds > 0
        ? snapshot.secondsRemaining / snapshot.totalRestSeconds
        : 0.0;
    return Container(
      width: double.infinity,
      color: context.colors.primary.withValues(alpha: 0.12),
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_rounded,
                size: 20,
                color: context.colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'DESCANSO',
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              Text(
                formattedTime,
                style: context.text.headlineMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: context.colors.primary.withValues(alpha: 0.18),
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _AdjustButton(
                label: '−15s',
                onTap: () {
                  HapticFeedback.selectionClick();
                  onAdjust(-15);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SkipButton(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSkip();
                  },
                ),
              ),
              const SizedBox(width: 8),
              _AdjustButton(
                label: '+15s',
                onTap: () {
                  HapticFeedback.selectionClick();
                  onAdjust(15);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  const _AdjustButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.colors.primary.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: context.colors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'SALTAR',
          style: context.text.labelMedium?.copyWith(
            color: context.colors.onPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
