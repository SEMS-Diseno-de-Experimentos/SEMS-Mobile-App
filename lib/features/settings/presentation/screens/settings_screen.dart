import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/core/providers/theme_provider.dart';
import 'package:flutter_application_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_application_1/core/widgets/sems_card.dart';
import 'package:flutter_application_1/core/widgets/sems_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.user?.fullName ?? '');
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    await Future.delayed(const Duration(milliseconds: 600)); // Simulating network req
    await auth.updateProfile(fullName: _nameCtrl.text);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<LanguageProvider>().t("Perfil guardado", "Profile saved"))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t("Configuración", "Settings"), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              lang.t("Perfil", "Profile"),
              style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SemsCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.t("Nombre Completo", "Full Name"), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                  ),
                  const SizedBox(height: 16),
                  Text(lang.t("Correo Electrónico (No modificable)", "Email (Uneditable)"), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: TextEditingController(text: auth.user?.email ?? ''),
                    enabled: false,
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SemsButton(
                      text: lang.t("Guardar cambios", "Save changes"),
                      isLoading: _saving,
                      onPressed: _saveProfile,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              lang.t("Preferencias", "Preferences"),
              style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SemsCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(lang.t("Modo Oscuro", "Dark Mode")),
                    subtitle: Text(lang.t("Cambia la apariencia visual", "Change visual appearance")),
                    value: themeProvider.isDark,
                    onChanged: (v) => themeProvider.toggle(),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(lang.t("Idioma (Inglés)", "Language (English)")),
                    subtitle: Text(lang.t("Cambiar entre ES/EN", "Switch between ES/EN")),
                    value: lang.isEn,
                    onChanged: (v) => lang.toggle(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
