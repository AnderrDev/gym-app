import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';

/// Loader circular on-brand: anillo de fondo a baja opacidad + arco sweep
/// con caps redondos rotando, y un dot interior que respira en fase con
/// el sweep. Sin dependencias externas: `CustomPainter` + un único
/// `AnimationController`.
///
/// Conserva la API histórica (`small`/`medium`/`large` + constructor
/// genérico) para que los callers (`AppLoader`, dialogs, sheets, pages)
/// no necesiten cambios. El nombre de la clase es legacy — el diseño es
/// circular, no más la "barbell-rep".
class BarbellLoader extends StatefulWidget {
  const BarbellLoader({
    super.key,
    this.size = const Size(40, 40),
    this.color,
    this.semanticLabel = 'Cargando',
  });

  /// Inline / dentro de un Row. ~20×20.
  const BarbellLoader.small({super.key, this.color, this.semanticLabel = 'Cargando'})
    : size = const Size(20, 20);

  /// Para zonas medianas. ~40×40.
  const BarbellLoader.medium({super.key, this.color, this.semanticLabel = 'Cargando'})
    : size = const Size(40, 40);

  /// Para pages vacíos / dialog grande. ~64×64.
  const BarbellLoader.large({super.key, this.color, this.semanticLabel = 'Cargando'})
    : size = const Size(64, 64);

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
      duration: const Duration(milliseconds: 1200),
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
    // Fuerza shape cuadrado: si el caller pasó un Size no-cuadrado, usamos
    // el lado menor — el painter dibuja un círculo y los rectángulos
    // distorsionaban la geometría.
    final side = math.min(widget.size.width, widget.size.height);
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: SizedBox(
        width: side,
        height: side,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _RingLoaderPainter(
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

class _RingLoaderPainter extends CustomPainter {
  _RingLoaderPainter({required this.progress, required this.color});

  /// 0..1 — fase del ciclo.
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    // Grosor del stroke ~12% del diámetro: suficiente para verse a 20px
    // y no satura a 64px.
    final stroke = math.max(2.0, side * 0.12);
    final radius = (side - stroke) / 2;

    // 1. Ring de fondo (full circle, alpha baja).
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Arc sweep rotante. La longitud del arco oscila entre 18% y 82%
    //    del círculo (sensación de "respiración") y el ángulo de inicio
    //    avanza a ritmo constante para que nunca se vea estático.
    final sweepPhase = _smoothSin(progress); // 0..1..0
    final sweepFraction = 0.18 + 0.64 * sweepPhase;
    final sweepAngle = sweepFraction * 2 * math.pi;
    // 2π por ciclo asegura una vuelta completa por loop además del
    // efecto respiración → el ojo siempre detecta movimiento.
    final startAngle = -math.pi / 2 + progress * 2 * math.pi;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // 3. Dot central que respira (más visible cuando el arco es corto, da
    //    una segunda capa de movimiento para tamaños grandes).
    final dotRadius = side * 0.06;
    final dotAlpha = 0.35 + 0.55 * (1 - sweepPhase);
    final dotPaint = Paint()
      ..color = color.withValues(alpha: dotAlpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, dotRadius, dotPaint);
  }

  /// Curva 0→1→0 con ease cuadrático en la cima.
  static double _smoothSin(double t) {
    final s = 1 - (2 * t - 1).abs();
    return s * s * (3 - 2 * s);
  }

  @override
  bool shouldRepaint(covariant _RingLoaderPainter old) =>
      old.progress != progress || old.color != color;
}
