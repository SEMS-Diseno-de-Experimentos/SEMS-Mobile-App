import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/core/widgets/sems_button.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _error = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
                Icon(
                  Icons.electric_bolt,
                  size: 48,
                  color: SemsColors.blue600,
                ),
                const SizedBox(height: 16),
                Text(
                  lang.t("Iniciar sesión", "Sign in"),
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  lang.t("Bienvenido de vuelta a SEMS", "Welcome back to SEMS"),
                  style: TextStyle(
                    color: isDark ? SemsColors.slate400 : SemsColors.slate500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_error)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: SemsColors.rose500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SemsColors.rose500.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      lang.t("Credenciales incorrectas.", "Invalid credentials."),
                      style: const TextStyle(color: SemsColors.rose500, fontSize: 13),
                    ),
                  ),
                Text(lang.t("Email", "Email"), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    hintText: "tu@email.com",
                  ),
                ),
                const SizedBox(height: 16),
                Text(lang.t("Password", "Password"), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "••••••••",
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    style: TextButton.styleFrom(
                      foregroundColor: SemsColors.blue600,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: Text(lang.t("¿Olvidaste tu contraseña?", "Forgot password?")),
                  ),
                ),
                const SizedBox(height: 16),
                SemsButton(
                  text: lang.t("Iniciar sesión", "Sign in"),
                  isLoading: auth.isLoading,
                  isFullWidth: true,
                  onPressed: () async {
                    setState(() => _error = false);
                    try {
                      await auth.login(_emailCtrl.text, _passCtrl.text);
                      if (context.mounted) context.go('/');
                    } catch (e) {
                      setState(() => _error = true);
                    }
                  },
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      lang.t("¿No tienes cuenta?", "Don't have an account?"),
                      style: TextStyle(
                        color: isDark ? SemsColors.slate400 : SemsColors.slate500,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      style: TextButton.styleFrom(
                        foregroundColor: SemsColors.blue600,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      child: Text(lang.t("Regístrate", "Sign up")),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
