import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';

/// Avatar circular con iniciales (o icono fallback) + nombre + email.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user});

  final User user;

  /// Primer letra del primer y último word (max 2 chars, en mayúsculas).
  /// Devuelve `''` cuando no hay nombre utilizable.
  static String _computeInitials(String? fullName) {
    if (fullName == null) return '';
    final words = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words.first.characters.first.toUpperCase();
    }
    final first = words.first.characters.first;
    final last = words.last.characters.first;
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final initials = _computeInitials(user.fullName);
    final hasInitials = initials.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary.withValues(alpha: 0.16),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: hasInitials
              ? Text(
                  initials,
                  style: text.headlineLarge?.copyWith(
                    color: colors.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : Icon(Icons.person_rounded, size: 40, color: colors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          (user.fullName != null && user.fullName!.trim().isNotEmpty)
              ? user.fullName!
              : 'Sin nombre',
          style: text.headlineMedium,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: text.bodyMedium?.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
