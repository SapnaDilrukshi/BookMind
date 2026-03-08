import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/color.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen>
    with TickerProviderStateMixin {
  bool loading = true;
  String? error;

  Map<String, dynamic>? insightsMe;
  List<dynamic> events = [];

  late TabController _tabController;
  late AnimationController _animController;
  late Animation<double> _animProgress;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animProgress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final me = await ApiService.getInsightsMe();
      final data = await ApiService.getInsightsActivity(limit: 100);

      if (!mounted) return;
      setState(() {
        insightsMe = me;
        events = data;
        loading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  IconData _iconForType(String t) {
    switch (t) {
      case "view_book":
        return Icons.menu_book;
      case "recommend_search":
        return Icons.search;
      case "recommend_text":
        return Icons.auto_awesome;
      case "favorite_add":
        return Icons.favorite;
      case "favorite_remove":
        return Icons.heart_broken;
      case "review_save":
        return Icons.rate_review;
      default:
        return Icons.bolt;
    }
  }

  Color _colorForType(String t) {
    switch (t) {
      case "view_book":
        return const Color(0xFF4F8EF7);
      case "recommend_search":
        return const Color(0xFF9B59B6);
      case "recommend_text":
        return const Color(0xFFFF8C42);
      case "favorite_add":
        return const Color(0xFFE74C6E);
      case "favorite_remove":
        return const Color(0xFF95A5A6);
      case "review_save":
        return const Color(0xFF27AE60);
      default:
        return AppColors.primary;
    }
  }

  String _labelForType(String t) {
    switch (t) {
      case "view_book":
        return "Viewed Book";
      case "recommend_search":
        return "Searched Recommendations";
      case "recommend_text":
        return "AI Recommendation";
      case "favorite_add":
        return "Added to Favorites";
      case "favorite_remove":
        return "Removed from Favorites";
      case "review_save":
        return "Saved Review";
      default:
        return t.replaceAll("_", " ");
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inMinutes < 1) return "Just now";
      if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
      if (difference.inHours < 24) return "${difference.inHours}h ago";
      if (difference.inDays < 7) return "${difference.inDays}d ago";
      return "${dt.month}/${dt.day}/${dt.year}";
    } catch (e) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with gradient
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "AI Insights",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.75),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Icon(Icons.insights, size: 150,
                          color: Colors.white.withOpacity(0.09)),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Icon(Icons.auto_graph, size: 100,
                          color: Colors.white.withOpacity(0.09)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64,
                          color: AppColors.error.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text("Failed to load insights",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      Text(error!,
                          style: const TextStyle(color: AppColors.mediumText),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildStatsSection(),
                  const SizedBox(height: 16),

                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05),
                            blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.mediumText,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      tabs: const [
                        Tab(icon: Icon(Icons.dashboard, size: 18), text: "Overview"),
                        Tab(icon: Icon(Icons.trending_up, size: 18), text: "Trends"),
                        Tab(icon: Icon(Icons.history, size: 18), text: "Activity"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildTrendsTab(),
                        _buildActivityTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Stats Section ────────────────────────────────────────────────────────

  Widget _buildStatsSection() {
    final stats = (insightsMe?["stats"] as Map?)?.cast<String, dynamic>() ?? {};
    final totalViews = (stats["total_book_views"] ?? 0) as num;
    final favorites = (stats["favorites_added"] ?? 0) as num;
    final reviews = (stats["reviews_count"] ?? 0) as num;
    final totalActions = totalViews + favorites + reviews;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.analytics, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                "Your Reading Statistics",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                    color: AppColors.darkTextAlt),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Ring chart + stats side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ring chart
              AnimatedBuilder(
                animation: _animProgress,
                builder: (_, __) => CustomPaint(
                  size: const Size(110, 110),
                  painter: _RingChartPainter(
                    sections: [
                      _RingSection(
                          value: totalViews.toDouble(),
                          color: const Color(0xFF4F8EF7)),
                      _RingSection(
                          value: favorites.toDouble(),
                          color: const Color(0xFFE74C6E)),
                      _RingSection(
                          value: reviews.toDouble(),
                          color: const Color(0xFF27AE60)),
                    ],
                    progress: _animProgress.value,
                    centerLabel: totalActions.toInt().toString(),
                    centerSub: "total",
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Legend + values
              Expanded(
                child: Column(
                  children: [
                    _legendRow(Icons.visibility, "Book Views",
                        totalViews.toInt(), const Color(0xFF4F8EF7)),
                    const SizedBox(height: 10),
                    _legendRow(Icons.favorite, "Favorites",
                        favorites.toInt(), const Color(0xFFE74C6E)),
                    const SizedBox(height: 10),
                    _legendRow(Icons.rate_review, "Reviews",
                        reviews.toInt(), const Color(0xFF27AE60)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow(IconData icon, String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.mediumText,
                  fontWeight: FontWeight.w600)),
        ),
        Text(value.toString(),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                color: color)),
      ],
    );
  }

  // ─── Overview Tab ─────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final Map<String, int> eventCounts = {};
    for (var event in events) {
      final type = (event["type"] ?? "").toString();
      eventCounts[type] = (eventCounts[type] ?? 0) + 1;
    }

    final maxVal = eventCounts.values.fold(0, (a, b) => a > b ? a : b);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // Activity Breakdown Bar Chart
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(Icons.bar_chart_rounded, "Activity Breakdown"),
                const SizedBox(height: 20),
                if (eventCounts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text("No activity yet. Start exploring books! 📚",
                          style: TextStyle(color: AppColors.mediumText)),
                    ),
                  )
                else
                  ...eventCounts.entries.map((entry) {
                    final frac = maxVal == 0 ? 0.0 : entry.value / maxVal;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _colorForType(entry.key)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(_iconForType(entry.key),
                                    color: _colorForType(entry.key), size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_labelForType(entry.key),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkTextAlt)),
                              ),
                              Text(
                                "${entry.value}",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _colorForType(entry.key)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          AnimatedBuilder(
                            animation: _animProgress,
                            builder: (_, __) => ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: frac * _animProgress.value,
                                minHeight: 8,
                                backgroundColor: _colorForType(entry.key)
                                    .withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation(
                                    _colorForType(entry.key)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info tip card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.purple.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange.shade700, size: 26),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Your activity helps us understand your preferences and provide better book recommendations!",
                    style: TextStyle(fontSize: 13, height: 1.4,
                        color: AppColors.darkTextAlt),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Trends Tab (genres + moods + recent activity) ────────────────────────

  Widget _buildTrendsTab() {
    final top = insightsMe?["top"] as Map<String, dynamic>? ?? {};
    final genres = (top["genres"] as List?) ?? [];
    final emotions = (top["emotions"] as List?) ?? [];
    final recent = (insightsMe?["recent_activity"] as List?) ?? [];

    final maxGenre = genres.isNotEmpty
        ? (genres.map((g) => (g["count"] ?? 1) as num).reduce(
            (a, b) => a > b ? a : b)).toDouble()
        : 1.0;
    final maxEmo = emotions.isNotEmpty
        ? (emotions.map((e) => (e["count"] ?? 1) as num).reduce(
            (a, b) => a > b ? a : b)).toDouble()
        : 1.0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // Top Genres Bar Chart
          if (genres.isNotEmpty) ...[
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardHeader(Icons.library_books_rounded, "Top Genres"),
                  const SizedBox(height: 20),
                  ...genres.take(6).toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final g = entry.value as Map;
                    final name = (g["name"] ?? "").toString();
                    final count = (g["count"] ?? 1) as num;
                    final frac = count / maxGenre;
                    final barColor = _genreColor(i);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: AppColors.darkTextAlt),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _animProgress,
                              builder: (_, __) => Stack(
                                children: [
                                  Container(
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: barColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor:
                                        frac * _animProgress.value,
                                    child: Container(
                                      height: 22,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            barColor,
                                            barColor.withOpacity(0.7)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 28,
                            child: Text(
                              count.toInt().toString(),
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w800,
                                  color: barColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Top Moods Bubble Grid
          if (emotions.isNotEmpty) ...[
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardHeader(Icons.mood_rounded, "Top Moods"),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: emotions.take(8).toList().asMap().entries.map(
                      (entry) {
                        final i = entry.key;
                        final e = entry.value as Map;
                        final name = (e["name"] ?? "").toString();
                        final count = (e["count"] ?? 1) as num;
                        final size = 0.55 + (count / maxEmo) * 0.45;
                        final c = _moodColor(i);

                        return AnimatedBuilder(
                          animation: _animProgress,
                          builder: (_, __) {
                            return Transform.scale(
                              scale: _animProgress.value * size +
                                  (1 - _animProgress.value) * 0.4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    c.withOpacity(0.18),
                                    c.withOpacity(0.08),
                                  ]),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: c.withOpacity(0.45), width: 1.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_moodEmoji(name),
                                        style:
                                            const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 5),
                                    Text(
                                      name,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: c),
                                    ),
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: c.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(count.toInt().toString(),
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: c)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Recent Activity Timeline ────────────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(Icons.access_time_rounded, "Recent Activity"),
                const SizedBox(height: 16),
                if (recent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text("No recent activity yet.",
                        style: TextStyle(color: AppColors.mediumText)),
                  )
                else
                  ...recent.take(6).toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value as Map;
                    final type = (r["type"] ?? "").toString();
                    final title = (r["book_title"] ?? "").toString();
                    final date = (r["created_at"] ?? "").toString();
                    final isLast = i == (math.min(recent.length, 6) - 1);

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline line + dot
                          SizedBox(
                            width: 32,
                            child: Column(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      _colorForType(type),
                                      _colorForType(type).withOpacity(0.7),
                                    ]),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(_iconForType(type),
                                      color: Colors.white, size: 15),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      color: AppColors.border,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Content
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  bottom: isLast ? 0 : 16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _labelForType(type),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppColors.darkText),
                                  ),
                                  if (title.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.mediumText),
                                    ),
                                  ],
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 11,
                                          color: Colors.grey.shade400),
                                      const SizedBox(width: 3),
                                      Text(
                                        date.isEmpty
                                            ? ""
                                            : date.split("T").first,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade400),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Activity Tab ─────────────────────────────────────────────────────────

  Widget _buildActivityTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: events.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 40),
                Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("No activity yet",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text("Start exploring books to see your activity timeline here!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index] as Map<String, dynamic>;
                final type = (event["type"] ?? "").toString();
                final title = (event["book_title"] ?? "").toString();
                final createdAt = (event["created_at"] ?? "").toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.045),
                          blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _colorForType(type),
                            _colorForType(type).withOpacity(0.65)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_iconForType(type),
                          color: Colors.white, size: 22),
                    ),
                    title: Text(_labelForType(type),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkTextAlt)),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 11,
                                color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(_formatDateTime(createdAt),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right,
                        color: Colors.grey.shade300),
                  ),
                );
              },
            ),
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.055),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: AppColors.darkTextAlt)),
      ],
    );
  }

  Color _genreColor(int i) {
    const colors = [
      Color(0xFF4F8EF7),
      Color(0xFF9B59B6),
      Color(0xFFFF8C42),
      Color(0xFF27AE60),
      Color(0xFFE74C6E),
      Color(0xFF1ABC9C),
    ];
    return colors[i % colors.length];
  }

  Color _moodColor(int i) {
    const colors = [
      Color(0xFFFF8C42),
      Color(0xFF4F8EF7),
      Color(0xFFE74C6E),
      Color(0xFF27AE60),
      Color(0xFF9B59B6),
      Color(0xFF1ABC9C),
      Color(0xFFF39C12),
      Color(0xFF2980B9),
    ];
    return colors[i % colors.length];
  }

  String _moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case "happy": return "😊";
      case "sad": return "😢";
      case "inspired": return "✨";
      case "scary": return "😱";
      case "romantic": return "💕";
      case "dark": return "🌑";
      case "adventurous": return "⚡";
      case "mysterious": return "🔮";
      case "neutral": return "😐";
      default: return "📚";
    }
  }
}

