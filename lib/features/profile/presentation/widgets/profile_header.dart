import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
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
            color: AppColors.primary.withValues(alpha: 0.16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: hasInitials
              ? Text(
                  initials,
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : const Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
        ),
        const SizedBox(height: 16),
        Text(
          (user.fullName != null && user.fullName!.trim().isNotEmpty)
              ? user.fullName!
              : 'Sin nombre',
          style: AppTextStyles.heading2,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
