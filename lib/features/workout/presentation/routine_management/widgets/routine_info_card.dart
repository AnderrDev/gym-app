import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/i18n/app_strings.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';

/// Card de información de la rutina: avatar de color (acento por nombre),
/// input grande del nombre, switch público con descripción corta.
class RoutineInfoCard extends StatefulWidget {
  const RoutineInfoCard({
    super.key,
    required this.nameController,
    required this.isPublic,
    required this.onNameChanged,
    required this.onPublicChanged,
    this.readOnly = false,
    this.creatorName,
  });

  final TextEditingController nameController;
  final bool isPublic;
  final VoidCallback onNameChanged;
  final ValueChanged<bool> onPublicChanged;

  /// Cuando `true` deshabilita la edición del nombre y el switch público.
  /// Se usa al abrir una rutina ajena (vista previa antes de forkear).
  final bool readOnly;

  /// Nombre del autor, sólo se muestra en modo `readOnly` como atribución
  /// debajo del nombre.
  final String? creatorName;

  @override
  State<RoutineInfoCard> createState() => _RoutineInfoCardState();
}

class _RoutineInfoCardState extends State<RoutineInfoCard> {
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
        color: context.colors.surface,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: widget.nameController,
                      readOnly: widget.readOnly,
                      enabled: !widget.readOnly,
                      onChanged: (_) => widget.onNameChanged(),
                      style: context.text.displayLarge
                          ?.copyWith(fontSize: 22, letterSpacing: -0.3),
                      decoration: InputDecoration(
                        hintText: 'Nombre de la rutina',
                        hintStyle: context.text.displayLarge?.copyWith(
                          color: context.colors.textDisabled,
                          fontSize: 22,
                          letterSpacing: -0.3,
                        ),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 6),
                        border: InputBorder.none,
                      ),
                    ),
                    if (widget.readOnly &&
                        widget.creatorName != null &&
                        widget.creatorName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Por ${widget.creatorName}',
                          style: context.text.labelMedium?.copyWith(
                            color: context.colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Divider(color: context.colors.divider, height: 1),
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isPublic ? AppStrings.public : AppStrings.private,
                      style: context.text.labelMedium?.copyWith(
                        color: widget.isPublic
                            ? accent
                            : context.colors.textSecondary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      widget.isPublic
                          ? 'Visible para toda la comunidad'
                          : 'Solo vos podés usarla',
                      style: context.text.labelMedium?.copyWith(
                        color: context.colors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.isPublic,
                activeThumbColor: accent,
                onChanged: widget.readOnly ? null : widget.onPublicChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
