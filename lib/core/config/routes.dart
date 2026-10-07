import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:flutter_application_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_application_1/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_application_1/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter_application_1/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter_application_1/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:flutter_application_1/features/auth/presentation/screens/verify_account_screen.dart';
import 'package:flutter_application_1/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter_application_1/features/devices/presentation/screens/devices_screen.dart';
import 'package:flutter_application_1/features/monitoring/presentation/screens/monitoring_screen.dart';
import 'package:flutter_application_1/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:flutter_application_1/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:flutter_application_1/features/analytics/presentation/screens/reports_screen.dart';
import 'package:flutter_application_1/features/subscriptions/presentation/screens/subscription_screen.dart';
import 'package:flutter_application_1/features/settings/presentation/screens/household_screen.dart';
import 'package:flutter_application_1/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_application_1/core/widgets/not_found_screen.dart';
import 'package:flutter_application_1/core/layout/app_shell.dart';

// Placeholder for main screens
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Center(child: Text(title));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  errorBuilder: (context, state) => const NotFoundScreen(),
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();
    final isGoingToAuth = state.matchedLocation.startsWith('/login') ||
        state.matchedLocation.startsWith('/register') ||
        state.matchedLocation.startsWith('/forgot-password') ||
        state.matchedLocation.startsWith('/reset-password') ||
        state.matchedLocation.startsWith('/verify');
    
    // Auth redirect logic
    if (!auth.isAuthenticated && !isGoingToAuth) {
      return '/login';
    }
    if (auth.isAuthenticated && isGoingToAuth) {
      return '/';
    }
    return null;
  },
  routes: [
    // Auth Routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => ResetPasswordScreen(
        token: state.uri.queryParameters['token'] ?? '',
      ),
    ),
    GoRoute(
      path: '/verify',
      builder: (context, state) => VerifyAccountScreen(
        token: state.uri.queryParameters['token'] ?? '',
      ),
    ),
    // App Shell Route
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/devices',
          builder: (context, state) => const DevicesScreen(),
        ),
        GoRoute(
          path: '/monitoring',
          builder: (context, state) => const MonitoringScreen(),
        ),
        GoRoute(
          path: '/alerts',
          builder: (context, state) => const AlertsScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/subscription',
          builder: (context, state) => const SubscriptionScreen(),
        ),
        GoRoute(
          path: '/household',
          builder: (context, state) => const HouseholdScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
