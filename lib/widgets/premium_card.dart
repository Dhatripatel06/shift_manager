import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Premium card widget with glassmorphism and gradient effects
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final LinearGradient? gradient;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final double? elevation;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.borderRadius,
    this.boxShadow,
    this.onTap,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient:
              gradient ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppColors.cardDark, AppColors.cardDarkElevated]
                    : [AppColors.cardLight, AppColors.cardLightElevated],
              ),
          borderRadius: BorderRadius.circular(borderRadius ?? 20),
          boxShadow:
              boxShadow ??
              [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
