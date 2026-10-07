import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/config/theme.dart';

enum SemsButtonVariant { primary, outline, ghost }

class SemsButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final SemsButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? customIcon;

  const SemsButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = SemsButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null || customIcon != null) ...[
          customIcon ?? Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(text),
      ],
    );

    ButtonStyle style;
    switch (variant) {
      case SemsButtonVariant.primary:
        style = ElevatedButton.styleFrom(
          backgroundColor: SemsColors.blue600,
          foregroundColor: Colors.white,
          disabledBackgroundColor: SemsColors.blue600.withValues(alpha: 0.6),
        );
        break;
      case SemsButtonVariant.outline:
        style = OutlinedButton.styleFrom(
          foregroundColor: isDark ? SemsColors.slate200 : SemsColors.slate700,
          side: BorderSide(color: isDark ? SemsColors.navy700 : SemsColors.slate300),
          disabledForegroundColor: (isDark ? SemsColors.slate200 : SemsColors.slate700).withValues(alpha: 0.6),
        );
        break;
      case SemsButtonVariant.ghost:
        style = TextButton.styleFrom(
          foregroundColor: isDark ? SemsColors.slate300 : SemsColors.slate600,
          disabledForegroundColor: (isDark ? SemsColors.slate300 : SemsColors.slate600).withValues(alpha: 0.6),
        );
        break;
    }

    Widget button;
    if (variant == SemsButtonVariant.primary) {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      );
    } else if (variant == SemsButtonVariant.outline) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      );
    } else {
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      );
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
