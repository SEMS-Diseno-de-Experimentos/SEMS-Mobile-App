import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_application_1/core/widgets/sems_button.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_reset, size: 48, color: SemsColors.blue600),
                const SizedBox(height: 16),
                Text(
                  lang.t("Recuperar contraseña", "Recover password"),
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  lang.t(
                    "Ingresa tu correo y te enviaremos un enlace para restaurarla.",
                    "Enter your email and we'll send a reset link.",
                  ),
                  style: TextStyle(
                    color: isDark ? SemsColors.slate400 : SemsColors.slate500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_sent)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: SemsColors.emerald500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: SemsColors.emerald500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      lang.t(
                        "Si tu correo está registrado, recibirás las instrucciones en breve.",
                        "If registered, you'll receive instructions shortly.",
                      ),
                      style: const TextStyle(
                        color: SemsColors.emerald600,
                        fontSize: 13,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    lang.t("Email", "Email"),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(hintText: "tu@email.com"),
                  ),
                  const SizedBox(height: 24),
                  SemsButton(
                    text: lang.t("Enviar enlace", "Send link"),
                    isLoading: _loading,
                    isFullWidth: true,
                    onPressed: () async {
                      setState(() => _loading = true);
                      try {
                        await AuthRepositoryImpl.forgotPassword(
                          _emailCtrl.text,
                        );
                        setState(() => _sent = true);
                      } finally {
                        setState(() => _loading = false);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(lang.t("Volver al login", "Back to login")),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
