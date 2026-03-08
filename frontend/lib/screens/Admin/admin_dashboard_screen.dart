import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../landing_screen.dart';

// ─────────────────────────────────────────────
// APP COLORS
// ─────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFFF2FCF8);
  static const bgAlt       = Color(0xFFE4F6EF);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFF7FDFB);
  static const primary     = Color(0xFF3EB489);
  static const primaryDark = Color(0xFF1A6B50);
  static const accent      = Color(0xFF00C9A7);
  static const textDark    = Color(0xFF1A3D2E);
  static const textMid     = Color(0xFF4A8870);
  static const textLight   = Color(0xFF8ABFAD);
  static const textHint    = Color(0xFFB8D9CE);
  static const border      = Color(0xFFCCEEE2);
  static const borderLight = Color(0xFFE0F5EE);
  static const divider     = Color(0xFFBFE8DA);
  static const error       = Color(0xFFEF4444);
  static const warning     = Color(0xFFF59E0B);
  static const purple      = Color(0xFF8B5CF6);
  static const pink        = Color(0xFFF472B6);

  static const gradient = LinearGradient(
    colors: [Color(0xFF1A6B50), Color(0xFF3EB489)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const accentGrad = LinearGradient(
    colors: [Color(0xFF3EB489), Color(0xFF00C9A7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static List<BoxShadow> get shadow => [
    BoxShadow(color: const Color(0xFF1A6B50).withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get glowShadow => [
    BoxShadow(color: const Color(0xFF00C9A7).withOpacity(0.22), blurRadius: 14, offset: const Offset(0, 5)),
  ];
}

// ─────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded,          label: 'Overview'),
    _NavItem(icon: Icons.menu_book_rounded,           label: 'Books'),
    _NavItem(icon: Icons.people_rounded,              label: 'Users'),
    _NavItem(icon: Icons.psychology_rounded,          label: 'AI Metrics'),
    _NavItem(icon: Icons.sentiment_satisfied_rounded, label: 'Sentiment'),
  ];

  final _pages = const [
    _OverviewTab(),
    _BooksTab(),
    _UsersTab(),
    _AiMetricsTab(),
    _SentimentTab(),
  ];

  // ── Logout: small confirm popup then navigate ──────────────────────────────
  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        // Small centered popup
        insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 260),
        child: Container(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _C.error.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: _C.error, size: 22),
            ),
            const SizedBox(height: 10),
            const Text('Logout?',
                style: TextStyle(color: _C.textDark, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 6),
            const Text('Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: TextStyle(color: _C.textMid, fontSize: 12)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _C.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: _C.textMid, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.error, foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Logout', style: TextStyle(fontSize: 13)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (confirm != true) return;
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    if (isMobile) return _buildMobileScaffold();
    return _buildDesktopScaffold();
  }

  Widget _buildDesktopScaffold() {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Row(children: [
        _Sidebar(
          items: _navItems,
          selectedIndex: _selectedIndex,
          expanded: _sidebarExpanded,
          onSelect: (i) => setState(() => _selectedIndex = i),
          onToggle: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
          onLogout: () => _logout(context),
        ),
        Expanded(child: _pages[_selectedIndex]),
      ]),
    );
  }

  Widget _buildMobileScaffold() {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        title: Row(children: [
          _LogoMark(),
          const SizedBox(width: 10),
          const Text('BookMind Admin',
              style: TextStyle(color: _C.textDark, fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _C.error),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: _C.surface,
        child: _DrawerNav(
          items: _navItems,
          selectedIndex: _selectedIndex,
          onSelect: (i) { setState(() => _selectedIndex = i); Navigator.pop(context); },
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

// ─────────────────────────────────────────────
// SIDEBAR  (no "System Online", plain logout)
// ─────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final bool expanded;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.items, required this.selectedIndex, required this.expanded,
    required this.onSelect, required this.onToggle, required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final w = expanded ? 210.0 : 64.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: w,
      decoration: BoxDecoration(
        color: _C.surface,
        boxShadow: [BoxShadow(color: _C.primaryDark.withOpacity(0.07), blurRadius: 16, offset: const Offset(4, 0))],
      ),
      child: Column(children: [
        // ── Header
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(gradient: _C.gradient),
          child: Row(children: [
            _LogoMark(light: true),
            if (expanded) ...[
              const SizedBox(width: 8),
              const Expanded(
                child: Text('BookMind',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.3)),
              ),
            ],
            IconButton(
              icon: Icon(expanded ? Icons.chevron_left : Icons.chevron_right,
                  color: Colors.white.withOpacity(0.8), size: 18),
              onPressed: onToggle,
            ),
          ]),
        ),

        const SizedBox(height: 8),

        // ── Nav items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final selected = i == selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Material(
                  color: selected ? _C.primary.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSelect(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Row(children: [
                        Icon(item.icon, size: 18, color: selected ? _C.primary : _C.textLight),
                        if (expanded) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item.label, style: TextStyle(
                              color: selected ? _C.primary : _C.textMid,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            )),
                          ),
                          if (selected)
                            Container(width: 5, height: 5,
                                decoration: const BoxDecoration(color: _C.accent, shape: BoxShape.circle)),
                        ],
                      ]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Logout — plain icon + text, no background ─────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onLogout,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(children: [
                  Icon(Icons.logout_rounded, size: 17, color: _C.error.withOpacity(0.7)),
                  if (expanded) ...[
                    const SizedBox(width: 10),
                    Text('Logout',
                        style: TextStyle(color: _C.error.withOpacity(0.7),
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DrawerNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _DrawerNav({required this.items, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        height: 90, width: double.infinity,
        decoration: const BoxDecoration(gradient: _C.gradient),
        alignment: Alignment.center,
        child: const Text('BookMind Admin',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final selected = i == selectedIndex;
            return ListTile(
              leading: Icon(item.icon, color: selected ? _C.primary : _C.textMid, size: 20),
              title: Text(item.label, style: TextStyle(
                  color: selected ? _C.primary : _C.textDark,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13)),
              selected: selected,
              selectedTileColor: _C.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              dense: true,
              onTap: () => onSelect(i),
            );
          },
        ),
      ),
    ]);
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  final bool light;
  const _LogoMark({this.light = false});
  @override
  Widget build(BuildContext context) => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(
      gradient: light ? null : _C.gradient,
      color: light ? Colors.white.withOpacity(0.2) : null,
      borderRadius: BorderRadius.circular(9),
    ),
    child: const Icon(Icons.auto_stories, color: Colors.white, size: 17),
  );
}

Widget _pageHeader(String title, String subtitle, {Widget? action}) => Padding(
  padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
  child: Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: _C.textDark, fontSize: 18,
          fontWeight: FontWeight.w800, letterSpacing: -0.4)),
      const SizedBox(height: 1),
      Text(subtitle, style: const TextStyle(color: _C.textMid, fontSize: 12)),
    ])),
    if (action != null) action,
  ]),
);

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
    child: Row(children: [
      Container(width: 3, height: 14,
          decoration: BoxDecoration(gradient: _C.gradient, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(color: _C.textDark, fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sub;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color, this.sub});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _C.surface, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.18)), boxShadow: _C.shadow,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(children: [
      Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 17)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800, height: 1.1)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(color: _C.textLight, fontSize: 10),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      if (sub != null) Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(color: _C.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
        child: Text(sub!, style: const TextStyle(color: _C.accent, fontSize: 9, fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}

class _GreenBarChart extends StatelessWidget {
  final List<MapEntry<String, int>> data;
  final Color barColor;
  final double height;
  const _GreenBarChart({required this.data, required this.barColor, this.height = 120});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();
    final maxVal = data.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((e) {
          final ratio = maxVal == 0 ? 0.0 : e.value / maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${e.value}', style: const TextStyle(color: _C.textMid, fontSize: 7)),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: (height - 28) * ratio,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [barColor, barColor.withOpacity(0.5)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(e.key.length > 5 ? '${e.key.substring(0, 4)}…' : e.key,
                    style: const TextStyle(color: _C.textLight, fontSize: 7),
                    textAlign: TextAlign.center, maxLines: 2),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MetricProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;
  const _MetricProgressRow({required this.label, required this.value, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    child: Column(children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: _C.textMid, fontSize: 12))),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: _C.borderLight,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 5,
        ),
      ),
    ]),
  );
}

