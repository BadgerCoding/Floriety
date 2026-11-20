import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groq_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../../main.dart';

class AiChatbotScreen extends StatefulWidget {
  const AiChatbotScreen({super.key});

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  final AuthService _auth = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, String>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _loadingHistory = false;
  List<Map<String, dynamic>> _historySessions = [];
  int? _currentSessionId;
  String _currentSessionTitle = 'Floriety Chat';

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'content':
          'Hello! I am the Floriety AI 🌸 I can help you identify flowers, diagnose plant health, and answer all your botanical questions. What are we exploring today?',
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_auth.isLoggedIn) {
        _loadChatHistory();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    if (!_auth.isLoggedIn) return;
    setState(() => _loadingHistory = true);
    try {
      final sessions = await ApiService.getChatHistory(_auth.token!);
      if (mounted) {
        setState(() => _historySessions = sessions);
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _openSession(int id) async {
    if (!_auth.isLoggedIn) return;
    try {
      final session = await ApiService.getChatConversation(_auth.token!, id);
      final rawMessages = session['messages'] as List<dynamic>;
      final restored = rawMessages.map<Map<String, String>>((dynamic raw) {
        final message = Map<String, dynamic>.from(raw as Map);
        return {
          'role': message['role'].toString(),
          'content': message['content'].toString(),
        };
      }).toList();
      if (mounted) {
        setState(() {
          _messages
            ..clear()
            ..addAll(restored);
          _currentSessionId = id;
          _currentSessionTitle =
              session['title']?.toString() ?? 'Floriety Chat';
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open conversation history.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String _sessionTitleFromMessages() {
    final firstUser = _messages.firstWhere(
      (message) => message['role'] == 'user',
      orElse: () => {'content': 'Floriety Chat'},
    );
    final content = firstUser['content']?.trim() ?? 'Floriety Chat';
    if (content.isEmpty) return 'Floriety Chat';
    if (content.length > 40) return '${content.substring(0, 40)}...';
    return content;
  }

  Future<void> _saveConversation() async {
    if (!_auth.isLoggedIn || _messages.length < 2) return;
    final title = _sessionTitleFromMessages();
    try {
      final savedId = await ApiService.saveChatConversation(
        _auth.token!,
        id: _currentSessionId,
        title: title,
        messages: _messages,
      );
      if (mounted) {
        setState(() {
          _currentSessionId = savedId;
          _currentSessionTitle = title;
        });
      }
      await _loadChatHistory();
    } catch (_) {
      // ignore failures for auto-save
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await GroqService.chat(
        _messages
            .where((m) => m['role'] != 'assistant' || _messages.indexOf(m) > 0)
            .toList(),
      );
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _isLoading = false;
        });
        _scrollToBottom();
        await _saveConversation();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content':
                'Sorry, I encountered an error. Please check your connection and try again.',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;
    final surfaceVariant = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      endDrawer: _buildChatHistoryDrawer(isDark),
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Chatbot',
              style: AppTypography.textTheme.headlineSmall?.copyWith(
                color: primary,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _currentSessionTitle,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: surfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: surfaceVariant),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            tooltip: 'Chat history',
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: surfaceVariant,
            ),
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Typing indicator
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildTypingIndicator(isDark),
                  );
                }
                final msg = _messages[index];
                final isBot = msg['role'] == 'assistant';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: isBot
                      ? _buildBotMessage(
                          isDark: isDark,
                          text: msg['content'] ?? '',
                        )
                      : _buildUserMessage(
                          isDark: isDark,
                          text: msg['content'] ?? '',
                        ),
                );
              },
            ),
          ),
          _buildInputArea(isDark, primary),
        ],
      ),
    );
  }

  Widget _buildBotMessage({required bool isDark, required String text}) {
    final primary = isDark ? AppColors.primary : AppColors.lightPrimary;
    final cardBg = isDark
        ? AppColors.surfaceContainerLow
        : AppColors.lightSurfaceContainerLow;
    final textColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final outline = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceContainerHighest
                : AppColors.lightSurfaceContainerHighest,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: primary.withOpacity(0.1), blurRadius: 10),
            ],
          ),
          child: Icon(Icons.psychology, color: primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: outline.withOpacity(0.1)),
                ),
                child: Text(
                  text,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'BOT • FLORIETY AI',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                  color:
                      (isDark
                              ? AppColors.onSurfaceVariant
                              : AppColors.lightOnSurfaceVariant)
                          .withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
      ],
    );
  }

  Widget _buildUserMessage({required bool isDark, required String text}) {
    final primary = isDark ? AppColors.primary : AppColors.lightPrimary;
    final onPrimary = isDark ? AppColors.onPrimary : Colors.white;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'YOU',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                  color:
                      (isDark
                              ? AppColors.onSurfaceVariant
                              : AppColors.lightOnSurfaceVariant)
                          .withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isDark ? AppColors.primary : AppColors.lightPrimary)
                .withOpacity(0.15),
          ),
          child: Icon(
            Icons.person,
            color: isDark ? AppColors.primary : AppColors.lightPrimary,
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildChatHistoryDrawer(bool isDark) {
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;
    final onSurface = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final cardBg = isDark
        ? AppColors.surfaceContainerHigh
        : AppColors.lightSurfaceContainerHigh;

    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Text(
                'Conversation History',
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : !_auth.isLoggedIn
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Login to see your saved conversations.',
                              textAlign: TextAlign.center,
                              style: AppTypography.textTheme.bodyMedium
                                  ?.copyWith(color: subColor),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  context.go('/login');
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                ),
                                child: const Text('Login'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  context.go('/register');
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                ),
                                child: const Text('Sign Up'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _historySessions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'No saved conversations yet. Start chatting to create a history.',
                          textAlign: TextAlign.center,
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: subColor,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _historySessions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final session = _historySessions[index];
                        final isSelected = session['id'] == _currentSessionId;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          tileColor: isSelected ? cardBg : Colors.transparent,
                          title: Text(
                            session['title']?.toString() ?? 'Untitled chat',
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            session['updated_at']?.toString() ?? '',
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: subColor,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: onSurface,
                            size: 10,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _openSession(session['id'] as int);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    final cardBg = isDark
        ? AppColors.surfaceContainerLow
        : AppColors.lightSurfaceContainerLow;
    final primary = isDark ? AppColors.primary : AppColors.lightPrimary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceContainerHighest
                : AppColors.lightSurfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.psychology, color: primary, size: 20),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedDot(color: primary, delay: 0),
              const SizedBox(width: 4),
              _AnimatedDot(color: primary, delay: 200),
              const SizedBox(width: 4),
              _AnimatedDot(color: primary, delay: 400),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea(bool isDark, Color primary) {
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;
    final inputBg = isDark
        ? AppColors.surfaceContainerHigh
        : AppColors.lightSurfaceContainerHigh;
    final outline = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;
    final hintColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final textColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
      decoration: BoxDecoration(color: bg.withOpacity(0.9)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: inputBg.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: outline.withOpacity(0.15)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 12),
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 1,
                  style: TextStyle(color: textColor, fontSize: 14),
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Ask about a flower species...',
                    hintStyle: TextStyle(
                      color: hintColor.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 4, right: 4),
              decoration: BoxDecoration(
                color: _isLoading
                    ? (isDark
                          ? AppColors.surfaceContainerHighest
                          : AppColors.lightSurfaceContainerHighest)
                    : primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: primary.withOpacity(0.3), blurRadius: 20),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.send,
                  color: _isLoading
                      ? hintColor
                      : (isDark ? AppColors.onPrimary : Colors.white),
                  size: 20,
                ),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated bouncing dot for typing indicator
class _AnimatedDot extends StatefulWidget {
  final Color color;
  final int delay;
  const _AnimatedDot({required this.color, required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0,
      end: -6,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
