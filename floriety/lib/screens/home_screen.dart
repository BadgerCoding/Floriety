import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../services/auth_service.dart';
import 'scaffold_with_nav_bar.dart';
import 'feedback_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _onFeedbackTap(BuildContext context) {
    final auth = AuthService();
    if (auth.isLoggedIn) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FeedbackScreen()));
    } else {
      ScaffoldWithNavBar.showAuthGateDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Floriety',
          style: AppTypography.textTheme.headlineSmall?.copyWith(
            color: primary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark
                  ? AppColors.onSurfaceVariant
                  : AppColors.lightOnSurfaceVariant,
            ),
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero section
                Text(
                  'BOTANICAL INTELLIGENCE',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.0,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Digital Field Guide',
                  style: AppTypography.textTheme.displaySmall?.copyWith(
                    color: isDark
                        ? AppColors.onSurface
                        : AppColors.lightOnSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI scanner system',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.onSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),

                // Feature Cards
                _buildFeatureCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.camera_alt,
                  iconColor: primary,
                  title: 'Scan flower',
                  subtitle: 'Identify species instantly via AI',
                  route: '/home/scan',
                  bgAsset: 'assets/1.png',
                ),
                const SizedBox(height: 20),
                _buildFeatureCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.chat_bubble,
                  iconColor: const Color(0xFF4CAF50),
                  title: 'Floriety AI',
                  subtitle: 'Ask questions about care & history',
                  route: '/home/chatbot',
                  bgAsset: 'assets/2.png',
                ),
                const SizedBox(height: 20),
                _buildFeatureCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.auto_awesome,
                  iconColor: const Color(0xFF7B61FF),
                  title: 'AI Flower',
                  subtitle: 'Describe a flower, get an image',
                  route: '/home/generate',
                  bgAsset: 'assets/5.png',
                ),

                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),

          // Floating feedback button
          Positioned(
            bottom: 24,
            right: 24,
            child: GestureDetector(
              onTap: () => _onFeedbackTap(context),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primary,
                      isDark
                          ? AppColors.primaryContainer
                          : AppColors.lightPrimaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.help_outline,
                  color: isDark ? AppColors.onPrimary : Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String route,
    required String bgAsset,
  }) {
    final cardBg = isDark
        ? AppColors.surfaceContainerHigh
        : AppColors.lightSurfaceContainerHigh;
    final textColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return GestureDetector(
      onTap: () {
        context.go(route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                (isDark
                        ? AppColors.outlineVariant
                        : AppColors.lightOutlineVariant)
                    .withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned(
              right: -32,
              top: -32,
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  bgAsset,
                  width: 128,
                  height: 128,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withOpacity(0.12),
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.textTheme.titleLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: subColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