Widget _card({required Widget child, EdgeInsetsGeometry? padding, Color? borderColor}) =>
    Container(
      decoration: BoxDecoration(
        color: _C.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? _C.border), boxShadow: _C.shadow,
      ),
      padding: padding ?? const EdgeInsets.all(14),
      child: child,
    );

Widget _loadingView() => const Center(child: CircularProgressIndicator(color: _C.primary));

Widget _errorView(String e, VoidCallback onRetry) => Center(
  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _C.error.withOpacity(0.08), shape: BoxShape.circle),
      child: Icon(Icons.cloud_off_rounded, color: _C.error.withOpacity(0.6), size: 34),
    ),
    const SizedBox(height: 14),
    Text(e, style: const TextStyle(color: _C.textMid, fontSize: 13), textAlign: TextAlign.center),
    const SizedBox(height: 16),
    ElevatedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh, size: 15),
      label: const Text('Retry'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _C.primary, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  ]),
);

// ─────────────────────────────────────────────
// TAB 1 — OVERVIEW  (unchanged)
// ─────────────────────────────────────────────
class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _sentimentData;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getAdminDashboard(),
        ApiService.getAdminSentimentAnalytics(),
      ]);
      setState(() { _data = results[0]; _sentimentData = results[1]; });
    } catch (e) { setState(() { _error = e.toString(); }); }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingView();
    if (_error != null) return _errorView(_error!, _load);
    final d = _data!;
    final topRated = _sentimentData?["top_rated_books"] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _load, color: _C.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: _C.gradient, borderRadius: BorderRadius.circular(18), boxShadow: _C.glowShadow),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Welcome back, Admin 👋', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                const Text('Dashboard Overview',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: -0.4)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(7)),
                  child: Text(
                    '${d["total_users"] ?? 0} users · ${d["total_posts"] ?? 0} posts · ${d["total_reviews"] ?? 0} reviews',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ])),
              const Icon(Icons.auto_stories, color: Colors.white24, size: 48),
            ]),
          ),
          const _SectionLabel('Key Metrics'),
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.8,
            children: [
              _StatTile(label: 'Total Users',  value: '${d["total_users"] ?? 0}',     icon: Icons.people_rounded,        color: _C.primary,    sub: '+${d["new_users_week"] ?? 0} wk'),
              _StatTile(label: 'Posts',        value: '${d["total_posts"] ?? 0}',     icon: Icons.forum_rounded,         color: _C.accent,     sub: '+${d["new_posts_week"] ?? 0} wk'),
              _StatTile(label: 'Reviews',      value: '${d["total_reviews"] ?? 0}',   icon: Icons.star_rounded,          color: _C.warning),
              _StatTile(label: 'Favorites',    value: '${d["total_favorites"] ?? 0}', icon: Icons.favorite_rounded,      color: _C.pink),
              _StatTile(label: 'Events',       value: '${d["total_events"] ?? 0}',    icon: Icons.timeline_rounded,      color: _C.purple),
              _StatTile(label: 'Books',        value: '${d["total_admin_books"] ?? 0}', icon: Icons.library_books_rounded, color: _C.primaryDark),
            ],
          ),
          if (topRated.isNotEmpty) ...[
            const _SectionLabel('Top Rated Books'),
            _card(
              padding: const EdgeInsets.all(12),
              child: Column(children: topRated.take(6).map((b) {
                final img = b["image"] as String?;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: SizedBox(width: 38, height: 52,
                        child: img != null && img.isNotEmpty
                          ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _bookThumb())
                          : _bookThumb()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b["title"] ?? '', style: const TextStyle(color: _C.textDark, fontSize: 12, fontWeight: FontWeight.w700),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(b["author"] ?? '', style: const TextStyle(color: _C.textMid, fontSize: 10),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${b["review_count"] ?? 0} reviews', style: const TextStyle(color: _C.textHint, fontSize: 9)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(gradient: _C.accentGrad, borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, color: Colors.white, size: 11),
                        const SizedBox(width: 3),
                        Text('${b["avg_rating"]}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                      ]),
                    ),
                  ]),
                );
              }).toList()),
            ),
          ],
          const _SectionLabel('Quick Actions'),
          _card(
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _ActionChip(label: 'Add Book',   icon: Icons.add_circle_rounded,  color: _C.primary),
              _ActionChip(label: 'View Users', icon: Icons.people_rounded,       color: _C.accent),
              _ActionChip(label: 'AI Report',  icon: Icons.psychology_rounded,   color: _C.purple),
              _ActionChip(label: 'Sentiment',  icon: Icons.bar_chart_rounded,    color: _C.warning),
              _ActionChip(label: 'Export',     icon: Icons.download_rounded,     color: _C.textMid),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _bookThumb() => Container(
    decoration: const BoxDecoration(gradient: _C.gradient),
    child: const Center(child: Icon(Icons.menu_book_rounded, color: Colors.white54, size: 18)),
  );
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _ActionChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(9),
      border: Border.all(color: color.withOpacity(0.22)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 13),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    ]),
  );
}

