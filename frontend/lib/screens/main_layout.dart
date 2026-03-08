import 'package:bookmind/screens/ai_insights_screen.dart';
import 'package:bookmind/screens/community_screen.dart';
import 'package:bookmind/screens/favorites_screen.dart';
import 'package:bookmind/screens/my_library_old.dart';
import 'package:bookmind/screens/reviews_screen.dart';
import 'package:bookmind/screens/semantic_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:bookmind/screens/discover_screen.dart';
import 'package:bookmind/screens/home_screen.dart';
import 'package:bookmind/screens/login_screen.dart';
import 'package:bookmind/services/api_service.dart';
import '../config/color.dart';

// ─── Nav item model ───────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int pageIndex;
  const _NavItem(this.icon, this.selectedIcon, this.label, this.pageIndex);
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _expanded = true;

  late AnimationController _animCtrl;
  late Animation<double> _widthAnim;

  static const double _expandedW = 220;
  static const double _collapsedW = 64;

  // ── Page list (order matches nav items below) ──────────────────────────────
  final List<Widget> _pages = const [
    HomeScreen(),
    DiscoverScreen(),
    CommunityScreen(),
    SemanticSearchScreen(),
    AiInsightsScreen(),
    MyLibraryPage(),
    FavoritesScreen(),
    ReviewsScreen(),
  ];

  // ── Top section ────────────────────────────────────────────────────────────
  static const List<_NavItem> _topItems = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, "Home", 0),
    _NavItem(Icons.search_outlined, Icons.search_rounded, "Discover", 1),
    _NavItem(Icons.people_outline, Icons.people_rounded, "Community", 2),
    _NavItem(Icons.people_outline, Icons.description_rounded, "AI Describe", 3),
    _NavItem(Icons.insights_outlined, Icons.insights_rounded, "AI Insights", 4),
  ];

  // ── Library section ────────────────────────────────────────────────────────
  static const List<_NavItem> _libraryItems = [
    _NavItem(Icons.auto_stories_outlined, Icons.auto_stories, "My Library", 5),
    _NavItem(Icons.favorite_outline, Icons.favorite_rounded, "Favorites", 6),
    _NavItem(Icons.rate_review_outlined, Icons.rate_review_rounded, "Reviews", 7),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 240));
    _widthAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.value = 1.0; // start expanded
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 220),
        child: Container(
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.largeShadow),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.logout, color: AppColors.error, size: 24),
            ),
            const SizedBox(height: 12),
            const Text("Logout",
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                    fontSize: 16)),
            const SizedBox(height: 6),
            const Text("Are you sure you want to logout?",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mediumText, fontSize: 13)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.mediumText,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text("Logout"),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );

    if (confirm != true) return;
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(children: [
        // ── Sidebar ──────────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _widthAnim,
          builder: (_, __) {
            final w = _collapsedW +
                (_expandedW - _collapsedW) * _widthAnim.value;
            return SizedBox(
              width: w,
              child: _buildSidebar(w),
            );
          },
        ),

        // ── Content ───────────────────────────────────────────────────────────
        Expanded(child: _pages[_selectedIndex]),
      ]),
    );
  }

  // ─── Sidebar ──────────────────────────────────────────────────────────────

  Widget _buildSidebar(double currentW) {
    final isExp = currentW > (_collapsedW + 40);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(2, 0)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header: logo / toggle ─────────────────────────────────────────
        _buildHeader(isExp),

        const SizedBox(height: 8),

        // ── Top nav items ─────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Main group
              if (isExp)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                  child: Text("MAIN",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightText,
                          letterSpacing: 1.2)),
                ),
              ..._topItems.map((item) => _navTile(item, isExp)),

              const SizedBox(height: 6),
              _divider(isExp, label: "LIBRARY"),
              const SizedBox(height: 6),

              ..._libraryItems.map((item) => _navTile(item, isExp)),
            ]),
          ),
        ),

        // ── Bottom: logout ─────────────────────────────────────────────────
        _buildBottom(isExp),
      ]),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isExp) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        // Logo / icon
        if (isExp)
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppColors.glowShadow,
            ),
            // Use image logo if asset exists, fallback to icon
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/book.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          )
        else
          // Collapsed: just the book icon centered, also serves as toggle
          GestureDetector(
            onTap: _toggleExpand,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppColors.glowShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/book.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

        if (isExp) ...[
          const SizedBox(width: 10),
          // App name
          const Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Text("BookMind",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkText,
                      letterSpacing: 0.2)),
              Text("Your reading hub",
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.lightText,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
          // Toggle collapse button
          GestureDetector(
            onTap: _toggleExpand,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: AppColors.backgroundAlt,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.chevron_left_rounded,
                  color: AppColors.mediumText, size: 18),
            ),
          ),
        ],
      ]),
    );
  }

  // ─── Divider with optional label ──────────────────────────────────────────

  Widget _divider(bool isExp, {String label = ""}) {
    if (!isExp) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Container(height: 1, color: AppColors.borderLight),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
      child: Row(children: [
        if (label.isNotEmpty)
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightText,
                  letterSpacing: 1.2)),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: AppColors.borderLight)),
      ]),
    );
  }

  // ─── Nav tile ─────────────────────────────────────────────────────────────

  Widget _navTile(_NavItem item, bool isExp) {
    final isSelected = _selectedIndex == item.pageIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = item.pageIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: isExp ? 12 : 0,
              vertical: isExp ? 10 : 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: isSelected
                ? Border.all(color: AppColors.primary.withOpacity(0.2))
                : null,
          ),
          child: isExp
              ? Row(children: [
                  // Icon container — highlighted when selected
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.backgroundAlt,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.mediumText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.darkText,
                      ),
                    ),
                  ),
                  // Active dot
                  if (isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle),
                    ),
                ])
              // Collapsed: centered icon only
              : Center(
                  child: Tooltip(
                    message: item.label,
                    preferBelow: false,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        size: 20,
                        color: isSelected
                            ? Colors.white
                            : AppColors.mediumText,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ─── Bottom (logout) ──────────────────────────────────────────────────────

  Widget _buildBottom(bool isExp) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: isExp
          ? GestureDetector(
              onTap: _handleLogout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text("Logout",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error)),
                ]),
              ),
            )
          : Tooltip(
              message: "Logout",
              child: GestureDetector(
                onTap: _handleLogout,
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: AppColors.error, size: 18),
                ),
              ),
            ),
    );
  }
}