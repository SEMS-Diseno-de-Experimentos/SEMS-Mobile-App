import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/core/providers/theme_provider.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentPath = GoRouterState.of(context).matchedLocation;

    Widget buildItem({
      required IconData icon,
      required String title,
      required String path,
    }) {
      final isSelected = currentPath == path;
      return ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? SemsColors.blue600
              : (isDark ? SemsColors.slate400 : SemsColors.slate500),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? SemsColors.blue600
                : (isDark ? SemsColors.slate200 : SemsColors.slate700),
          ),
        ),
        selected: isSelected,
        selectedTileColor: isDark ? SemsColors.navy800 : SemsColors.blue50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          if (!isSelected) {
            context.go(path);
          }
        },
      );
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.electric_bolt, color: SemsColors.blue600, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'SEMS',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  buildItem(
                    icon: Icons.dashboard_outlined,
                    title: lang.t('Resumen', 'Overview'),
                    path: '/',
                  ),
                  buildItem(
                    icon: Icons.devices_outlined,
                    title: lang.t('Dispositivos', 'Devices'),
                    path: '/devices',
                  ),
                  buildItem(
                    icon: Icons.bolt_outlined,
                    title: lang.t('Monitoreo', 'Monitoring'),
                    path: '/monitoring',
                  ),
                  buildItem(
                    icon: Icons.analytics_outlined,
                    title: lang.t('Analíticas', 'Analytics'),
                    path: '/analytics',
                  ),
                  buildItem(
                    icon: Icons.notifications_none,
                    title: lang.t('Alertas', 'Alerts'),
                    path: '/alerts',
                  ),
                  buildItem(
                    icon: Icons.description_outlined,
                    title: lang.t('Reportes', 'Reports'),
                    path: '/reports',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  buildItem(
                    icon: Icons.credit_card_outlined,
                    title: lang.t('Suscripción', 'Subscription'),
                    path: '/subscription',
                  ),
                  buildItem(
                    icon: Icons.business_outlined,
                    title: lang.t('Mi organización', 'My Organization'),
                    path: '/household',
                  ),
                  buildItem(
                    icon: Icons.settings_outlined,
                    title: lang.t('Configuración', 'Settings'),
                    path: '/settings',
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: SemsColors.blue600,
                    child: Text(
                      auth.user?.fullName.isNotEmpty == true
                          ? auth.user!.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.fullName ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          auth.user?.email ?? '',
                          style: TextStyle(
                            color: isDark ? SemsColors.slate400 : SemsColors.slate500,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
                      await auth.logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => lang.toggle(),
                    icon: const Icon(Icons.language, size: 16),
                    label: Text(lang.isEs ? 'ES' : 'EN'),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? SemsColors.slate300 : SemsColors.slate600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => themeProvider.toggle(),
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 16),
                    label: Text(isDark ? lang.t('Claro', 'Light') : lang.t('Oscuro', 'Dark')),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? SemsColors.slate300 : SemsColors.slate600,
                    ),
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