// ─────────────────────────────────────────────
// TAB 2 — BOOKS  (compact cards + narrow dialog)
// ─────────────────────────────────────────────
class _BooksTab extends StatefulWidget {
  const _BooksTab();
  @override
  State<_BooksTab> createState() => _BooksTabState();
}

class _BooksTabState extends State<_BooksTab> {
  bool _loading = true;
  List<dynamic> _books = [];
  String? _error;
  final _searchCtrl = TextEditingController();
  int _page = 1;
  int _total = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load({int page = 1}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.getAdminBooks(page: page, limit: 20, q: _searchCtrl.text.trim());
      setState(() { _books = result["books"] ?? []; _total = result["total"] ?? 0; _page = page; });
    } catch (e) { setState(() { _error = e.toString(); }); }
    setState(() { _loading = false; });
  }

  Future<void> _delete(String id) async {
    final confirm = await _confirmDialog(context, 'Delete this book?');
    if (!confirm) return;
    try {
      await ApiService.deleteAdminBook(id);
      _load(page: _page);
    } catch (e) { _snack('Error: $e', isError: true); }
  }

  // ── Book detail popup (tapping the card)
  void _showDetailDialog(Map<String, dynamic> book) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        // Narrow centered popup
        insetPadding: const EdgeInsets.symmetric(horizontal: 120, vertical: 60),
        child: Container(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Cover banner
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 120, width: double.infinity,
                child: book["image"] != null && (book["image"] as String).isNotEmpty
                  ? Image.network(book["image"], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(decoration: const BoxDecoration(gradient: _C.gradient),
                          child: const Center(child: Icon(Icons.menu_book_rounded, color: Colors.white38, size: 32))))
                  : Container(decoration: const BoxDecoration(gradient: _C.gradient),
                      child: const Center(child: Icon(Icons.menu_book_rounded, color: Colors.white38, size: 32))),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(book["title"] ?? 'Untitled',
                    style: const TextStyle(color: _C.textDark, fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 3),
                Text(book["author"] ?? '', style: const TextStyle(color: _C.textMid, fontSize: 12)),
                if ((book["description"] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(book["description"], style: const TextStyle(color: _C.textMid, fontSize: 11, height: 1.4),
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
                if ((book["genres"] as List?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 4,
                    children: (book["genres"] as List).take(4).map((g) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: _C.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                      child: Text(g.toString(), style: const TextStyle(color: _C.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                    )).toList()),
                ],
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () { Navigator.pop(ctx); _showAddEditDialog(book: Map<String, dynamic>.from(book)); },
                      icon: const Icon(Icons.edit_rounded, size: 13),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.primary,
                        side: const BorderSide(color: _C.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.textMid,
                      side: const BorderSide(color: _C.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 12)),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Add / Edit dialog — narrow ─────────────────────────────────────────────
  Future<void> _showAddEditDialog({Map<String, dynamic>? book}) async {
    final titleCtrl   = TextEditingController(text: book?["title"]       ?? "");
    final authorCtrl  = TextEditingController(text: book?["author"]      ?? "");
    final yearCtrl    = TextEditingController(text: book?["year"]?.toString() ?? "");
    final descCtrl    = TextEditingController(text: book?["description"] ?? "");
    final emotionCtrl = TextEditingController(text: book?["emotion"]     ?? "");
    final imageCtrl   = TextEditingController(text: book?["image"]       ?? "");
    final genresCtrl  = TextEditingController(text: (book?["genres"] as List?)?.join(", ") ?? "");
    final isEdit = book != null;

    await showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        // Narrow — insetPadding controls width
        insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              decoration: BoxDecoration(
                gradient: _C.gradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(children: [
                Icon(isEdit ? Icons.edit_rounded : Icons.add_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(isEdit ? 'Edit Book' : 'Add Book',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ]),
            ),
            // Fields
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  _fld('Title *', titleCtrl),
                  _fld('Author *', authorCtrl),
                  Row(children: [
                    Expanded(child: _fld('Year', yearCtrl, numeric: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _fld('Genres (comma-sep)', genresCtrl)),
                  ]),
                  _fld('Description', descCtrl, maxLines: 2),
                  _fld('Emotion Tags', emotionCtrl),
                  _fld('Image URL', imageCtrl),
                ]),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _C.border),
                      foregroundColor: _C.textMid,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary, foregroundColor: Colors.white, elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final payload = {
                          "title": titleCtrl.text.trim(), "author": authorCtrl.text.trim(),
                          "year": int.tryParse(yearCtrl.text.trim()),
                          "description": descCtrl.text.trim(), "emotion": emotionCtrl.text.trim(),
                          "image": imageCtrl.text.trim(),
                          "genres": genresCtrl.text.split(",").map((g) => g.trim()).where((g) => g.isNotEmpty).toList(),
                        };
                        if (isEdit) { await ApiService.updateAdminBook(book["id"], payload); _snack('Updated ✓'); }
                        else        { await ApiService.addAdminBook(payload); _snack('Book added ✓'); }
                        _load(page: _page);
                      } catch (e) { _snack('Error: $e', isError: true); }
                    },
                    child: Text(isEdit ? 'Update' : 'Add Book', style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _fld(String label, TextEditingController ctrl, {bool numeric = false, int maxLines = 1}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl, maxLines: maxLines,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: _C.textDark, fontSize: 13),
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: _C.textLight, fontSize: 11),
          filled: true, fillColor: _C.bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: _C.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: _C.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: _C.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          isDense: true,
        ),
      ),
    );

  void _snack(String msg, {bool isError = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: isError ? _C.error : _C.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Top bar
      Container(
        color: _C.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pageHeader('Book Library', '$_total books',
            action: ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Book', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl, onSubmitted: (_) => _load(),
            style: const TextStyle(color: _C.textDark, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by title or author…',
              hintStyle: const TextStyle(color: _C.textHint, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: _C.textLight, size: 17),
              filled: true, fillColor: _C.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.primary)),
              contentPadding: const EdgeInsets.symmetric(vertical: 9),
              isDense: true,
            ),
          ),
        ]),
      ),

      // ── Grid
      Expanded(
        child: _loading
          ? _loadingView()
          : _error != null
            ? _errorView(_error!, _load)
            : RefreshIndicator(
                onRefresh: () => _load(page: _page),
                color: _C.primary,
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,          // more columns = smaller cards
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.72,     // slightly portrait, compact
                  ),
                  itemCount: _books.length,
                  itemBuilder: (context, i) {
                    final b = _books[i];
                    return _BookCard(
                      book: b,
                      onTap: () => _showDetailDialog(Map<String, dynamic>.from(b)),
                      onEdit: () => _showAddEditDialog(book: Map<String, dynamic>.from(b)),
                      onDelete: () => _delete(b["id"]),
                    );
                  },
                ),
              ),
      ),

      // ── Pagination
      if (!_loading && _error == null && _total > 20)
        Container(
          color: _C.surface,
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.chevron_left, color: _C.primary, size: 20),
                onPressed: _page > 1 ? () => _load(page: _page - 1) : null),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: _C.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text('$_page / ${(_total / 20).ceil()}',
                  style: const TextStyle(color: _C.primary, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            IconButton(icon: const Icon(Icons.chevron_right, color: _C.primary, size: 20),
                onPressed: _page * 20 < _total ? () => _load(page: _page + 1) : null),
          ]),
        ),
    ]);
  }
}

