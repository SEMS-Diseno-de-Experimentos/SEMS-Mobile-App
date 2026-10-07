import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_application_1/core/layout/drawer_menu.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Only show bottom nav if authenticated.
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: auth.isAuthenticated
          ? AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              iconTheme: IconThemeData(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            )
          : null,
      drawer: auth.isAuthenticated ? const DrawerMenu() : null,
      body: child,
    );
  }
}
