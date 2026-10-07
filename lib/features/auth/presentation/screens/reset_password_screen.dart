import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_application_1/core/widgets/sems_button.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _success = false;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.password, size: 48, color: SemsColors.blue600),
                const SizedBox(height: 16),
                Text(
                  lang.t("Nueva contraseña", "New password"),
                  style: const TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  lang.t("Ingresa tu nueva contraseña para acceder.", "Enter your new password to login."),
                  style: TextStyle(color: isDark ? SemsColors.slate400 : SemsColors.slate500, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_success)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: SemsColors.emerald500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SemsColors.emerald500.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          lang.t("¡Contraseña actualizada!", "Password updated!"),
                          style: const TextStyle(color: SemsColors.emerald600, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SemsButton(
                          text: lang.t("Ir al login", "Go to login"),
                          onPressed: () => context.go('/login'),
                          isFullWidth: true,
                        )
                      ],
                    ),
                  )
                else ...[
                  Text(lang.t("Nueva Password", "New Password"), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(hintText: "••••••••")),
                  const SizedBox(height: 24),
                  SemsButton(
                    text: lang.t("Guardar contraseña", "Save password"),
                    isLoading: _loading,
                    isFullWidth: true,
                    onPressed: () async {
                      setState(() => _loading = true);
                      try {
                        await AuthRepositoryImpl.resetPassword(widget.token, _passCtrl.text);
                        setState(() => _success = true);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.t("Error", "Error"))));
                      } finally {
                        setState(() => _loading = false);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
