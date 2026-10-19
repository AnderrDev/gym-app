import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Campo de formulario único. Sustituye a todos los `TextField` directos en
/// `lib/features/`. La apariencia viene del `inputDecorationTheme` del tema —
/// `AppFormField` solo orquesta valor, error y autofill.
///
/// El `value` es la fuente de verdad: el widget maneja un controller interno
/// para no obligar a cada caller a crearlo, pero sincroniza con `value` en
/// `didUpdateWidget` para que el formulario reactivo siga siendo dueño del
/// estado.
class AppFormField extends StatefulWidget {
  const AppFormField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.prefixIcon,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
    this.hintText,
    this.focusNode,
    this.uppercaseLabel = true,
    this.autofocus = false,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final IconData? prefixIcon;
  final bool enabled;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final FocusNode? focusNode;
  final bool uppercaseLabel;
  final bool autofocus;

  @override
  State<AppFormField> createState() => _AppFormFieldState();
}

class _AppFormFieldState extends State<AppFormField> {
  late final TextEditingController _controller;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _obscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AppFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleObscured() => setState(() => _obscured = !_obscured);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.uppercaseLabel ? widget.label.toUpperCase() : widget.label,
          style: textTheme.labelMedium?.copyWith(
            fontSize: widget.uppercaseLabel ? null : 14,
            letterSpacing: widget.uppercaseLabel ? 1.5 : 0,
            fontWeight: widget.uppercaseLabel
                ? FontWeight.w900
                : FontWeight.w600,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Semantics(
          label: widget.label,
          child: TextField(
            controller: _controller,
            autofocus: widget.autofocus,
            focusNode: widget.focusNode,
            obscureText: _obscured && widget.obscureText,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hintText,
              errorText: widget.errorText,
              counterText: '',
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, size: 18)
                  : null,
              suffixIcon: widget.obscureText
                  ? IconButton(
                      tooltip: _obscured
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      onPressed: _toggleObscured,
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 18,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
