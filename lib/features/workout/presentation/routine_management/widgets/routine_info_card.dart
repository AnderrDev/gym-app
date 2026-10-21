import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_list_card.dart';

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

  /// Cuando `true` deshabilita la edición del nombre y oculta el switch público.
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
    final accent = RoutineColor.accentFor(context, widget.nameController.text);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(
          color: context.colors.divider.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RoutineAvatar(
                name: widget.nameController.text,
                accent: accent,
                size: 48,
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
                      style: context.text.headlineSmall?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nombre de la rutina',
                        hintStyle: context.text.headlineSmall?.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        isDense: true,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        // El tema define enabled/focused/disabledBorder, que tienen
                        // prioridad sobre `border`: sin anularlos sale un marco doble.
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                    if (widget.readOnly &&
                        widget.creatorName != null &&
                        widget.creatorName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Por ${widget.creatorName}',
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Compartir solo aplica a las rutinas propias: en la vista previa
          // de una ajena el switch deshabilitado solo confundía.
          if (!widget.readOnly) ...[
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
                        'Compartir con la comunidad',
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.isPublic
                            ? 'Pública · cualquiera puede verla y copiarla'
                            : 'Privada · solo tú puedes usarla',
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.isPublic,
                  activeThumbColor: accent,
                  onChanged: widget.onPublicChanged,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
