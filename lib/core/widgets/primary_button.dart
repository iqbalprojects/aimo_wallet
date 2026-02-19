import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Primary Button
/// 
/// Reusable button component with gradient background.
/// 
/// Usage:
/// ```dart
/// PrimaryButton(
///   text: 'Continue',
///   onPressed: () => controller.handleContinue(),
/// )
/// ```
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: onPressed != null && !isLoading
              ? AppTheme.primaryGradient
              : null,
          color: onPressed == null || isLoading
              ? AppTheme.textTertiary
              : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: onPressed != null && !isLoading
              ? AppTheme.cardShadow
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.textPrimary,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: AppTheme.spacingS),
                    ],
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
