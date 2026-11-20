import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _auth = AuthService();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_items);
      } else {
        _filtered = _items.where((item) {
          final name = (item['flower_name'] ?? '').toString().toLowerCase();
          final family = (item['family'] ?? '').toString().toLowerCase();
          return name.contains(q) || family.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _loadHistory() async {
    try {
      final data = await ApiService.getHistory(_auth.token!);
      if (mounted) {
        setState(() {
          _items = data;
          _filtered = List.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(int id) async {
    try {
      final result = await ApiService.toggleFavorite(_auth.token!, id);
      setState(() {
        for (var item in _items) {
          if (item['id'] == id) {
            item['is_favorite'] = result;
          }
        }
        _onSearch();
      });
    } catch (e) {
      // ignore
    }
  }

  void _confirmDelete(int id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.surfaceContainerHigh
        : AppColors.lightSurfaceContainerHigh;
    final onSurface = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this?',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: GoogleFonts.inter(fontSize: 13, color: subColor),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: subColor.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _deleteItem(id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
    try {
      await ApiService.deleteHistory(_auth.token!, id);
      setState(() {
        _items.removeWhere((item) => item['id'] == id);
        _onSearch();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('History item deleted'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'History',
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
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
              color: primary,
              onRefresh: _loadHistory,
              child: _items.isEmpty
                  ? _buildEmpty(isDark, primary, subColor)
                  : _buildList(isDark),
            ),
    );
  }

  Widget _buildEmpty(bool isDark, Color primary, Color subColor) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.1),
              ),
              child: Icon(Icons.history, color: primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'No Scans Yet',
              style: AppTypography.textTheme.titleLarge?.copyWith(
                color: isDark ? AppColors.onSurface : AppColors.lightOnSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan a flower to start building\nyour botanical collection!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: subColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(bool isDark) {
    final searchBg = isDark
        ? AppColors.surfaceContainerLow
        : AppColors.lightSurfaceContainerLow;
    final searchInputBg = isDark
        ? AppColors.surfaceContainerHighest
        : AppColors.lightSurfaceContainerHighest;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Search Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: searchBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: searchInputBg,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: subColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.onSurface
                            : AppColors.lightOnSurface,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search your herbarium...',
                        hintStyle: TextStyle(
                          color: subColor.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          ..._filtered.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildHistoryItem(isDark: isDark, item: item),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required bool isDark,
    required Map<String, dynamic> item,
  }) {
    final cardBg = isDark
        ? AppColors.surfaceContainerLow
        : AppColors.lightSurfaceContainerLow;
    final primary = isDark ? AppColors.primary : AppColors.lightPrimary;
    final textColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    final String flowerName = item['flower_name'] ?? '';
    final String imageUrl = (item['image_url'] ?? '').toString();
    final String family = (item['family'] ?? '').toString().toUpperCase();
    final String description = item['description'] ?? '';
    final bool isFav = item['is_favorite'] == true;
    final int id = item['id'];
    final String createdAt = item['created_at'] ?? '';

    // Format date
    String dateStr = '';
    try {
      final dt = DateTime.parse(createdAt);
      final months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      dateStr = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      dateStr = createdAt;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        family,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        flowerName,
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description.length > 60
                            ? '${description.substring(0, 60)}...'
                            : description,
                        style: GoogleFonts.inter(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmDelete(id),
                  child: Icon(
                    Icons.delete_outline,
                    color: isDark ? Colors.white30 : Colors.black26,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: subColor.withOpacity(0.6),
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleFavorite(id),
                  child: Icon(
                    isFav ? Icons.star : Icons.star_border,
                    color: isFav ? primary : subColor.withOpacity(0.4),
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
