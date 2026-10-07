import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/config/theme.dart';

enum SemsBadgeVariant { blue, green, amber, rose, slate }

class SemsBadge extends StatelessWidget {
  final String text;
  final SemsBadgeVariant variant;

  const SemsBadge({
    super.key,
    required this.text,
    this.variant = SemsBadgeVariant.slate,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (variant) {
      case SemsBadgeVariant.blue:
        bgColor = isDark ? SemsColors.blue900 : SemsColors.blue100;
        textColor = isDark ? SemsColors.blue300 : SemsColors.blue700;
        break;
      case SemsBadgeVariant.green:
        bgColor = isDark ? SemsColors.emerald700 : SemsColors.emerald50;
        textColor = isDark ? SemsColors.emerald300 : SemsColors.emerald700;
        break;
      case SemsBadgeVariant.amber:
        bgColor = isDark ? SemsColors.amber700 : SemsColors.amber50;
        textColor = isDark ? SemsColors.amber300 : SemsColors.amber700;
        break;
      case SemsBadgeVariant.rose:
        bgColor = isDark ? SemsColors.rose700 : SemsColors.rose50;
        textColor = isDark ? SemsColors.rose300 : SemsColors.rose700;
        break;
      case SemsBadgeVariant.slate:
        bgColor = isDark ? SemsColors.slate800 : SemsColors.slate100;
        textColor = isDark ? SemsColors.slate300 : SemsColors.slate700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
