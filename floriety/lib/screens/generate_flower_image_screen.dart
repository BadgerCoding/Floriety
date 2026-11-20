import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groq_service.dart';
import '../../main.dart';

class GenerateFlowerImageScreen extends StatefulWidget {
  const GenerateFlowerImageScreen({super.key});

  @override
  State<GenerateFlowerImageScreen> createState() =>
      _GenerateFlowerImageScreenState();
}

class _GenerateFlowerImageScreenState extends State<GenerateFlowerImageScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  Map<String, String>? _result;
  String? _imageUrl;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _result = null;
      _imageUrl = null;
    });

    try {
      // Step 1: Identify the flower from description via Groq
      final flowerData = await GroqService.identifyFlower(prompt);

      // Step 2: Build a Pollinations.ai image URL from the image prompt
      final imagePrompt =
          (flowerData['imagePrompt'] ?? flowerData['name'] ?? 'flower')
              .replaceAll(' ', '+');
      final url =
          'https://image.pollinations.ai/prompt/$imagePrompt?width=512&height=512&nologo=true';

      if (mounted) {
        setState(() {
          _result = flowerData;
          _imageUrl = url;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.lightPrimary;
    final onSurface = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;
    final cardBg = isDark
        ? AppColors.surfaceContainerLow
        : AppColors.lightSurfaceContainerLow;
    final inputBg = isDark
        ? AppColors.surfaceContainerHighest
        : AppColors.lightSurfaceContainerHighest;
    final outline = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'AI Flower',
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
            Text(
              'BOTANICAL SYNTHESIZER',
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: primary,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: AppTypography.textTheme.headlineLarge?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
                children: [
                  const TextSpan(text: 'Describe your '),
                  TextSpan(
                    text: 'vision.',
                    style: TextStyle(color: primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Describe a flower by its traits and our AI will identify and generate it for you.',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: subColor,
              ),
            ),
            const SizedBox(height: 32),

            // Input Area
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: outline.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _promptController,
                    maxLines: 4,
                    minLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      hintText:
                          'e.g. "Flower that has thorns and poison", "tiny blue wildflower with 5 petals"...',
                      hintStyle: TextStyle(
                        color: subColor.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: onSurface, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Notice: Due to high traffic, only 1 image can be generated every 30 mins.',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: subColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _generate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: isDark
                            ? AppColors.onPrimary
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 0,
                      ),
                      child: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'GENERATE',
                              style: AppTypography.textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.onPrimary
                                        : Colors.white,
                                  ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Result Area
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.hardEdge,
              child: _result == null
                  ? Padding(
                      padding: const EdgeInsets.all(48),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            child: _buildBracket(true, true, primary),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _buildBracket(true, false, primary),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: _buildBracket(false, true, primary),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: _buildBracket(false, false, primary),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.surfaceContainerHighest
                                        : AppColors
                                              .lightSurfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: primary.withOpacity(0.4),
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Your AI flower will appear here',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.textTheme.titleMedium
                                      ?.copyWith(
                                        color: onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Describe any flower by its characteristics and let AI find and visualize it.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.textTheme.bodyMedium
                                      ?.copyWith(color: subColor, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Generated image
                        if (_imageUrl != null)
                          SizedBox(
                            width: double.infinity,
                            height: 280,
                            child: Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 280,
                                  color: isDark
                                      ? AppColors.surfaceContainerHighest
                                      : AppColors.lightSurfaceContainerHighest,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          color: primary,
                                          strokeWidth: 2,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Generating image...',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: subColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                height: 160,
                                color: isDark
                                    ? AppColors.surfaceContainerHighest
                                    : AppColors.lightSurfaceContainerHighest,
                                child: Center(
                                  child: Icon(
                                    Icons.local_florist,
                                    color: primary,
                                    size: 64,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Flower info
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI IDENTIFIED',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _result!['name'] ?? 'Unknown Flower',
                                style: AppTypography.textTheme.headlineSmall
                                    ?.copyWith(
                                      color: onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if ((_result!['scientific'] ?? '')
                                  .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _result!['scientific']!,
                                  style: AppTypography.textTheme.bodyMedium
                                      ?.copyWith(
                                        color: subColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ],
                              if ((_result!['description'] ?? '')
                                  .isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _result!['description']!,
                                  style: AppTypography.textTheme.bodyMedium
                                      ?.copyWith(color: onSurface, height: 1.5),
                                ),
                              ],
                            ],
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
}
