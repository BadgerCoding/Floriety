import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../../main.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  bool _loading = true;
  bool _saving = false;

  final _nameController = TextEditingController();
  String _nickname = '';
  final _descController = TextEditingController();
  int _selectedProfileIndex = 0;
  int? _hoveredProfileIndex;

  final List<String> _nicknameOptions = [
    '',
    'Botanist',
    'Garden Enthusiast',
    'Flower Keeper',
    'Bloom Whisperer',
    'Petal Poet',
    'Sunrise Sprout',
    'Jade Gardener',
    'Rose Ranger',
    'Meadow Muse',
    'Orchid Oracle',
  ];

  final List<String> _profileImagePaths = List.generate(
    10,
    (index) => 'assets/profile_avatar/profile_${index + 1}.png',
  );

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.getProfile(_auth.token!);
      if (mounted) {
        setState(() {
          _nameController.text = data['name'] ?? _auth.name ?? '';
          _nickname = data['nickname'] ?? '';
          _selectedProfileIndex = ((data['avatar_index'] ?? 1) as int) - 1;
          _descController.text = data['description'] ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nameController.text = _auth.name ?? '';
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    setState(() => _saving = true);
    try {
      await _auth.updateProfile(
        name: _nameController.text.trim(),
        nickname: _nickname,
        description: _descController.text.trim(),
        avatarIndex: _selectedProfileIndex + 1,
        isDark: isDarkMode,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Profile saved!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      router.go('/home');
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
    final cardBg = isDark
        ? AppColors.surfaceContainerLow
        : AppColors.lightSurfaceContainerLow;
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;
    final inputBg = isDark
        ? AppColors.surfaceContainerHigh
        : AppColors.lightSurfaceContainerHigh;
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Profile',
                            style: AppTypography.textTheme.headlineSmall
                                ?.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final nextMode = isDark
                                ? ThemeMode.light
                                : ThemeMode.dark;
                            final messenger = ScaffoldMessenger.of(context);
                            themeNotifier.value = nextMode;
                            try {
                              await _auth.updateProfile(
                                isDark: nextMode == ThemeMode.dark,
                              );
                            } catch (_) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Failed to save theme preference.',
                                  ),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              color: primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: primary.withAlpha((0.35 * 255).round()),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              _profileImagePaths[_selectedProfileIndex],
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Name', onSurface),
                              const SizedBox(height: 10),
                              _buildInputField(
                                controller: _nameController,
                                hintText: 'Enter your name',
                                inputBg: inputBg,
                                onSurface: onSurface,
                                subColor: subColor,
                                primary: primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _label('Choose your profile', onSurface),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: Row(
                        children: [
                          _navButton(
                            Icons.arrow_back_ios_new,
                            onPressed: () {
                              setState(() {
                                _selectedProfileIndex =
                                    (_selectedProfileIndex -
                                        1 +
                                        _profileImagePaths.length) %
                                    _profileImagePaths.length;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _profileImagePaths.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final isSelected =
                                    index == _selectedProfileIndex;
                                final isHovered = index == _hoveredProfileIndex;
                                return MouseRegion(
                                  onEnter: (_) => setState(
                                    () => _hoveredProfileIndex = index,
                                  ),
                                  onExit: (_) => setState(
                                    () => _hoveredProfileIndex = null,
                                  ),
                                  child: _profileCard(
                                    imagePath: _profileImagePaths[index],
                                    isSelected: isSelected,
                                    isHovered: isHovered,
                                    onTap: () => setState(
                                      () => _selectedProfileIndex = index,
                                    ),
                                    primary: primary,
                                    cardBg: cardBg,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          _navButton(
                            Icons.arrow_forward_ios,
                            onPressed: () {
                              setState(() {
                                _selectedProfileIndex =
                                    (_selectedProfileIndex + 1) %
                                    _profileImagePaths.length;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _label('Nickname', onSurface),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _nicknameOptions.contains(_nickname)
                              ? _nickname
                              : '',
                          isExpanded: true,
                          dropdownColor: cardBg,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: subColor,
                          ),
                          style: AppTypography.textTheme.bodyLarge?.copyWith(
                            color: onSurface,
                          ),
                          items: _nicknameOptions.map((nick) {
                            return DropdownMenuItem(
                              value: nick,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 8,
                                ),
                                child: Text(
                                  nick.isEmpty ? 'Enter a nickname' : nick,
                                  style: TextStyle(
                                    color: nick.isEmpty ? subColor : onSurface,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _nickname = val);
                          },
                          hint: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 8),
                            child: Text(
                              'Enter a nickname',
                              style: TextStyle(color: subColor),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _label('Description', onSurface),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descController,
                      maxLines: 6,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        hintText: 'Enter a description',
                        hintStyle: TextStyle(
                          color: subColor.withAlpha((0.6 * 255).round()),
                        ),
                        filled: true,
                        fillColor: inputBg,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: primary.withAlpha((0.7 * 255).round()),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Save Profile',
                                style: AppTypography.textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _auth.logout();
                          if (mounted) {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.redAccent, width: 1.8),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: AppTypography.textTheme.titleMedium?.copyWith(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _label(String text, Color color) {
    return Text(
      text,
      style: AppTypography.textTheme.titleSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required Color inputBg,
    required Color onSurface,
    required Color subColor,
    required Color primary,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: subColor.withAlpha((0.6 * 255).round())),
        filled: true,
        fillColor: inputBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: primary.withAlpha((0.7 * 255).round()),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, {required VoidCallback onPressed}) {
    return Material(
      color: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
      ),
    );
  }

  Widget _profileCard({
    required String imagePath,
    required bool isSelected,
    required bool isHovered,
    required VoidCallback onTap,
    required Color primary,
    required Color cardBg,
  }) {
    final bool active = isSelected || isHovered;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: primary.withAlpha(120),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            imagePath,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
