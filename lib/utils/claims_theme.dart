import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Claims-specific Status Colors
class ClaimsColors {
  // Status Colors (matching the existing design system)
  static const Color pending = Color(0xFFF57C00); // Orange for pending/under review
  static const Color pendingLight = Color(0xFFFFF9E6); // Light yellow background
  static const Color approved = Color(0xFF4CAF50); // Green for approved/completed
  static const Color approvedLight = Color(0xFFE8F5E9); // Light green background
  static const Color rejected = Color(0xFFF44336); // Red for rejected
  static const Color rejectedLight = Color(0xFFFFEBEE); // Light red background
  static const Color info = Color(0xFF2196F3); // Blue for informational states
  static const Color infoLight = Color(0xFFE3F2FD); // Light blue background
}

/// Compact Spacing for Claims UI
class ClaimsSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
}

/// Typography Styles for Claims
class ClaimsTypography {
  // Titles
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Body text
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Small text
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Labels
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}

/// Claims Button Styles (Uniform height and width)
class ClaimsButtonStyles {
  // Primary Action Button (Approve, Confirm, Submit)
  static ButtonStyle primary({Color? backgroundColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12, // Reduced: 12px top/bottom = 42px total height
      ),
      minimumSize: const Size(double.infinity, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  // Secondary Action Button (Reject, Cancel, Go Back)
  static ButtonStyle secondary({Color? foregroundColor}) {
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor ?? AppColors.textPrimary,
      backgroundColor: AppColors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      minimumSize: const Size(double.infinity, 42),
      side: BorderSide(
        color: foregroundColor ?? AppColors.lightGray,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  // Tertiary Action Button (View Details, Contact)
  static ButtonStyle tertiary() {
    return TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      minimumSize: const Size(double.infinity, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      textStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  // Gradient Button (Special actions like Approve)
  static BoxDecoration gradientDecoration({
    required List<Color> colors,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(AppRadius.md),
      boxShadow: [
        BoxShadow(
          color: colors.first.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

/// Claims Card Styles (Consistent padding, margin, border-radius)
class ClaimsCardStyles {
  // Main Card Container
  static BoxDecoration card({
    Color? backgroundColor,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      boxShadow: elevated ? AppShadows.soft : null,
    );
  }

  // Compact Card (for list items)
  static BoxDecoration compactCard({bool isExpanded = false}) {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      boxShadow: isExpanded
          ? AppShadows.soft
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
    );
  }

  // Info/Status Card (colored background)
  static BoxDecoration infoCard(Color backgroundColor) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: backgroundColor.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  // Section Card (collapsible sections)
  static BoxDecoration sectionCard() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      boxShadow: AppShadows.soft,
    );
  }
}

/// Reusable Claims Widgets
class ClaimsWidgets {
  // Status Badge Widget
  static Widget statusBadge({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // Information Row (icon + text)
  static Widget infoRow({
    required IconData icon,
    required String text,
    Color? iconColor,
    TextStyle? textStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ?? AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textStyle ??
                const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }

  // Section Header (collapsible)
  static Widget sectionHeader({
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Color color,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Row(
          children: [
            // Status Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Title and Count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$count claim${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Expand/Collapse Icon
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Thumbnail Image
  static Widget thumbnail({
    String? imageUrl,
    IconData placeholderIcon = Icons.image_outlined,
    double size = 48,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      clipBehavior: Clip.hardEdge,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                placeholderIcon,
                color: AppColors.textSecondary,
                size: size * 0.5,
              ),
            )
          : Icon(
              placeholderIcon,
              color: AppColors.textSecondary,
              size: size * 0.5,
            ),
    );
  }

  // Divider Line
  static Widget divider() {
    return Divider(
      height: 1,
      color: AppColors.lightGray.withOpacity(0.5),
    );
  }

  // Empty State
  static Widget emptyState({
    required String message,
    required IconData icon,
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: AppColors.lightGray,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Compact Info Card
  static Widget compactInfoCard({
    required String label,
    required String value,
    IconData? icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(ClaimsSpacing.sm),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: color ?? AppColors.primary,
            ),
            const SizedBox(width: ClaimsSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: ClaimsTypography.label,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: ClaimsTypography.bodyBold,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Detail Row (label: value)
  static Widget detailRow({
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClaimsSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: ClaimsTypography.caption,
            ),
          ),
          const SizedBox(width: ClaimsSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? ClaimsTypography.body,
            ),
          ),
        ],
      ),
    );
  }
}

/// Claims Button Widget (Reusable)
class ClaimsButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final ClaimsButtonType type;
  final bool isLoading;
  final bool isFullWidth;

  const ClaimsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.type = ClaimsButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;

    switch (type) {
      case ClaimsButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ClaimsButtonStyles.primary(),
          child: _buildButtonContent(),
        );
        break;
      case ClaimsButtonType.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: ClaimsButtonStyles.secondary(),
          child: _buildButtonContent(),
        );
        break;
      case ClaimsButtonType.approve:
        return Container(
          decoration: ClaimsButtonStyles.gradientDecoration(
            colors: [ClaimsColors.approved, const Color(0xFF388E3C)],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              minimumSize: const Size(double.infinity, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            child: _buildButtonContent(),
          ),
        );
      case ClaimsButtonType.reject:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: ClaimsButtonStyles.secondary(
            foregroundColor: ClaimsColors.rejected,
          ),
          child: _buildButtonContent(),
        );
        break;
      case ClaimsButtonType.review:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ClaimsButtonStyles.primary(backgroundColor: ClaimsColors.pending),
          child: _buildButtonContent(),
        );
        break;
      case ClaimsButtonType.contact:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ClaimsButtonStyles.primary(backgroundColor: const Color(0xFF25D366)),
          child: _buildButtonContent(),
        );
        break;
      case ClaimsButtonType.call:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: ClaimsButtonStyles.secondary(),
          child: _buildButtonContent(),
        );
        break;
    }

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildButtonContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (icon != null) ...[
          Icon(icon, size: 16),
          const SizedBox(width: 6),
        ],
        if (!isLoading) 
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
    );
  }
}

enum ClaimsButtonType {
  primary,
  secondary,
  approve,
  reject,
  review,
  contact,
  call,
}

/// Claims Card Widget (Reusable)
class ClaimsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool elevated;

  const ClaimsCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.md),
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: ClaimsCardStyles.card(
        backgroundColor: backgroundColor,
        elevated: elevated,
      ),
      child: child,
    );
  }
}
