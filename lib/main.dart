import 'package:flutter/material.dart';
import 'ui/dashboard_screen.dart';

final ValueNotifier<ThemeMode> appThemeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.dark);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WebRevenApp());
}

class WebRevenApp extends StatelessWidget {
  const WebRevenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'WebReven - Lead & Email Harvester',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D9488), // Emerald Teal
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF14B8A6),
              brightness: Brightness.dark,
              surface: const Color(0xFF121417),
              surfaceContainerHighest: const Color(0xFF1E2228),
            ),
            scaffoldBackgroundColor: const Color(0xFF0F1115),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Color(0xFF121417),
            ),
          ),
          home: const DashboardScreen(),
        );
      },
    );
  }
}
