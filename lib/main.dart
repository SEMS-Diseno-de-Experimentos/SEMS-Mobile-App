import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/core/providers/theme_provider.dart';
import 'package:flutter_application_1/core/config/theme.dart';
import 'package:flutter_application_1/core/config/routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return MaterialApp.router(
      title: 'SEMS',
      theme: SemsTheme.light(),
      darkTheme: SemsTheme.dark(),
      themeMode: themeProvider.mode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
