import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Input grande del nombre del día dentro del editor — sin chrome extra,
/// solo una línea con underline animado.
class DayNameInput extends StatelessWidget {
  const DayNameInput({
    super.key,
    required this.controller,
    required this.onChanged,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lgPlus,
        Spacing.sm,
        Spacing.lgPlus,
        Spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOMBRE DEL DÍA',
            style: context.text.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              letterSpacing: 1.2,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          TextField(
            controller: controller,
            onChanged: onChanged,
            readOnly: readOnly,
            enabled: !readOnly,
            style: context.text.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            decoration: InputDecoration(
              hintText: 'Pull Day · Espalda/Bíceps',
              hintStyle: context.text.headlineSmall?.copyWith(
                color: context.colors.textSecondary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
              isDense: true,
              // Sin relleno: el nombre es el título de la pantalla y se edita
              // en sitio, con solo la línea inferior como affordance.
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              border: InputBorder.none,
              // Vista previa (read-only): sin línea, se lee como título.
              disabledBorder: InputBorder.none,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.colors.divider),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: context.colors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
