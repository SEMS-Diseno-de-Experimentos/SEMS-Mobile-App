import 'dart:io';

void main() async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('Run this from the project root');
    return;
  }

  final fileMap = {
    'api.dart': 'core/config/api.dart',
    'routes.dart': 'core/config/routes.dart',
    'theme.dart': 'core/config/theme.dart',
    'sems_button.dart': 'core/widgets/sems_button.dart',
    'sems_card.dart': 'core/widgets/sems_card.dart',
    'sems_badge.dart': 'core/widgets/sems_badge.dart',
    'loading_widget.dart': 'core/widgets/loading_widget.dart',
    'error_widget.dart': 'core/widgets/error_widget.dart',
    'kpi_card.dart': 'core/widgets/kpi_card.dart',
    'consumption_chart.dart': 'core/widgets/consumption_chart.dart',
    'qr_scanner_modal.dart': 'features/monitoring/presentation/widgets/qr_scanner_modal.dart',
    'app_shell.dart': 'core/layout/app_shell.dart',
    'bottom_nav.dart': 'core/layout/bottom_nav.dart',
    'drawer_menu.dart': 'core/layout/drawer_menu.dart',
    'language_provider.dart': 'core/providers/language_provider.dart',
    'theme_provider.dart': 'core/providers/theme_provider.dart',
    'demo.dart': 'core/utils/demo.dart',
    'not_found_screen.dart': 'core/widgets/not_found_screen.dart',
    
    'user.dart': 'features/auth/domain/entities/user.dart',
    'auth_provider.dart': 'features/auth/presentation/providers/auth_provider.dart',
    'auth_service.dart': 'features/auth/data/repositories/auth_repository_impl.dart',
    'login_screen.dart': 'features/auth/presentation/screens/login_screen.dart',
    'register_screen.dart': 'features/auth/presentation/screens/register_screen.dart',
    'forgot_password_screen.dart': 'features/auth/presentation/screens/forgot_password_screen.dart',
    'reset_password_screen.dart': 'features/auth/presentation/screens/reset_password_screen.dart',
    'verify_account_screen.dart': 'features/auth/presentation/screens/verify_account_screen.dart',

    'dashboard.dart': 'features/dashboard/domain/entities/dashboard.dart',
    'dashboard_service.dart': 'features/dashboard/data/repositories/dashboard_repository_impl.dart',
    'dashboard_screen.dart': 'features/dashboard/presentation/screens/dashboard_screen.dart',

    'device.dart': 'features/devices/domain/entities/device.dart',
    'devices_service.dart': 'features/devices/data/repositories/devices_repository_impl.dart',
    'devices_screen.dart': 'features/devices/presentation/screens/devices_screen.dart',

    'energy.dart': 'features/monitoring/domain/entities/energy.dart',
    'energy_service.dart': 'features/monitoring/data/repositories/energy_repository_impl.dart',
    'monitoring_screen.dart': 'features/monitoring/presentation/screens/monitoring_screen.dart',

    'alert.dart': 'features/alerts/domain/entities/alert.dart',
    'alerts_service.dart': 'features/alerts/data/repositories/alerts_repository_impl.dart',
    'alerts_screen.dart': 'features/alerts/presentation/screens/alerts_screen.dart',

    'analytics.dart': 'features/analytics/domain/entities/analytics.dart',
    'analytics_service.dart': 'features/analytics/data/repositories/analytics_repository_impl.dart',
    'analytics_screen.dart': 'features/analytics/presentation/screens/analytics_screen.dart',
    'reports_screen.dart': 'features/analytics/presentation/screens/reports_screen.dart',

    'billing.dart': 'features/subscriptions/domain/entities/billing.dart',
    'subscriptions_service.dart': 'features/subscriptions/data/repositories/subscriptions_repository_impl.dart',
    'subscription_screen.dart': 'features/subscriptions/presentation/screens/subscription_screen.dart',

    'settings_screen.dart': 'features/settings/presentation/screens/settings_screen.dart',
    'household_screen.dart': 'features/settings/presentation/screens/household_screen.dart',
  };

  final classReplacements = {
    'AuthService': 'AuthRepositoryImpl',
    'DashboardService': 'DashboardRepositoryImpl',
    'DevicesService': 'DevicesRepositoryImpl',
    'EnergyService': 'EnergyRepositoryImpl',
    'AlertsService': 'AlertsRepositoryImpl',
    'AnalyticsService': 'AnalyticsRepositoryImpl',
    'SubscriptionsService': 'SubscriptionsRepositoryImpl',
  };

  // Find all Dart files in lib
  final allFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  
  // Track files to delete later (to avoid issues during reading)
  final filesToDelete = <File>[];

  // We need to do this in two passes:
  // 1. Read all files and calculate their new content and path.
  // 2. Write all new files.
  // 3. Delete old files.

  for (var file in allFiles) {
    final fileName = file.uri.pathSegments.last;
    
    if (fileName == 'main.dart') {
      // main.dart stays in place, just update contents
      var content = file.readAsStringSync();
      content = _updateImportsAndClasses(content, fileMap, classReplacements);
      file.writeAsStringSync(content);
      continue;
    }

    if (fileMap.containsKey(fileName)) {
      var content = file.readAsStringSync();
      content = _updateImportsAndClasses(content, fileMap, classReplacements);
      
      final newPath = 'lib/${fileMap[fileName]}';
      final newFile = File(newPath);
      newFile.parent.createSync(recursive: true);
      newFile.writeAsStringSync(content);
      
      filesToDelete.add(file);
    }
  }

  // Delete old files
  for (var file in filesToDelete) {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  // Cleanup empty directories
  _deleteEmptyDirs(libDir);
  
  print('Migration completed successfully!');
}

String _updateImportsAndClasses(String content, Map<String, String> fileMap, Map<String, String> classReplacements) {
  // Replace imports
  final importRegex = RegExp(r"import\s+['""](.*?([^/]+))['""];");
  content = content.replaceAllMapped(importRegex, (match) {
    final fullImport = match.group(1)!;
    final importedFileName = match.group(2)!;
    
    // Ignore package: imports unless they are ours (which they aren't yet)
    if (fullImport.startsWith('package:') && !fullImport.startsWith('package:flutter_application_1')) {
      return match.group(0)!;
    }
    
    if (fileMap.containsKey(importedFileName)) {
      return "import 'package:flutter_application_1/${fileMap[importedFileName]}';";
    }
    return match.group(0)!;
  });

  // Replace classes
  classReplacements.forEach((oldClass, newClass) {
    // Basic string replace is safe enough for these specific unique names
    content = content.replaceAll(oldClass, newClass);
  });

  return content;
}

void _deleteEmptyDirs(Directory dir) {
  for (var entity in dir.listSync()) {
    if (entity is Directory) {
      _deleteEmptyDirs(entity);
    }
  }
  if (dir.listSync().isEmpty) {
    dir.deleteSync();
  }
}
