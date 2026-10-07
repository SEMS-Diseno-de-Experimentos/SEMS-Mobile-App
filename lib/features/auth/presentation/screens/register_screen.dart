import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/core/widgets/sems_button.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.electric_bolt, size: 48, color: SemsColors.blue600),
                const SizedBox(height: 16),
                Text(
                  lang.t("Crear cuenta", "Create account"),
                  style: const TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: SemsColors.rose500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SemsColors.rose500.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: SemsColors.rose500, fontSize: 13),
                    ),
                  ),
                Text(lang.t("Email", "Email"), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(controller: _emailCtrl, decoration: const InputDecoration(hintText: "tu@email.com")),
                const SizedBox(height: 16),
                Text(lang.t("Password", "Password"), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(hintText: "••••••••")),
                const SizedBox(height: 32),
                SemsButton(
                  text: lang.t("Registrarse", "Sign up"),
                  isLoading: auth.isLoading,
                  isFullWidth: true,
                  onPressed: () async {
                    setState(() => _errorMessage = null);
                    try {
                      await auth.register(_emailCtrl.text, _passCtrl.text);
                      if (context.mounted) context.go('/');
                    } catch (e) {
                      setState(() {
                        String msg = e.toString();
                        if (msg.startsWith('Exception: ')) {
                          msg = msg.replaceFirst('Exception: ', '');
                        }
                        _errorMessage = msg.isNotEmpty ? msg : lang.t("Error al registrarse.", "Registration failed.");
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
