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
              seedColor: const Color(0xFF10B981), // Emerald Green
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
              seedColor: const Color(0xFF00E676), // Cyber Neon Green
              brightness: Brightness.dark,
              surface: const Color(0xFF101413),
              surfaceContainerHighest: const Color(0xFF18221D),
            ),
            scaffoldBackgroundColor: const Color(0xFF0B0F0D),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Color(0xFF101413),
            ),
          ),
          home: const DashboardScreen(),
        );
      },
    );
  }
}
