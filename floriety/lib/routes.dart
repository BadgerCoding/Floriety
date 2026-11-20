import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../screens/scaffold_with_nav_bar.dart';
import '../screens/home_screen.dart';
import '../screens/history_screen.dart';
import '../screens/about_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/scan_flower_screen.dart';
import '../screens/ai_chatbot_screen.dart';
import '../screens/generate_flower_image_screen.dart';
import '../screens/result_screen.dart';
import '../screens/printable_result_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  refreshListenable: AuthService().authState,
  initialLocation: '/home',
  redirect: (context, state) {
    final auth = AuthService();
    if (!auth.isLoggedIn) {
      final protectedPaths = ['/history', '/profile'];
      if (protectedPaths.any((path) => state.uri.path.startsWith(path))) {
        return '/login';
      }
    }
    return null;
  },
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'scan',
              builder: (context, state) => const ScanFlowerScreen(),
            ),
            GoRoute(
              path: 'chatbot',
              builder: (context, state) => const AiChatbotScreen(),
            ),
            GoRoute(
              path: 'generate',
              builder: (context, state) => const GenerateFlowerImageScreen(),
            ),
            GoRoute(
              path: 'result',
              builder: (context, state) {
                final flowerData = state.extra as Map<String, String>?;
                return ResultScreen(flowerData: flowerData);
              },
              routes: [
                GoRoute(
                  path: 'printable',
                  builder: (context, state) {
                    final flowerData = state.extra as Map<String, String>?;
                    return PrintableResultScreen(flowerData: flowerData);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
      ],
    ),
  ],
);
