import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';

/// Indicador de fuerza de contraseña: 3 segmentos que se rellenan según el
/// score combinado de longitud + variedad de caracteres. Cuando el campo
/// está vacío no se renderiza para no agregar ruido visual.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  /// 0 (vacía) · 1 (débil) · 2 (media) · 3 (fuerte).
  static int scoreFor(String pw) {
    if (pw.isEmpty) return 0;
    var score = 0;
    if (pw.length >= 8) score++;
    if (pw.length >= 12) score++;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(pw);
    final hasDigit = RegExp(r'\d').hasMatch(pw);
    final hasSymbol = RegExp(r'[!-/:-@\[-`{-~]').hasMatch(pw);
    final varietyCount =
        (hasUpper ? 1 : 0) + (hasDigit ? 1 : 0) + (hasSymbol ? 1 : 0);
    if (varietyCount >= 2) score++;
    return score.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final score = scoreFor(password);
    if (password.isEmpty) return const SizedBox.shrink();
    final (color, label) = _resolve(score);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: 4,
                decoration: BoxDecoration(
                  color: i < score ? color : AppColors.divider,
                  borderRadius: BorderRadius.circular(Radii.xs),
                ),
              ),
            ),
            if (i < 2) const SizedBox(width: 4),
          ],
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Text(
              label,
              key: ValueKey(label),
              style: AppTextStyles.label.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _resolve(int score) {
    switch (score) {
      case 0:
        return (AppColors.textSecondary, '');
      case 1:
        return (AppColors.error, 'DÉBIL');
      case 2:
        return (AppColors.warning, 'OK');
      case 3:
      default:
        return (AppColors.success, 'FUERTE');
    }
  }
}
