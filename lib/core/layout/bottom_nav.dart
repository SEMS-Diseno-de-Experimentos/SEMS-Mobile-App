import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final path = GoRouterState.of(context).matchedLocation;
    
    int currentIndex = 0;
    if (path.startsWith('/devices')) {
      currentIndex = 1;
    } else if (path.startsWith('/monitoring')) {
      currentIndex = 2;
    } else if (path.startsWith('/alerts')) {
      currentIndex = 3;
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/devices');
            break;
          case 2:
            context.go('/monitoring');
            break;
          case 3:
            context.go('/alerts');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard_outlined),
          activeIcon: const Icon(Icons.dashboard),
          label: lang.t('Resumen', 'Overview'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.devices_outlined),
          activeIcon: const Icon(Icons.devices),
          label: lang.t('Dispositivos', 'Devices'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.bolt_outlined),
          activeIcon: const Icon(Icons.bolt),
          label: lang.t('Monitoreo', 'Monitoring'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.notifications_none),
          activeIcon: const Icon(Icons.notifications),
          label: lang.t('Alertas', 'Alerts'),
        ),
      ],
    );
  }
}
