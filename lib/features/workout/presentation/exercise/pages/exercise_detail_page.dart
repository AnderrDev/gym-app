import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_scroll_physics.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_detail.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_detail/exercise_detail_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_detail/exercise_detail_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_detail/exercise_detail_state.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_info_chips.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_markdown_lite.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_media_hero.dart';

/// Pantalla fullscreen con el detalle de un ejercicio del catálogo:
/// hero visual (animación/imagen), chips de metadata, instrucciones y
/// consejos (markdown-lite), CTA al video externo si existe.
class ExerciseDetailPage extends StatefulWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<ExerciseDetailBloc>()
          .add(LoadExerciseDetail(widget.exerciseId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExerciseDetailBloc, ExerciseDetailState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              tooltip: 'Volver',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              state.detail?.name ?? 'Detalle',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ExerciseDetailState state) {
    if (state.isLoading || state.status == ExerciseDetailStatus.initial) {
      return const Center(child: AppSpinner.large());
    }
    if (state.status == ExerciseDetailStatus.failure) {
      return _ErrorView(
        message: state.errorMessage ?? 'Error',
        onRetry: () => context
            .read<ExerciseDetailBloc>()
            .add(LoadExerciseDetail(widget.exerciseId)),
      );
    }
    final detail = state.detail;
    if (detail == null) {
      return const _ErrorView(message: 'Ejercicio no encontrado');
    }
    return _Content(detail: detail);
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.detail});

  final ExerciseDetail detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: AdaptiveScrollPhysics.preferred,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lgPlus,
        Spacing.sm,
        Spacing.lgPlus,
        Spacing.xxl,
      ),
      children: [
        ExerciseMediaHero(
          muscleGroup: detail.muscleGroup,
          imageUrl: detail.imageUrl,
          animationUrl: detail.animationUrl,
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          detail.name,
          style: AppTextStyles.heading1.copyWith(fontSize: 26),
        ),
        if (detail.description != null && detail.description!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              detail.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        const SizedBox(height: Spacing.md),
        ExerciseInfoChips(
          muscleGroup: detail.muscleGroup,
          equipment: detail.equipment,
          difficulty: detail.difficulty,
        ),
        if (detail.videoUrl != null && detail.videoUrl!.trim().isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          _VideoCTA(url: detail.videoUrl!),
        ],
        if (detail.instructions != null &&
            detail.instructions!.trim().isNotEmpty) ...[
          const SizedBox(height: Spacing.xl),
          const _SectionHeader(
            icon: Icons.list_alt_rounded,
            label: 'CÓMO HACERLO',
          ),
          const SizedBox(height: Spacing.md),
          ExerciseMarkdownLite(detail.instructions!),
        ],
        if (detail.tips != null && detail.tips!.trim().isNotEmpty) ...[
          const SizedBox(height: Spacing.xl),
          _SectionHeader(
            icon: Icons.lightbulb_outline_rounded,
            label: 'CONSEJOS',
            accent: context.colors.warning,
          ),
          const SizedBox(height: Spacing.md),
          ExerciseMarkdownLite(detail.tips!, accent: context.colors.warning),
        ],
        if (!detail.hasRichContent) ...[
          const SizedBox(height: Spacing.xl),
          _EmptyContentHint(),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    this.accent,
  });

  final IconData icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? context.colors.primary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: Spacing.sm),
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _VideoCTA extends StatelessWidget {
  const _VideoCTA({required this.url});

  final String url;

  Future<void> _onTap(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    AppSnackBar.success(
      context,
      'Link copiado · pegalo en el navegador para ver el tutorial',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onTap(context),
        child: Ink(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.colors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.play_circle_filled_rounded,
                color: context.colors.primary,
                size: 32,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VER VIDEO TUTORIAL',
                      style: AppTextStyles.label.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tocá para copiar el link',
                      style: AppTextStyles.label.copyWith(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.content_copy_rounded,
                color: context.colors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyContentHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: context.colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'Todavía no hay contenido enriquecido para este ejercicio.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: context.colors.error,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Spacing.lg),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
