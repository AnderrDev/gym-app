import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/settings/presentation/settings_bloc.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Bottom sheet con las tres opciones de tema: System / Claro / Oscuro.
///
/// Lee y dispatcha al `SettingsBloc` global (lifetime app), así que no hay
/// `BlocProvider` local — la elección persiste vía
/// `UserPreferencesService.setThemeMode`.
class ProfileThemeModeSheet extends StatelessWidget {
  const ProfileThemeModeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // El picker se monta vía `AdaptiveSheet.showRaw`, que en web envuelve en
    // un `Dialog` con backgroundColor transparent (sin chrome) y en mobile
    // en un `showModalBottomSheet` también con backgroundColor transparent.
    // Por eso el sheet debe traer su propio Material con `surface` y radii
    // de bottom-sheet — sin esto se ve transparente sobre la página.
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(Radii.xxl),
      ),
      clipBehavior: Clip.antiAlias,
      child: BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (p, c) => p.themeMode != c.themeMode,
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              Spacing.md,
              Spacing.xl,
              Spacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle (también sirve de affordance en web — separa
                // visualmente el sheet del scrim).
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: Spacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceOverlay,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Tema', style: context.text.titleLarge),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Elegí cómo se ve la app. "Sistema" sigue la configuración del dispositivo.',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: Spacing.lg),
                _ThemeOption(
                  mode: ThemeMode.system,
                  selected: state.themeMode == ThemeMode.system,
                  title: 'Sistema',
                  subtitle: 'Sigue al dispositivo',
                  icon: Icons.brightness_auto_rounded,
                ),
                const SizedBox(height: Spacing.sm),
                _ThemeOption(
                  mode: ThemeMode.light,
                  selected: state.themeMode == ThemeMode.light,
                  title: 'Claro',
                  subtitle: 'Fondo blanco siempre',
                  icon: Icons.light_mode_rounded,
                ),
                const SizedBox(height: Spacing.sm),
                _ThemeOption(
                  mode: ThemeMode.dark,
                  selected: state.themeMode == ThemeMode.dark,
                  title: 'Oscuro',
                  subtitle: 'Fondo oscuro siempre',
                  icon: Icons.dark_mode_rounded,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final ThemeMode mode;
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.primary;
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.10)
          : colors.surfaceHighlight,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () {
          context.read<SettingsBloc>().add(SettingsThemeModeChanged(mode));
          Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? accent
                      : colors.surface,
                  borderRadius: BorderRadius.circular(Radii.sm),
                  border: Border.all(color: colors.divider),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 18,
                  color: selected ? colors.onPrimary : colors.textPrimary,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(subtitle, style: context.text.bodySmall),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta humana del `ThemeMode` activo. Se usa en la fila del perfil para
/// mostrar el valor actual ("Sistema" / "Claro" / "Oscuro").
String themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return 'Sistema';
    case ThemeMode.light:
      return 'Claro';
    case ThemeMode.dark:
      return 'Oscuro';
  }
}
