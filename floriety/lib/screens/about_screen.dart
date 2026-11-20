import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.lightPrimary;
    final onSurface = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final cardBg = isDark
        ? AppColors.surfaceContainerLow
        : AppColors.lightSurfaceContainerLow;
    final outline = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'About',
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
              color: subColor,
            ),
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Header ──
            Text(
              'BOTANICAL INTELLIGENCE',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Floriety',
              style: GoogleFonts.manrope(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
                color: primary,
                height: 0.9,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Flower Variety and Disease Identifying System\nwith Care Recommendation',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: subColor,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 36),
            Divider(color: outline.withOpacity(0.2)),
            const SizedBox(height: 28),

            // ── Project Info ──
            _sectionLabel('PROJECT INSTITUTION', subColor),
            const SizedBox(height: 8),
            _infoCard(
              isDark,
              cardBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'South East Asian Institute of Technology',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'College of Information & Communication Technology',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: subColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Dedicated To ──
            _sectionLabel('DEDICATED TO', subColor),
            const SizedBox(height: 8),
            _infoCard(
              isDark,
              cardBg,
              child: Text(
                'Jho Flowershop...and all botanists, shop owners, and plant lovers\nwho deserve better tools to identify, understand, and care for flowers.',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: onSurface,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Developers ──
            _sectionLabel('DEVELOPED BY', subColor),
            const SizedBox(height: 8),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _developerCard(
                        'Beejay H.\nBalajadia',
                        primary,
                        cardBg,
                        onSurface,
                        subColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: _developerCard(
                        'Remy Jay\nLatorza',
                        primary,
                        cardBg,
                        onSurface,
                        subColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _developerCard(
                        'Ian Paul\nTadao',
                        primary,
                        cardBg,
                        onSurface,
                        subColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: _developerCard(
                        'John Michael\nBalderas',
                        primary,
                        cardBg,
                        onSurface,
                        subColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── What It Does ──
            _sectionLabel('ABOUT THE SYSTEM', subColor),
            const SizedBox(height: 8),
            _infoCard(
              isDark,
              cardBg,
              child: Text(
                'Floriety combines AI-powered image recognition with a mobile-first interface to help users identify flower varieties, detect plant diseases, learn about allergens, and receive personalized care recommendations — all from a single photo.',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: onSurface,
                  height: 1.65,
                ),
              ),
            ),

            const SizedBox(height: 16),
            _infoCard(
              isDark,
              cardBg,
              child: Text(
                'Terms & Conditions: This system is not yet official and is provided only for research and testing purposes. Use it as a prototype tool, not as a final production service.',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: onSurface,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Core Features ──
            _sectionLabel('CORE FEATURES', subColor),
            const SizedBox(height: 8),
            _featureRow(
              Icons.center_focus_strong,
              'AI Flower Scanning & Recognition',
              primary,
              cardBg,
              onSurface,
              subColor,
            ),
            const SizedBox(height: 10),
            _featureRow(
              Icons.info_outline,
              'Flower Information & Description',
              primary,
              cardBg,
              onSurface,
              subColor,
            ),
            const SizedBox(height: 10),
            _featureRow(
              Icons.warning_amber_rounded,
              'Allergy Information Display',
              primary,
              cardBg,
              onSurface,
              subColor,
            ),
            const SizedBox(height: 10),
            _featureRow(
              Icons.health_and_safety,
              'Disease Detection & Care Tips',
              primary,
              cardBg,
              onSurface,
              subColor,
            ),
            const SizedBox(height: 10),
            _featureRow(
              Icons.photo_library_outlined,
              'Photo Upload & Gallery Analysis',
              primary,
              cardBg,
              onSurface,
              subColor,
            ),

            const SizedBox(height: 36),
            Divider(color: outline.withOpacity(0.2)),
            const SizedBox(height: 28),

            // ── Footer ──
            Center(
              child: Column(
                children: [
                  Text(
                    'APRIL 2026',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      color: subColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'In partial fulfillment of the requirements for the subject\nin Information Technology',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: outline,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.5,
        color: color,
      ),
    );
  }

  Widget _infoCard(bool isDark, Color bg, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _developerCard(
    String name,
    Color primary,
    Color bg,
    Color onSurface,
    Color subColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline, color: primary, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Developer',
            style: GoogleFonts.inter(fontSize: 10, color: subColor),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(
    IconData icon,
    String label,
    Color primary,
    Color bg,
    Color onSurface,
    Color subColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: primary.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
