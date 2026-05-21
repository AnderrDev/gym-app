import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

/// Halo radial neon-lime difuminado detrás del formulario de auth. El gradient
/// se centra ligeramente arriba para que el card del formulario quede en el
/// "calor" del halo. Sin overlay sólido encima — el background del scaffold
/// sigue siendo `context.colors.background`.
class AuthAuraBackground extends StatelessWidget {
  const AuthAuraBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _AuraGradient()),
        child,
      ],
    );
  }
}

class _AuraGradient extends StatelessWidget {
  const _AuraGradient();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 0.9,
          colors: [
            context.colors.primary.withValues(alpha: 0.22),
            context.colors.primary.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
    );
  }
}
