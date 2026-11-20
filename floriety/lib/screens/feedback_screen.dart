import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _auth = AuthService();
  final _gmailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill gmail with user email
    _gmailController.text = _auth.email ?? '';
  }

  @override
  void dispose() {
    _gmailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final gmail = _gmailController.text.trim();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Subject and message are required'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await ApiService.submitFeedback(
        _auth.token!,
        gmail: gmail,
        subject: subject,
        message: message,
      );
      if (mounted) {
        _subjectController.clear();
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Feedback sent! Thank you.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.lightPrimary;
    final onSurface = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant;
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;
    final inputBg = isDark ? AppColors.surfaceContainerHigh : AppColors.lightSurfaceContainerHigh;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: subColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Send Feedback',
          style: AppTypography.textTheme.headlineSmall?.copyWith(
            color: primary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'We value your input! Share your thoughts, suggestions, or report issues.',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: subColor,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Gmail
            _sectionLabel('GMAIL', subColor),
            const SizedBox(height: 8),
            TextField(
              controller: _gmailController,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                hintText: 'your.email@gmail.com',
                hintStyle: TextStyle(color: subColor.withOpacity(0.4)),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                prefixIcon: Icon(Icons.email_outlined, color: subColor, size: 20),
              ),
            ),

            const SizedBox(height: 20),

            // Subject
            _sectionLabel('SUBJECT', subColor),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                hintText: 'What is this about?',
                hintStyle: TextStyle(color: subColor.withOpacity(0.4)),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                prefixIcon: Icon(Icons.subject, color: subColor, size: 20),
              ),
            ),

            const SizedBox(height: 20),

            // Message
            _sectionLabel('MESSAGE', subColor),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 6,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                hintText: 'Write your feedback here...',
                hintStyle: TextStyle(color: subColor.withOpacity(0.4)),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),

            const SizedBox(height: 32),

            // Submit
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
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(Icons.send_rounded, color: isDark ? AppColors.onPrimary : Colors.white),
                  label: Text(
                    _sending ? 'Sending...' : 'Submit Feedback',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: isDark ? AppColors.onPrimary : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
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
}
