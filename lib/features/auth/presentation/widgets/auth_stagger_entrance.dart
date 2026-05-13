import 'dart:async';

import 'package:flutter/material.dart';

/// Envoltorio que aplica fade + slide-up al child cuando se monta, con un
/// `delay` opcional. Usado en login/register para crear una entrada en
/// cascada de los elementos del formulario.
class AuthStaggerEntrance extends StatefulWidget {
  const AuthStaggerEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
    this.offsetY = 12.0,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  @override
  State<AuthStaggerEntrance> createState() => _AuthStaggerEntranceState();
}

class _AuthStaggerEntranceState extends State<AuthStaggerEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary aísla el repaint del fade/translate: con múltiples
    // staggers en cascada en la misma pantalla, sin él cada frame invalida
    // la capa raster del padre completo.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: Transform.translate(
              offset: Offset(0, (1 - _animation.value) * widget.offsetY),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
