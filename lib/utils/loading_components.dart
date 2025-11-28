import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Standardized Loading Components
class AppLoading {
  /// Standard loading indicator for general use
  static Widget get standard => SizedBox(
    width: 24,
    height: 24,
    child: CircularProgressIndicator(
      strokeWidth: 2.5,
      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
    ),
  );
  
  /// Small loading indicator for buttons
  static Widget get small => SizedBox(
    width: 16,
    height: 16,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
    ),
  );
  
  /// Loading screen with neutral background
  static Widget screen({String? message}) => Container(
    color: AppColors.background,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          standard,
          if (message != null) ...[
            SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
  
  /// Loading overlay for existing content
  static Widget overlay({String? message}) => Container(
    color: AppColors.white.withOpacity(0.8),
    child: Center(
      child: Container(
        padding: EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          boxShadow: AppShadows.standard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            standard,
            if (message != null) ...[
              SizedBox(height: AppSpacing.lg),
              Text(
                message,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    ),
  );
  
  /// Minimal inline loading for list items
  static Widget get inline => Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.mediumGray),
        ),
      ),
    ),
  );
}

/// Standardized Success/Process Headers
class AppHeaders {
  /// Success header with accent color
  static Widget success({
    required String title,
    String? subtitle,
    IconData? icon,
  }) => Column(
    children: [
      if (icon != null) ...[
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
      ],
      Text(
        title,
        style: AppTextStyles.successHeader,
        textAlign: TextAlign.center,
      ),
      if (subtitle != null) ...[
        SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ],
  );
  
  /// Process header with accent color
  static Widget process({
    required String title,
    String? subtitle,
    IconData? icon,
  }) => Column(
    children: [
      if (icon != null) ...[
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.standard),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        SizedBox(height: AppSpacing.md),
      ],
      Text(
        title,
        style: AppTextStyles.processHeader,
        textAlign: TextAlign.center,
      ),
      if (subtitle != null) ...[
        SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ],
  );
}

/// Subtle Animation Utilities
class AppAnimations {
  /// Standard fade duration
  static const Duration fadeDuration = Duration(milliseconds: 200);
  
  /// Standard slide duration
  static const Duration slideDuration = Duration(milliseconds: 250);
  
  /// Fade transition
  static Widget fadeIn({
    required Widget child,
    Duration? duration,
  }) => AnimatedOpacity(
    opacity: 1.0,
    duration: duration ?? fadeDuration,
    child: child,
  );
  
  /// Slide transition
  static Widget slideIn({
    required Widget child,
    Duration? duration,
    Offset? begin,
  }) => AnimatedSlide(
    offset: Offset.zero,
    duration: duration ?? slideDuration,
    curve: Curves.easeOut,
    child: child,
  );
}