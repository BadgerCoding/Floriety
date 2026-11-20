import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groq_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class ScanFlowerScreen extends StatefulWidget {
  const ScanFlowerScreen({super.key});

  @override
  State<ScanFlowerScreen> createState() => _ScanFlowerScreenState();
}

class _ScanFlowerScreenState extends State<ScanFlowerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  String _statusText = 'Hold the flower like this';
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return;

      setState(() {
        _capturedImage = File(picked.path);
        _isAnalyzing = true;
        _statusText = 'AI is analyzing...';
      });

      final result = await GroqService.scanFlower(_capturedImage!);
      result['captured_image_path'] = _capturedImage!.path;

      // Save to history if logged in and it's a valid flower
      final auth = AuthService();
      String? saveWarning;
      if (auth.isLoggedIn && result['isFlower'] != 'false') {
        // Save the photo to cloud storage so it survives reinstalls/new phones.
        // If the upload fails, the scan is still saved (just without a photo).
        try {
          final bytes = await _capturedImage!.readAsBytes();
          final ext = _capturedImage!.path.split('.').last.toLowerCase();
          result['image_url'] = await ApiService.uploadImage(
            auth.token!,
            base64Encode(bytes),
            ext == 'png' ? 'image/png' : 'image/jpeg',
          );
        } catch (_) {
          saveWarning = 'Photo could not be uploaded to cloud storage.';
        }
        try {
          await ApiService.addHistory(auth.token!, result);
        } catch (e) {
          saveWarning =
              'Scan was not saved to your history: ${e.toString().replaceAll('Exception: ', '')}';
        }
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _statusText = 'Analysis complete!';
        });
        if (saveWarning != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(saveWarning),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
        // Navigate to result screen, passing flower data as extra
        context.go('/home/result', extra: result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _statusText = 'Target the bloom';
        });
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Scan flower',
          style: AppTypography.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: _isAnalyzing
                ? null
                : () => _pickAndAnalyze(ImageSource.camera),
            tooltip: 'Camera',
          ),
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white),
            onPressed: _isAnalyzing
                ? null
                : () => _pickAndAnalyze(ImageSource.gallery),
            tooltip: 'Gallery',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background: captured image or default bg
          _capturedImage != null
              ? Image.file(
                  _capturedImage!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                )
              : Image.asset(
                  'assets/4.png',
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.2),
                  colorBlendMode: BlendMode.darken,
                ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.25),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Scanner UI
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Viewfinder
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        // Corner brackets
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _buildCorner(top: true, left: true),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: _buildCorner(top: true, left: false),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: _buildCorner(top: false, left: true),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: _buildCorner(top: false, left: false),
                        ),

                        // Crosshair
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 16,
                                height: 1,
                                color: Colors.white.withOpacity(0.4),
                              ),
                              Container(
                                width: 1,
                                height: 16,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ],
                          ),
                        ),

                        // Animated scanning line (hide when analyzing)
                        if (!_isAnalyzing)
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Positioned(
                                top: _controller.value * 280,
                                left: 0,
                                right: 0,
                                child: Opacity(
                                  opacity:
                                      _controller.value < 0.1 ||
                                          _controller.value > 0.9
                                      ? 0.0
                                      : 1.0,
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primary.withOpacity(0.8),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                        // Loading spinner overlay
                        if (_isAnalyzing)
                          Center(
                            child: CircularProgressIndicator(
                              color: primary,
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                Text(
                  _statusText,
                  style: AppTypography.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isAnalyzing ? 'GROQ AI PROCESSING' : 'AI SCANNER ACTIVE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.0,
                    color: Colors.white60,
                  ),
                ),

                const Spacer(),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: GestureDetector(
          onTap: _isAnalyzing
              ? null
              : () => _pickAndAnalyze(ImageSource.camera),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isAnalyzing ? Colors.grey : primary,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: (_isAnalyzing ? Colors.grey : primary).withOpacity(
                    0.4,
                  ),
                  blurRadius: 32,
                ),
              ],
            ),
            child: _isAnalyzing
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(12) : Radius.zero,
          topRight: top && !left ? const Radius.circular(12) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(12) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(12) : Radius.zero,
        ),
      ),
    );
  }
}
