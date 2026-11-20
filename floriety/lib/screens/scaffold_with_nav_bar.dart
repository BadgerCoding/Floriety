import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.child,
    super.key,
  });

  final Widget child;

  static void showAuthGateDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.lightPrimary;
    final onSurface = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant;
    final cardBg = isDark ? AppColors.surfaceContainerHigh : AppColors.lightSurfaceContainerHigh;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                    ),
                    child: Icon(Icons.close, size: 18, color: subColor),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Lock icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withOpacity(0.12),
                ),
                child: Icon(Icons.lock_outline, color: primary, size: 32),
              ),

              const SizedBox(height: 20),

              // Message
              Text(
                'You are not logged in to access this feature',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: subColor,
                ),
              ),

              const SizedBox(height: 28),

              // Login button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                      colors: [primary, isDark ? AppColors.primaryContainer : AppColors.lightPrimaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                    ),
                    child: Text(
                      'Login',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.onPrimary : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Sign up button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/register');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primary.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  ),
                  child: Text(
                    'Sign Up',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: primary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Determine the current index from the route.
    final String location = GoRouterState.of(context).uri.path;
    int currentIndex = _calculateSelectedIndex(location);

    final navBg = isDark
        ? AppColors.surfaceContainerLow.withOpacity(0.8)
        : AppColors.lightSurfaceContainerLow.withOpacity(0.8);
    final navBorder = isDark
        ? AppColors.surfaceContainerHighest.withOpacity(0.3)
        : AppColors.lightSurfaceContainerHighest.withOpacity(0.3);

    return Scaffold(
      backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: navBorder)),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.primary : AppColors.lightPrimary).withOpacity(0.1),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: (isDark ? AppColors.primary : AppColors.lightPrimary).withOpacity(0.1),
          selectedIndex: currentIndex,
          onDestinationSelected: (int index) => _onItemTapped(index, context),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: isDark ? AppColors.primary : AppColors.lightPrimary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: isDark ? AppColors.primary : AppColors.lightPrimary),
              label: 'History',
            ),
            NavigationDestination(
              icon: const Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info, color: isDark ? AppColors.primary : AppColors.lightPrimary),
              label: 'About',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: isDark ? AppColors.primary : AppColors.lightPrimary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(String location) {
    if (location.startsWith('/home')) {
      return 0;
    }
    if (location.startsWith('/history')) {
      return 1;
    }
    if (location.startsWith('/about')) {
      return 2;
    }
    if (location.startsWith('/profile')) {
      return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    final auth = AuthService();
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        if (auth.isLoggedIn) {
          context.go('/history');
        } else {
          showAuthGateDialog(context);
        }
        break;
      case 2:
        context.go('/about');
        break;
      case 3:
        if (auth.isLoggedIn) {
          context.go('/profile');
        } else {
          showAuthGateDialog(context);
        }
        break;
    }
  }
}
