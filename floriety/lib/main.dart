import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme/colors.dart';
import 'theme/typography.dart';
import 'services/auth_service.dart';

// Global theme notifier — toggled by dark mode button in any screen
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().init();
  themeNotifier.value = AuthService().isDark ? ThemeMode.dark : ThemeMode.light;
  runApp(const FlorietyApp());
}

class FlorietyApp extends StatelessWidget {
  const FlorietyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp.router(
          title: 'Floriety',
          theme: ThemeData(
            colorScheme: AppColors.lightColorScheme,
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.lightSurface,
            textTheme: AppTypography.textTheme,
          ),
          darkTheme: ThemeData(
            colorScheme: AppColors.colorScheme,
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.surface,
            textTheme: AppTypography.textTheme,
          ),
          themeMode: mode,
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
