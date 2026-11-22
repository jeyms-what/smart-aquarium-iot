import 'package:flutter/material.dart';

/// Reusable, low-distraction card surface for AquaCare.
///
/// This intentionally uses a solid Material surface rather than a blur on
/// every card. It keeps sensor dashboards readable and reduces repeated
/// BackdropFilter work on mobile devices.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.tint,
    this.blur = 18,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;

  /// Retained for source compatibility with earlier Aqua Life widgets.
  /// Flat surfaces no longer use a backdrop blur.
  final double blur;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint ?? colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.72 : 0.9),
        ),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: const Color(0xFF164D4B).withValues(alpha: 0.045),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: child,
    );
  }
}

/// A Material Card wrapped in the shared AquaCare surface treatment.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.color,
    super.key,
  });

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      tint: color,
      child: child,
    );
  }
}