// ── Compact Book Card ──────────────────────────────────────────────────────────
class _BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _BookCard({required this.book, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.border), boxShadow: _C.shadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cover — takes most of the card height
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: SizedBox.expand(
                child: book["image"] != null && (book["image"] as String).isNotEmpty
                  ? Image.network(book["image"], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ph())
                  : _ph(),
              ),
            ),
          ),

          // Title + author — just 2 lines, compact
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 5, 6, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(book["title"] ?? 'Untitled',
                  style: const TextStyle(color: _C.textDark, fontWeight: FontWeight.w700, fontSize: 10),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(book["author"] ?? '',
                  style: const TextStyle(color: _C.textMid, fontSize: 9),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),

          // Action row
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: Row(children: [
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Icon(Icons.edit_rounded, size: 12, color: _C.primary),
                  ),
                ),
              ),
              Container(width: 1, height: 14, color: _C.border),
              Expanded(
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Icon(Icons.delete_rounded, size: 12, color: _C.error.withOpacity(0.65)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _ph() => Container(
    decoration: const BoxDecoration(gradient: _C.gradient),
    child: const Center(child: Icon(Icons.menu_book_rounded, color: Colors.white38, size: 22)),
  );
}

// ─────────────────────────────────────────────
// TAB 3 — USERS  (narrower confirm dialog)
// ─────────────────────────────────────────────
class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  bool _loading = true;
  List<dynamic> _users = [];
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final u = await ApiService.getAdminUsers(limit: 100);
      setState(() { _users = u; });
    } catch (e) { setState(() { _error = e.toString(); }); }
    setState(() { _loading = false; });
  }

  Future<void> _delete(String id, String name) async {
    final confirm = await _confirmDialog(context, 'Delete "$name" and all their data?');
    if (!confirm) return;
    try {
      await ApiService.deleteAdminUser(id);
      setState(() { _users.removeWhere((u) => u["id"] == id); });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User deleted'), backgroundColor: _C.primary,
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: _C.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingView();
    if (_error != null) return _errorView(_error!, _load);

    return Column(children: [
      Container(
        color: _C.surface,
        child: _pageHeader('User Directory', '${_users.length} registered users',
          action: IconButton(
              icon: const Icon(Icons.refresh, color: _C.textLight, size: 18), onPressed: _load)),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load, color: _C.primary,
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 2.6,
            ),
            itemCount: _users.length,
            itemBuilder: (context, i) {
              final u = _users[i];
              final eng = u["engagement"] as Map? ?? {};
              return _UserCard(
                user: u, engagement: eng,
                onDelete: () => _delete(u["id"], u["username"] ?? ''),
              );
            },
          ),
        ),
      ),
    ]);
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final Map engagement;
  final VoidCallback onDelete;
  const _UserCard({required this.user, required this.engagement, required this.onDelete});

  Color get _color {
    final name = user["username"] ?? '';
    final colors = [_C.primary, _C.accent, _C.purple, _C.warning, _C.pink, _C.primaryDark];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final reviews  = (engagement["reviews"]   ?? 0) as int;
    final posts    = (engagement["posts"]     ?? 0) as int;
    final favs     = (engagement["favorites"] ?? 0) as int;
    final totalEng = reviews + posts + favs;
    final username = user["username"] ?? 'User';
    final initial  = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final engColor = totalEng > 30 ? _C.accent : totalEng > 10 ? _C.warning : _C.textLight;

    return Container(
      decoration: BoxDecoration(
        color: _C.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border), boxShadow: _C.shadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _color.withOpacity(0.1), shape: BoxShape.circle,
            border: Border.all(color: _color.withOpacity(0.3), width: 1.5),
          ),
          child: Center(child: Text(initial,
              style: TextStyle(color: _color, fontWeight: FontWeight.w800, fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(username, style: const TextStyle(color: _C.textDark, fontWeight: FontWeight.w700, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 1),
            Text(user["email"] ?? '', style: const TextStyle(color: _C.textLight, fontSize: 9),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Row(children: [
              _MiniStat('⭐', '$reviews'),
              const SizedBox(width: 8),
              _MiniStat('💬', '$posts'),
              const SizedBox(width: 8),
              _MiniStat('❤️', '$favs'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: engColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                child: Text('$totalEng',
                    style: TextStyle(color: engColor, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ]),
          ],
        )),
        const SizedBox(width: 8),
        InkWell(
          onTap: onDelete,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _C.error.withOpacity(0.06), borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _C.error.withOpacity(0.12)),
            ),
            child: Icon(Icons.delete_rounded, size: 14, color: _C.error.withOpacity(0.65)),
          ),
        ),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji;
  final String value;
  const _MiniStat(this.emoji, this.value);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(emoji, style: const TextStyle(fontSize: 10)),
    const SizedBox(width: 2),
    Text(value, style: const TextStyle(color: _C.textDark, fontWeight: FontWeight.w700, fontSize: 10)),
  ]);
}

