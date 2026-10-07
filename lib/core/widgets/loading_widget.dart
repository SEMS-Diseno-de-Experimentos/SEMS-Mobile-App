import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: SemsColors.blue600,
      ),
    );
  }
}
