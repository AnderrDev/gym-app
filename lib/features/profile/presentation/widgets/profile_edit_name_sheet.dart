import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/ui/molecules/app_form_field.dart';
import 'package:gym_flutter/features/profile/presentation/bloc/profile_bloc.dart';

/// Bottom sheet para editar `full_name`. Renderiza un `AppFormField`
/// + botón "Guardar". El bloc gestiona el ciclo submitting → success/failure
/// y la pantalla padre escucha el `lastSavedFullName` para refrescar la
/// `User` global vía `AuthBloc`.
class ProfileEditNameSheet extends StatefulWidget {
  const ProfileEditNameSheet({
    super.key,
    required this.userId,
    required this.initialValue,
    required this.onSaved,
  });

  final String userId;
  final String? initialValue;

  /// Se invoca con el nombre confirmado por la API. La pantalla padre
  /// debería propagarlo al `AuthBloc` para que toda la app vea el cambio.
  final void Function(String fullName) onSaved;

  @override
  State<ProfileEditNameSheet> createState() => _ProfileEditNameSheetState();
}

class _ProfileEditNameSheetState extends State<ProfileEditNameSheet> {
  late final TextEditingController _controller;
  String _value = '';

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue ?? '';
    _controller = TextEditingController(text: _value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final trimmed = _value.trim();
    if (trimmed.isEmpty) {
      AppSnackBar.warning(context, 'El nombre no puede estar vacío');
      return;
    }
    context.read<ProfileBloc>().add(
      UpdateFullNameRequested(userId: widget.userId, fullName: trimmed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == ProfileSubmissionStatus.success &&
            state.lastSavedFullName != null) {
          widget.onSaved(state.lastSavedFullName!);
          context.read<ProfileBloc>().add(const AcknowledgeProfileFeedback());
          Navigator.of(context).pop();
          AppSnackBar.success(context, 'Nombre actualizado');
        } else if (state.status == ProfileSubmissionStatus.failure) {
          AppSnackBar.error(context, state.errorMessage ?? 'Error al guardar');
          context.read<ProfileBloc>().add(const AcknowledgeProfileFeedback());
        }
      },
      builder: (context, state) {
        final submitting = state.status == ProfileSubmissionStatus.submitting;
        return Padding(
          padding: EdgeInsets.only(
            left: Spacing.xl,
            right: Spacing.xl,
            top: Spacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Editar nombre',
                style: AppTextStyles.heading2.copyWith(fontSize: 18),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'Así te ven los demás cuando compartís rutinas.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              AppFormField(
                label: 'Nombre',
                value: _value,
                onChanged: (v) => setState(() => _value = v),
                hintText: 'Tu nombre',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onSubmit(),
                enabled: !submitting,
              ),
              const SizedBox(height: Spacing.xl),
              AppButton(
                label: submitting ? 'GUARDANDO…' : 'GUARDAR',
                onPressed: submitting ? null : _onSubmit,
              ),
            ],
          ),
        );
      },
    );
  }
}
