import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_application_1/core/widgets/sems_button.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class VerifyAccountScreen extends StatefulWidget {
  final String token;
  const VerifyAccountScreen({super.key, required this.token});

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  bool _loading = true;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    try {
      await AuthRepositoryImpl.verifyAccount(widget.token);
      if (mounted) setState(() => _success = true);
    } catch (_) {
      if (mounted) setState(() => _success = false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_loading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(lang.t("Verificando cuenta...", "Verifying account...")),
              ] else if (_success) ...[
                Icon(Icons.check_circle, size: 64, color: SemsColors.emerald500),
                const SizedBox(height: 16),
                Text(
                  lang.t("¡Cuenta verificada!", "Account verified!"),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SemsButton(
                  text: lang.t("Ir al login", "Go to login"),
                  onPressed: () => context.go('/login'),
                ),
              ] else ...[
                Icon(Icons.error, size: 64, color: SemsColors.rose500),
                const SizedBox(height: 16),
                Text(
                  lang.t("No se pudo verificar", "Could not verify"),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(lang.t("El enlace es inválido o expiró.", "Link is invalid or expired.")),
                const SizedBox(height: 24),
                SemsButton(
                  text: lang.t("Ir al login", "Go to login"),
                  onPressed: () => context.go('/login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
