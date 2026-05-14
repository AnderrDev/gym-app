import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';

/// Loader on‑brand: una barra con dos platos a los costados que hace una
/// "repetición" — leve subida-bajada vertical más un pulse de opacidad en
/// los platos. Sin dependencias externas: `CustomPainter` + un único
/// `AnimationController`.
///
/// Tres tamaños preset (`small`/`medium`/`large`) y un constructor genérico
/// para casos custom. Color: por defecto `AppColors.primary` (lime), pero
/// se puede pisar (por ejemplo cuando vive arriba de un botón filled).
class BarbellLoader extends StatefulWidget {
  const BarbellLoader({
    super.key,
    this.size = const Size(56, 28),
    this.color,
    this.semanticLabel = 'Cargando',
  });

  /// Inline / dentro de un Row. ~28×14.
  const BarbellLoader.small({super.key, this.color, this.semanticLabel = 'Cargando'})
    : size = const Size(28, 14);

  /// Para zonas medianas. ~56×28.
  const BarbellLoader.medium({super.key, this.color, this.semanticLabel = 'Cargando'})
    : size = const Size(56, 28);

  /// Para pages vacíos / dialog grande. ~84×42.
  const BarbellLoader.large({super.key, this.color, this.semanticLabel = 'Cargando'})
    : size = const Size(84, 42);

  final Size size;
  final Color? color;
  final String semanticLabel;

  @override
  State<BarbellLoader> createState() => _BarbellLoaderState();
}

class _BarbellLoaderState extends State<BarbellLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _BarbellPainter(
                progress: _controller.value,
                color: color,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BarbellPainter extends CustomPainter {
  _BarbellPainter({required this.progress, required this.color});

  /// 0..1 — fase del ciclo de "repetición".
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Curva sinusoidal para que la subida/bajada sea suave.
    final t = progress;
    final liftPhase = _smoothSin(t); // 0..1..0
    final liftRange = h * 0.18;
    final dy = -liftRange * liftPhase; // negativo = arriba

    // Sincronizo el pulse de los platos con el lift (más claros arriba).
    final pulseAlpha = 0.6 + 0.4 * liftPhase;

    final plateWidth = w * 0.16;
    final plateHeight = h * 0.95;
    final innerPlateWidth = plateWidth * 0.55;
    final innerPlateHeight = h * 0.7;
    final barHeight = h * 0.22;
    final barWidth = w - plateWidth * 2 + 4; // se cuelan un poco bajo los platos

    canvas.save();
    canvas.translate(0, dy);

    final centerY = h / 2;

    // Barra central.
    final barPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final barRect = RRect.fromLTRBR(
      (w - barWidth) / 2,
      centerY - barHeight / 2,
      (w + barWidth) / 2,
      centerY + barHeight / 2,
      Radius.circular(barHeight / 2),
    );
    canvas.drawRRect(barRect, barPaint);

    // Platos externos (más grandes).
    final platePaint = Paint()
      ..color = color.withValues(alpha: pulseAlpha)
      ..style = PaintingStyle.fill;
    final outerRadius = Radius.circular(plateWidth * 0.25);
    canvas.drawRRect(
      RRect.fromLTRBR(
        0,
        centerY - plateHeight / 2,
        plateWidth,
        centerY + plateHeight / 2,
        outerRadius,
      ),
      platePaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        w - plateWidth,
        centerY - plateHeight / 2,
        w,
        centerY + plateHeight / 2,
        outerRadius,
      ),
      platePaint,
    );

    // Platos internos (más chicos, pulse desfasado).
    final innerPhase = _smoothSin((t + 0.5) % 1.0);
    final innerAlpha = 0.45 + 0.45 * innerPhase;
    final innerPaint = Paint()
      ..color = color.withValues(alpha: innerAlpha)
      ..style = PaintingStyle.fill;
    final innerRadius = Radius.circular(innerPlateWidth * 0.25);
    canvas.drawRRect(
      RRect.fromLTRBR(
        plateWidth + 2,
        centerY - innerPlateHeight / 2,
        plateWidth + 2 + innerPlateWidth,
        centerY + innerPlateHeight / 2,
        innerRadius,
      ),
      innerPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        w - plateWidth - 2 - innerPlateWidth,
        centerY - innerPlateHeight / 2,
        w - plateWidth - 2,
        centerY + innerPlateHeight / 2,
        innerRadius,
      ),
      innerPaint,
    );

    canvas.restore();
  }

  /// `sin(πt)` reescalado a 0..1 — sube de 0 a 1 y vuelve a 0 en un ciclo.
  /// Da una sensación más orgánica que una rampa lineal.
  static double _smoothSin(double t) {
    final s = (1 - (2 * t - 1).abs());
    // Ease cuadrático para suavizar la cima.
    return s * s * (3 - 2 * s);
  }

  @override
  bool shouldRepaint(covariant _BarbellPainter old) =>
      old.progress != progress || old.color != color;
}
