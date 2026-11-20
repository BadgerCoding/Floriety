import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';

class PrintableResultScreen extends StatelessWidget {
  final Map<String, String>? flowerData;
  const PrintableResultScreen({super.key, this.flowerData});

  Map<String, String> get _data => flowerData ?? {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;
    final cardBg = isDark ? AppColors.surfaceContainerLow : AppColors.lightSurfaceContainerLow;
    final onSurface = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant;

    final flowerName = _data['name'] ?? 'Unknown Flower';
    final imageQuery = Uri.encodeComponent(flowerName);
    final onlineImageUrl = 'https://source.unsplash.com/600x400/?$imageQuery,flower';

    final careLines = (_data['care_list'] ?? '')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Printable Result',
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
              color: isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant,
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Document header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.description_rounded, color: primary, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FLORIETY SCAN REPORT',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                color: primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              flowerName,
                              style: AppTypography.textTheme.titleLarge?.copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _data['scientific'] ?? '',
                              style: AppTypography.textTheme.bodySmall?.copyWith(
                                color: subColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Online Reference image
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: cardBg,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Image.network(
                    onlineImageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Center(child: CircularProgressIndicator(color: primary, strokeWidth: 2));
                    },
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.local_florist, size: 48, color: primary.withOpacity(0.3)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // All info in document rows
                _docSection('Flower Name', _data['name'] ?? 'N/A', onSurface, subColor, cardBg),
                _docSection('Flower Family', _data['family'] ?? 'N/A', onSurface, subColor, cardBg),
                _docSection('Scientific Name', _data['scientific'] ?? 'N/A', onSurface, subColor, cardBg, italic: true),
                _docSection('Variety & Appearance', _data['variety_appearance'] ?? 'N/A', onSurface, subColor, cardBg),
                _docSection('Origin', _data['origin'] ?? 'N/A', onSurface, subColor, cardBg),
                _docSection('Where to Find', _data['habitat'] ?? 'N/A', onSurface, subColor, cardBg),
                _docSection('Allergen', _data['allergen'] ?? 'N/A', onSurface, subColor, cardBg),
                _docSection('Disease Status', _data['disease'] ?? 'N/A', onSurface, subColor, cardBg),

                const SizedBox(height: 8),

                // Care Recommendation
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Care Recommendation',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: subColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...careLines.map((line) {
                        final match = RegExp(r'^(\d+)\.\s*(.*)').firstMatch(line);
                        final number = match?.group(1) ?? '';
                        final text = match?.group(2) ?? line;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$number. ',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.primary : AppColors.lightPrimary,
                                  )),
                              Expanded(
                                child: Text(text,
                                    style: AppTypography.textTheme.bodySmall?.copyWith(
                                      color: onSurface, height: 1.5)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Description
                if ((_data['description'] ?? '').isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: subColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _data['description'] ?? '',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: onSurface,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Generated by Floriety AI • Botanical Intelligence',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: subColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom buttons
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: bg,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download as Text File'),
                      onPressed: () => _downloadTextFile(context, flowerName, careLines, subColor),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.home_rounded,
                          color: isDark ? AppColors.primary : AppColors.lightPrimary),
                      label: Text(
                        'Go Back Home',
                        style: TextStyle(
                          color: isDark ? AppColors.primary : AppColors.lightPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => context.go('/home'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? AppColors.primary : AppColors.lightPrimary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docSection(String label, String value, Color onSurface, Color subColor, Color cardBg, {bool italic = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: subColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadTextFile(BuildContext context, String flowerName, List<String> careLines, Color subColor) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeFileName = flowerName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final file = File('${dir.path}/floriety_${safeFileName}.txt');

      final buffer = StringBuffer();
      buffer.writeln('=== FLORIETY SCAN REPORT ===');
      buffer.writeln('Generated by Floriety AI');
      buffer.writeln('');
      buffer.writeln('Flower Name: ${_data['name'] ?? 'N/A'}');
      buffer.writeln('Flower Family: ${_data['family'] ?? 'N/A'}');
      buffer.writeln('Scientific Name: ${_data['scientific'] ?? 'N/A'}');
      buffer.writeln('Variety & Appearance: ${_data['variety_appearance'] ?? 'N/A'}');
      buffer.writeln('Origin: ${_data['origin'] ?? 'N/A'}');
      buffer.writeln('Where to Find: ${_data['habitat'] ?? 'N/A'}');
      buffer.writeln('Allergen: ${_data['allergen'] ?? 'N/A'}');
      buffer.writeln('Disease Status: ${_data['disease'] ?? 'N/A'}');
      buffer.writeln('');
      buffer.writeln('--- Care Recommendation ---');
      for (final line in careLines) {
        buffer.writeln(line);
      }
      buffer.writeln('');
      buffer.writeln('--- Description ---');
      buffer.writeln(_data['description'] ?? '');

      await file.writeAsString(buffer.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to: ${file.path}'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}