// ─── Ring Chart Painter ───────────────────────────────────────────────────────

class _RingSection {
  final double value;
  final Color color;
  const _RingSection({required this.value, required this.color});
}

class _RingChartPainter extends CustomPainter {
  final List<_RingSection> sections;
  final double progress;
  final String centerLabel;
  final String centerSub;

  const _RingChartPainter({
    required this.sections,
    required this.progress,
    required this.centerLabel,
    required this.centerSub,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 10;
    const strokeW = 14.0;
    const gapAngle = 0.06;

    final total = sections.fold(0.0, (sum, s) => sum + s.value);
    if (total == 0) return;

    double startAngle = -math.pi / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    for (final section in sections) {
      final sweepAngle =
          (section.value / total) * 2 * math.pi * progress - gapAngle;
      if (sweepAngle <= 0) {
        startAngle += (section.value / total) * 2 * math.pi * progress;
        continue;
      }

      final paint = Paint()
        ..color = section.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle + gapAngle;
    }

    // Center text
    final labelPainter = TextPainter(
      text: TextSpan(
        text: centerLabel,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppColors.darkTextAlt,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final subPainter = TextPainter(
      text: TextSpan(
        text: centerSub,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.mediumText,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    labelPainter.paint(
      canvas,
      center - Offset(labelPainter.width / 2, labelPainter.height / 2 + 6),
    );
    subPainter.paint(
      canvas,
      center -
          Offset(subPainter.width / 2, -labelPainter.height / 2 - 2),
    );
  }

  @override
  bool shouldRepaint(_RingChartPainter old) =>
      old.progress != progress || old.sections != sections;
}