// ─────────────────────────────────────────────
// TAB 4 — AI METRICS  (unchanged)
// ─────────────────────────────────────────────
class _AiMetricsTab extends StatefulWidget {
  const _AiMetricsTab();
  @override
  State<_AiMetricsTab> createState() => _AiMetricsTabState();
}

class _AiMetricsTabState extends State<_AiMetricsTab> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _engagement;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getAdminAiMetrics(),
        ApiService.getAdminEngagementAnalytics(),
      ]);
      setState(() { _data = results[0]; _engagement = results[1]; });
    } catch (e) { setState(() { _error = e.toString(); }); }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingView();
    if (_error != null) return _errorView(_error!, _load);
    final topSearches    = _data!["top_searched_books"] as List? ?? [];
    final eventBreakdown = _data!["event_breakdown"] as List? ?? [];
    final dailyStats     = _engagement?["daily_stats"] as List? ?? [];
    final coverage       = _data!["dataset_coverage"] as Map? ?? {};
    final genreCov   = (coverage["genre_coverage_pct"]     ?? 0.0) as num;
    final emotionCov = (coverage["emotion_coverage_pct"]   ?? 0.0) as num;
    final sentCov    = (coverage["sentiment_coverage_pct"] ?? 0.0) as num;

    return RefreshIndicator(
      onRefresh: _load, color: _C.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        children: [
          const _SectionLabel('Daily Active Users (14 days)'),
          _card(child: dailyStats.isNotEmpty
            ? _GreenBarChart(barColor: _C.primary, height: 140,
                data: dailyStats.map((d) {
                  final date = (d["date"] as String).split("-").last;
                  return MapEntry(date, (d["active_users"] as num).toInt());
                }).toList())
            : const Padding(padding: EdgeInsets.all(20),
                child: Center(child: Text('No data', style: TextStyle(color: _C.textLight))))),
          if (eventBreakdown.isNotEmpty) ...[
            const _SectionLabel('Event Type Breakdown'),
            _card(child: _GreenBarChart(barColor: _C.accent, height: 140,
              data: eventBreakdown.take(10).map((e) => MapEntry(
                (e["type"] as String).replaceAll("_", " "), (e["count"] as num).toInt())).toList())),
          ],
          const _SectionLabel('Dataset Coverage'),
          _card(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
            child: Column(children: [
              _MetricProgressRow(label: 'Genre Coverage',     value: '${genreCov.toStringAsFixed(1)}%',   progress: genreCov / 100,   color: _C.primary),
              _MetricProgressRow(label: 'Emotion Coverage',   value: '${emotionCov.toStringAsFixed(1)}%', progress: emotionCov / 100, color: _C.warning),
              _MetricProgressRow(label: 'Sentiment Coverage', value: '${sentCov.toStringAsFixed(1)}%',    progress: sentCov / 100,    color: _C.accent),
            ]),
          ),
          if (topSearches.isNotEmpty) ...[
            const _SectionLabel('Top Searched Books'),
            _card(
              padding: const EdgeInsets.all(12),
              child: Column(children: topSearches.take(8).map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Container(width: 26, height: 26,
                    decoration: BoxDecoration(gradient: _C.gradient, borderRadius: BorderRadius.circular(7)),
                    child: const Center(child: Icon(Icons.search, color: Colors.white, size: 12))),
                  const SizedBox(width: 9),
                  Expanded(child: Text(b["title"] ?? '', style: const TextStyle(color: _C.textDark, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: _C.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('${b["count"]}x',
                        style: const TextStyle(color: _C.primary, fontSize: 10, fontWeight: FontWeight.w700))),
                ]),
              )).toList()),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB 5 — SENTIMENT  (unchanged)
// ─────────────────────────────────────────────
class _SentimentTab extends StatefulWidget {
  const _SentimentTab();
  @override
  State<_SentimentTab> createState() => _SentimentTabState();
}

class _SentimentTabState extends State<_SentimentTab> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await ApiService.getAdminSentimentAnalytics();
      setState(() { _data = d; });
    } catch (e) { setState(() { _error = e.toString(); }); }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingView();
    if (_error != null) return _errorView(_error!, _load);
    final overview        = _data!["overview"] as Map? ?? {};
    final ratingDist      = _data!["rating_distribution"] as Map? ?? {};
    final sentimentLabels = _data!["sentiment_labels"] as List? ?? [];
    final topRated        = _data!["top_rated_books"] as List? ?? [];
    final emotions        = _data!["emotion_distribution"] as List? ?? [];
    final genres          = _data!["genre_distribution"] as List? ?? [];
    final avgRating    = (overview["avg_rating"]    ?? 0.0) as num;
    final totalReviews = (overview["total_reviews"] ?? 0) as int;

    final ratingColors = [
      _C.error, const Color(0xFFFF8C69), _C.warning,
      _C.accent.withOpacity(0.85), _C.accent,
    ];

    return RefreshIndicator(
      onRefresh: _load, color: _C.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(gradient: _C.gradient, borderRadius: BorderRadius.circular(18), boxShadow: _C.glowShadow),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Average Rating', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 2),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(avgRating.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const Padding(padding: EdgeInsets.only(bottom: 7, left: 4),
                      child: Text('/ 5', style: TextStyle(color: Colors.white54, fontSize: 14))),
                ]),
                Row(children: List.generate(5, (i) => Icon(
                  i < avgRating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.white.withOpacity(0.85), size: 15))),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$totalReviews',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const Text('Total Reviews', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(7)),
                  child: const Text('Live Data', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                ),
              ]),
            ]),
          ),
          const _SectionLabel('Rating Snapshot'),
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.8,
            children: [
              ...List.generate(5, (i) {
                final star  = 5 - i;
                final count = (ratingDist["$star"] ?? 0) as int;
                return _StatTile(label: '$star Star Ratings', value: '$count',
                    icon: Icons.star_rounded, color: ratingColors[star - 1]);
              }),
              _StatTile(label: 'Avg Rating', value: avgRating.toStringAsFixed(1),
                  icon: Icons.grade_rounded, color: _C.primary),
            ],
          ),
          const _SectionLabel('Rating Distribution'),
          _card(child: Column(children: List.generate(5, (i) {
            final star  = 5 - i;
            final count = (ratingDist["$star"] ?? 0) as int;
            final maxV  = ratingDist.values.map((v) => v as int).fold(0, (a, b) => a > b ? a : b);
            final ratio = maxV == 0 ? 0.0 : count / maxV;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Icon(Icons.star_rounded, color: ratingColors[star - 1], size: 12),
                const SizedBox(width: 4),
                Text('$star', style: TextStyle(color: ratingColors[star - 1], fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: ratio, backgroundColor: _C.borderLight,
                    valueColor: AlwaysStoppedAnimation(ratingColors[star - 1]), minHeight: 7))),
                const SizedBox(width: 8),
                SizedBox(width: 28, child: Text('$count',
                    style: const TextStyle(color: _C.textMid, fontSize: 10), textAlign: TextAlign.right)),
              ]),
            );
          }))),
          if (sentimentLabels.isNotEmpty) ...[
            const _SectionLabel('Sentiment Labels'),
            _card(child: _GreenBarChart(barColor: _C.accent, height: 130,
              data: sentimentLabels.take(8).map((s) =>
                  MapEntry(s["label"] as String, (s["count"] as num).toInt())).toList())),
          ],
          if (topRated.isNotEmpty) ...[
            const _SectionLabel('Top Rated Books'),
            _card(padding: const EdgeInsets.all(12),
              child: Column(children: topRated.take(8).map((b) {
                final img = b["image"] as String?;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(7),
                      child: SizedBox(width: 36, height: 50,
                        child: img != null && img.isNotEmpty
                          ? Image.network(img, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _bookThumb())
                          : _bookThumb())),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b["title"] ?? '', style: const TextStyle(color: _C.textDark, fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(b["author"] ?? '', style: const TextStyle(color: _C.textMid, fontSize: 10),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${b["review_count"]} reviews', style: const TextStyle(color: _C.textHint, fontSize: 9)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(gradient: _C.accentGrad, borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, color: Colors.white, size: 11),
                        const SizedBox(width: 3),
                        Text('${b["avg_rating"]}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                      ]),
                    ),
                  ]),
                );
              }).toList())),
          ],
          if (emotions.isNotEmpty) ...[
            const _SectionLabel('Emotion Tag Cloud'),
            _card(child: Wrap(spacing: 8, runSpacing: 8,
              children: emotions.take(14).map((e) {
                final palette = [_C.primary, _C.accent, _C.warning, _C.purple, _C.pink, _C.primaryDark, _C.error.withOpacity(0.75)];
                final color = palette[emotions.indexOf(e) % palette.length];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withOpacity(0.22))),
                  child: Text('${e["emotion"]}  ${e["count"]}',
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                );
              }).toList())),
          ],
          if (genres.isNotEmpty) ...[
            const _SectionLabel('Genre Distribution'),
            _card(child: _GreenBarChart(barColor: _C.primary, height: 130,
              data: genres.take(10).map((g) =>
                  MapEntry(g["genre"] as String, (g["count"] as num).toInt())).toList())),
          ],
        ],
      ),
    );
  }

  Widget _bookThumb() => Container(
    decoration: const BoxDecoration(gradient: _C.gradient),
    child: const Center(child: Icon(Icons.menu_book_rounded, color: Colors.white54, size: 16)));
}

// ─────────────────────────────────────────────
// CONFIRM DIALOG  (small, centered)
// ─────────────────────────────────────────────
Future<bool> _confirmDialog(BuildContext context, String message) async {
  return await showDialog<bool>(
    context: context,
    barrierColor: Colors.black45,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      // Narrow popup
      insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 260),
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16)],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _C.error.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: _C.error, size: 22),
          ),
          const SizedBox(height: 10),
          const Text('Confirm', style: TextStyle(color: _C.textDark, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: _C.textMid, fontSize: 11), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _C.border),
                  foregroundColor: _C.textMid,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.error, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
                child: const Text('Delete', style: TextStyle(fontSize: 12)),
              ),
            ),
          ]),
        ]),
      ),
    ),
  ) ?? false;
}