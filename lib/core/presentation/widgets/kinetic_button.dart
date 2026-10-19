import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';

class KineticButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool fullWidth;
  final IconData? icon;
  final bool isLoading;

  const KineticButton({
    super.key,
    required this.label,
    this.onTap,
    this.fullWidth = true,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<KineticButton> createState() => _KineticButtonState();
}

class _KineticButtonState extends State<KineticButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && !widget.isLoading) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: widget.isLoading
              ? Center(child: AppSpinner.small(color: context.colors.onPrimary))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: context.colors.onPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      widget.label.toUpperCase(),
                      style: context.text.headlineMedium?.copyWith(
                        color: context.colors.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
