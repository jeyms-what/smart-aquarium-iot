import 'dart:ui';

import 'package:flutter/material.dart';

/// Reusable frosted-glass surface for the Aqua Life visual system.
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
  final double blur;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = tint ?? (isDark ? const Color(0xFF0D5960) : const Color(0xFFE5FAF7));
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base.withValues(alpha: isDark ? 0.34 : 0.62),
                (isDark ? const Color(0xFF102D3A) : Colors.white)
                    .withValues(alpha: isDark ? 0.48 : 0.72),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: (isDark ? const Color(0xFF9AF5E8) : const Color(0xFF4CBFB5))
                  .withValues(alpha: isDark ? 0.22 : 0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF21D4C2).withValues(alpha: isDark ? 0.08 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
