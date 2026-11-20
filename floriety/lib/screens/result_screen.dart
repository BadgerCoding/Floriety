import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, String>? flowerData;
  const ResultScreen({super.key, this.flowerData});

  Map<String, String> get _data =>
      flowerData ??
      {
        'isFlower': 'true',
        'name': 'Common Sunflower',
        'scientific': 'Helianthus annuus',
        'family': 'Asteraceae',
        'variety_appearance':
            'Russian Mammoth Giant – tall with bright yellow ray florets',
        'origin': 'North America',
        'habitat': 'Open fields, prairies, and sunny meadows',
        'allergen': 'Yes – Pollen may cause hay fever',
        'disease': 'None detected',
        'care_list':
            '1. Water deeply once a week\n2. Full sun (6–8 hours daily)\n3. Well-draining, slightly acidic soil\n4. Fertilize monthly with balanced fertilizer\n5. Stake tall varieties to prevent wind damage',
        'description':
            'A tall, sun-tracking annual with bright yellow ray florets that follow the sun throughout the day, symbolizing warmth and vitality.',
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.lightPrimary;
    final onSurface = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;
    final isFlower = _data['isFlower'] != 'false';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => context.go('/home'),
        ),
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
      body: isFlower
          ? _buildFlowerResult(context, isDark, primary, onSurface, bg)
          : _buildNoFlowerDetected(context, isDark, primary, bg),
    );
  }

  Widget _buildNoFlowerDetected(
    BuildContext context,
    bool isDark,
    Color primary,
    Color bg,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 60,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Flower Detected',
              style: AppTypography.textTheme.headlineSmall?.copyWith(
                color: isDark ? AppColors.onSurface : AppColors.lightOnSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'The image doesn\'t appear to contain a flower or plant. Try capturing a clearer photo with the bloom and leaves visible.',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.onSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Try Again'),
              onPressed: () => context.go('/home/scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/home'),
              child: Text('Go Back Home', style: TextStyle(color: primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowerResult(
    BuildContext context,
    bool isDark,
    Color primary,
    Color onSurface,
    Color bg,
  ) {
    final flowerName = _data['name'] ?? 'Unknown Flower';
    final capturedImagePath = _data['captured_image_path'];
    final imageQuery = Uri.encodeComponent(flowerName);
    final cloudImageUrl = _data['image_url'] ?? '';
    final onlineImageUrl = cloudImageUrl.isNotEmpty
        ? cloudImageUrl
        : 'https://source.unsplash.com/600x400/?$imageQuery,flower';

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Scanned Image ──
              _buildScannedImage(
                capturedImagePath,
                onlineImageUrl,
                primary,
                isDark,
                flowerName,
              ),

              const SizedBox(height: 24),

              // ── Info Cards ──
              _buildInfoTile(
                Icons.local_florist,
                'Flower Name',
                _data['name'] ?? 'Unknown',
                primary,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                Icons.account_tree,
                'Flower Family',
                _data['family'] ?? 'N/A',
                primary,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                Icons.auto_awesome,
                'Flower Variety & Appearance',
                _data['variety_appearance'] ?? 'N/A',
                primary,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                Icons.public,
                'Flower Origin',
                _data['origin'] ?? 'N/A',
                primary,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                Icons.landscape,
                'Where Can You See This?',
                _data['habitat'] ?? 'N/A',
                primary,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                Icons.warning_amber_rounded,
                'Allergen',
                _data['allergen'] ?? 'N/A',
                primary,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                Icons.health_and_safety,
                'Flower Disease',
                _data['disease'] ?? 'N/A',
                primary,
                isDark,
              ),

              const SizedBox(height: 12),

              // ── Care Recommendation ──
              _buildCareSection(
                _data['care_list'] ?? '',
                primary,
                isDark,
                onSurface,
              ),

              const SizedBox(height: 12),

              // ── Description ──
              if ((_data['description'] ?? '').isNotEmpty)
                _buildDescriptionSection(
                  _data['description'] ?? '',
                  isDark,
                  onSurface,
                ),
            ],
          ),
        ),

        // ── Bottom Buttons ──
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: bg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Go Back Home'),
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.print_rounded, color: primary),
                    label: Text(
                      'View Printable Result',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () =>
                        context.go('/home/result/printable', extra: flowerData),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScannedImage(
    String? imagePath,
    String url,
    Color primary,
    bool isDark,
    String flowerName,
  ) {
    final useLocalImage = imagePath != null && imagePath.isNotEmpty;
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerLow
            : AppColors.lightSurfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(0.15), blurRadius: 40),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (useLocalImage)
            Image.file(
              File(imagePath),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_florist,
                      size: 48,
                      color: primary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image unavailable',
                      style: TextStyle(color: primary.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
            )
          else
            Image.network(
              url,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: primary,
                    strokeWidth: 2,
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_florist,
                      size: 48,
                      color: primary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image unavailable',
                      style: TextStyle(color: primary.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
            ),
          // Brackets
          Positioned(
            top: 20,
            left: 20,
            child: _buildBracket(true, true, primary),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: _buildBracket(true, false, primary),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: _buildBracket(false, true, primary),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildBracket(false, false, primary),
          ),
          // Label badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    useLocalImage ? Icons.camera_alt : Icons.image_search,
                    size: 12,
                    color: primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    useLocalImage ? 'SCANNED IMAGE' : 'ONLINE REFERENCE IMAGE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom label
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                ),
              ),
              child: Text(
                'ANALYSIS COMPLETE',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareSection(
    String careList,
    Color primary,
    bool isDark,
    Color onSurface,
  ) {
    final cardBg = isDark
        ? AppColors.surfaceContainerLow
        : AppColors.lightSurfaceContainerLow;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    // Parse numbered list
    final lines = careList
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.eco, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'CARE RECOMMENDATION',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: subColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...lines.map((line) {
            // Try to strip leading number+dot for display
            final match = RegExp(r'^(\d+)\.\s*(.*)').firstMatch(line);
            final number = match?.group(1) ?? '';
            final text = match?.group(2) ?? line;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        number,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(
    String description,
    bool isDark,
    Color onSurface,
  ) {
    final cardBg = isDark
        ? AppColors.surfaceContainerLow
        : AppColors.lightSurfaceContainerLow;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESCRIPTION',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: subColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: onSurface,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracket(bool top, bool left, Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: color, width: 2) : BorderSide.none,
          bottom: !top ? BorderSide(color: color, width: 2) : BorderSide.none,
          left: left ? BorderSide(color: color, width: 2) : BorderSide.none,
          right: !left ? BorderSide(color: color, width: 2) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
    Color primary,
    bool isDark,
  ) {
    final cardBg = isDark
        ? AppColors.surfaceContainerLow
        : AppColors.lightSurfaceContainerLow;
    final textColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
