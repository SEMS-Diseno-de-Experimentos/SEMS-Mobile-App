import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'sems_button.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class ErrorWidgetDisplay extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;

  const ErrorWidgetDisplay({super.key, required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: SemsColors.rose500),
          const SizedBox(height: 16),
          Text(
            message ?? lang.t("Algo salió mal", "Something went wrong"),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SemsButton(
            text: lang.t("Reintentar", "Retry"),
            onPressed: onRetry,
            variant: SemsButtonVariant.outline,
          ),
        ],
      ),
    );
  }
}
