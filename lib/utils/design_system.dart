// Design System Components - Standardized UI Kit
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'loading_components.dart';

/// Standardized Card Component
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double? borderWidth;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.borderWidth,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: borderColor != null 
          ? Border.all(color: borderColor!, width: borderWidth ?? 1)
          : null,
        boxShadow: elevated ? AppShadows.standard : null,
      ),
      child: child,
    );
  }
}

/// Standardized Button Components
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool loading;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.loading = false,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = loading 
      ? AppLoading.small
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              SizedBox(width: AppSpacing.xs),
            ],
            Text(text),
          ],
        );

    ButtonStyle style = _getButtonStyle().copyWith(
      padding: padding != null 
        ? WidgetStateProperty.all(padding)
        : null,
    );

    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: style,
          child: content,
        );
      case AppButtonType.secondary:
        return OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: style,
          child: content,
        );
      case AppButtonType.ghost:
        return TextButton(
          onPressed: loading ? null : onPressed,
          style: style,
          child: content,
        );
    }
  }

  ButtonStyle _getButtonStyle() {
    switch (type) {
      case AppButtonType.primary:
        return AppButtonStyles.primary;
      case AppButtonType.secondary:
        return AppButtonStyles.secondary;
      case AppButtonType.ghost:
        return AppButtonStyles.ghost;
    }
  }
}

enum AppButtonType { primary, secondary, ghost }

/// Standardized Input Component
class AppInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final Widget? suffixIcon;

  const AppInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        // Theme handles all other styling
      ),
    );
  }
}

/// Standardized Section Header
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool accent;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: accent ? AppTextStyles.processHeader : AppTextStyles.h3,
              ),
              if (subtitle != null) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

/// Standardized Status Badge
class AppStatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool outlined;

  const AppStatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.1),
        border: Border.all(
          color: color,
          width: outlined ? 1 : 0,
        ),
        borderRadius: BorderRadius.circular(AppRadius.standard),
      ),
      child: Text(
        text,
        style: AppTextStyles.captionSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Standardized Empty State
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.lightGray.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Focus Outline Helper
class AppFocusOutline extends StatelessWidget {
  final Widget child;
  final bool focused;

  const AppFocusOutline({
    super.key,
    required this.child,
    this.focused = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(
          color: focused ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: child,
    );
  }
}