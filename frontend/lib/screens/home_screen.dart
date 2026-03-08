import 'package:bookmind/screens/BookDetailsScreen.dart';
import 'package:bookmind/screens/ai_insights_screen.dart';
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../widgets/book_cards.dart';
import '../config/color.dart';
import 'recommendation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────
  final TextEditingController recommendController = TextEditingController();
  final TextEditingController exactController = TextEditingController();
  late TabController _tabController;

  // ── Search states ─────────────────────────────────────────────
  bool searchingRecommend = false;
  bool searchingExact = false;
  bool _searchExpanded = false;

  // ── Page states ───────────────────────────────────────────────
  bool loading = true;
  bool isFirstLogin = true;

  // ── AI Insights ───────────────────────────────────────────────
  bool insightsLoading = true;
  Map<String, dynamic>? insightsMe;
  String? insightsError;

  // ── Filters ───────────────────────────────────────────────────
  final List<String> emotions = [
    "Happy", "Inspirational", "Dark", "Romantic",
    "Adventurous", "mysterious", "scary", "philosophical",
  ];
  final List<String> interests = [
    "fantasy", "historical", "biography", "self-help", "psychology",
    "business", "finance", "technology", "programming", "data-science",
    "art", "design", "poetry", "education", "travel", "health", "fitness",
    "mythology", "politics", "law", "environment", "spirituality", "children",
    "young-adult", "parenting", "sports", "cook",
  ];

  List<String> savedEmotions = [];
  List<String> savedInterests = [];
  List<String> pickedEmotions = [];
  List<String> pickedInterests = [];

  // ── Book lists ────────────────────────────────────────────────
  List<BookModel> searchBasedBooks = [];
  List<BookModel> hybridBooks = [];
  List<BookModel> interestBooks = [];
  List<BookModel> emotionBooks = [];

  // ── Favourites ────────────────────────────────────────────────
  final Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initHome();
  }

  @override
  void dispose() {
    recommendController.dispose();
    exactController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────
  Future<void> _initHome() async {
    isFirstLogin = await UserSession.isFirstLogin();
    savedInterests = await UserSession.getInterests();
    savedEmotions = await UserSession.getEmotions();
    pickedInterests = List<String>.from(savedInterests);
    pickedEmotions = List<String>.from(savedEmotions);

    await Future.wait([
      _loadAll(),
      _loadInsightsPreview(),
      _loadFavorites(),
    ]);

    if (mounted) setState(() => loading = false);

    if (isFirstLogin) {
      await UserSession.markVisited();
      if (mounted) setState(() => isFirstLogin = false);
    }
  }

  Future<void> _loadAll() async {
    try {
      await Future.wait([
        _loadSearchBased(),
        if (!isFirstLogin) _loadHybrid(),
        _loadInterest(),
        _loadEmotion(),
      ]);
    } catch (e) {
      debugPrint("Home load error: $e");
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await ApiService.fetchFavorites();
      if (!mounted) return;
      setState(() => _favorites.addAll(favs.cast<String>()));
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String title) async {
    final isNowFav = !_favorites.contains(title);
    setState(() {
      if (isNowFav) {
        _favorites.add(title);
      } else {
        _favorites.remove(title);
      }
    });
    try {
      if (isNowFav) {
        await ApiService.addFavorite(title);
      } else {
        await ApiService.removeFavorite(title);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (isNowFav) _favorites.remove(title);
        else _favorites.add(title);
      });
    }
  }

  Future<void> _loadInsightsPreview() async {
    try {
      if (mounted) setState(() { insightsLoading = true; insightsError = null; });
      final me = await ApiService.getInsightsMe();
      if (!mounted) return;
      setState(() { insightsMe = me; insightsLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { insightsLoading = false; insightsError = "Failed to load"; });
    }
  }

  Future<void> _loadSearchBased() async {
    try {
      final data = await ApiService.getRecommendations("Harry Potter");
      if (mounted) setState(() => searchBasedBooks = data);
    } catch (_) {}
  }

  Future<void> _loadHybrid() async {
    final interestsToUse = pickedInterests.isNotEmpty ? pickedInterests : savedInterests;
    final emotionsToUse = pickedEmotions.isNotEmpty ? pickedEmotions : savedEmotions;
    if (interestsToUse.isEmpty && emotionsToUse.isEmpty) return;
    try {
      final data = await ApiService.getHybridRecommendations(interestsToUse, emotionsToUse);
      if (mounted) setState(() => hybridBooks = data);
    } catch (_) {}
  }

  Future<void> _loadInterest() async {
    final interestsToUse = pickedInterests.isNotEmpty ? pickedInterests : savedInterests;
    if (interestsToUse.isEmpty) return;
    try {
      final data = await ApiService.getInterestRecommendations(interestsToUse);
      if (mounted) setState(() => interestBooks = data);
    } catch (_) {
      if (mounted) setState(() => interestBooks = []);
    }
  }

  Future<void> _loadEmotion() async {
    final emotionsToUse = pickedEmotions.isNotEmpty ? pickedEmotions : savedEmotions;
    if (emotionsToUse.isEmpty) return;
    try {
      final data = await ApiService.getEmotionRecommendations(emotionsToUse);
      if (mounted) setState(() => emotionBooks = data);
    } catch (_) {
      if (mounted) setState(() => emotionBooks = []);
    }
  }

  // ── Search actions ─────────────────────────────────────────────
 Future<void> searchRecommend() async {
  final query = recommendController.text.trim();
  if (query.isEmpty) return;
  try {
    setState(() => searchingRecommend = true);
    final results = await ApiService.getRecommendations(query);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendationScreen(
          recommendations: results,
          searchQuery: query,          // ← ADD THIS LINE
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to get recommendations")),
    );
  } finally {
    if (mounted) setState(() => searchingRecommend = false);
  }
}
  Future<void> searchExactBook() async {
    final query = exactController.text.trim();
    if (query.isEmpty) return;
    try {
      setState(() => searchingExact = true);
      final data = await ApiService.searchBooks(query, limit: 10);
      final exact = data["exact"];
      final List results = data["results"] ?? [];
      if (!mounted) return;
      if (exact != null && exact["title"] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailsScreen(title: exact["title"].toString()),
          ),
        );
        return;
      }
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No matching books found")),
        );
        return;
      }
      _showSearchSuggestions(results);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Search failed. Check backend URL.")),
      );
    } finally {
      if (mounted) setState(() => searchingExact = false);
    }
  }

  void _showSearchSuggestions(List results) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    "Search Results",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkTextAlt,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${results.length} found",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: AppColors.borderLight, height: 1),
                  itemBuilder: (_, i) {
                    final item = results[i] as Map<String, dynamic>;
                    final title = (item["title"] ?? "").toString();
                    final author = (item["author"] ?? "Unknown").toString();
                    final image = (item["image"] ?? "").toString();
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: image.isEmpty
                            ? Container(
                                width: 42,
                                height: 56,
                                color: AppColors.primaryLight,
                                child: Icon(Icons.book, color: AppColors.primary),
                              )
                            : Image.network(
                                image,
                                width: 42,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 42,
                                  height: 56,
                                  color: AppColors.primaryLight,
                                  child: Icon(Icons.book, color: AppColors.primary),
                                ),
                              ),
                      ),
                      title: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.darkTextAlt,
                        ),
                      ),
                      subtitle: Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.mediumText),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookDetailsScreen(title: title),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMultiSelect({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onApply,
  }) async {
    List<String> tempSelected = List<String>.from(selectedValues);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextAlt,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: ListView(
                  children: options.map((item) {
                    final checked = tempSelected.contains(item);
                    return CheckboxListTile(
                      title: Text(item,
                          style: TextStyle(
                              fontSize: 13, color: AppColors.darkText)),
                      value: checked,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setSheetState(() {
                        if (val == true) tempSelected.add(item);
                        else tempSelected.remove(item);
                      }),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        setSheetState(() => tempSelected.clear()),
                    child: Text("Clear",
                        style: TextStyle(color: AppColors.mediumText)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onApply(tempSelected);
                    },
                    child: const Text("Apply",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Column(
      children: [
        // ── Top Header ─────────────────────────────────────────
        _buildHeader(),

        // ── TabBar ─────────────────────────────────────────────
        _buildTabBar(),

        // ── Tab Content ────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _tabPicks(),
              _tabInterests(),
              _tabMood(),
              _tabAIPicks(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _buildHeader() {
    // final username = UserSession.user?["username"] ?? "Reader";

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mediumText,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      "Welcome back, Reader!",
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkTextAlt,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // AI Insights mini button
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AiInsightsScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insights,
                          size: 15, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        "Insights",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Compact Search Bar ──────────────────────────────
          Row(
            children: [
              // Recommend search
              Expanded(
                child: _CompactSearchField(
                  controller: recommendController,
                  hint: "AI Book Suggestions…",
                  icon: Icons.auto_awesome_rounded,
                  loading: searchingRecommend,
                  onSubmit: searchRecommend,
                ),
              ),
              const SizedBox(width: 8),
              // Exact book search
              Expanded(
                child: _CompactSearchField(
                  controller: exactController,
                  hint: "Find exact book…",
                  icon: Icons.menu_book_rounded,
                  loading: searchingExact,
                  onSubmit: searchExactBook,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // ── Stats strip ─────────────────────────────────────
          _buildStatsStrip(),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildStatsStrip() {
    if (insightsLoading) return const SizedBox(height: 36);

    final stats =
        (insightsMe?["stats"] as Map?)?.cast<String, dynamic>() ?? {};
    final views = (stats["total_book_views"] ?? 0).toString();
    final favs = (stats["favorites_added"] ?? 0).toString();
    final reviews = (stats["reviews_count"] ?? 0).toString();

    return Row(
      children: [
        _statPill(Icons.visibility_outlined, "$views views"),
        const SizedBox(width: 8),
        _statPill(Icons.favorite_border_rounded, "$favs saved"),
        const SizedBox(width: 8),
        _statPill(Icons.rate_review_outlined, "$reviews reviews"),
        const Spacer(),
        GestureDetector(
          onTap: insightsLoading ? null : _loadInsightsPreview,
          child: Icon(Icons.refresh_rounded,
              size: 16, color: AppColors.hintText),
        ),
      ],
    );
  }

  Widget _statPill(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.mediumText),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.mediumText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── TabBar ────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primaryDark,
            unselectedLabelColor: AppColors.hintText,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary,
                  width: 2.5,
                ),
              ),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: "Book Picks"),
              Tab(text: "Interests"),
              Tab(text: "Mood"),
              Tab(text: "AI Hybrid"),
            ],
          ),
          Divider(
              height: 1, thickness: 1, color: AppColors.borderLight),
        ],
      ),
    );
  }

  // ── Tab 1: Book Picks ─────────────────────────────────────────

  Widget _tabPicks() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await _loadSearchBased();
        await _loadInsightsPreview();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _sectionHeader(
            "📖 Book Suggestions",
            subtitle: "Readers also enjoyed these",
          ),
          const SizedBox(height: 12),
          if (searchBasedBooks.isEmpty)
            _emptyState("No suggestions available", Icons.menu_book_outlined)
          else
            _twoColGrid(searchBasedBooks),
        ],
      ),
    );
  }

  // ── Tab 2: Interests ──────────────────────────────────────────

  Widget _tabInterests() {
    final activeInterests =
        pickedInterests.isNotEmpty ? pickedInterests : savedInterests;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => await _loadInterest(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Header + filter button
          Row(
            children: [
              Expanded(
                child: _sectionHeader(
                  "🎯 Based on Your Interests",
                  subtitle: activeInterests.isNotEmpty
                      ? activeInterests.take(3).join(', ') +
                          (activeInterests.length > 3 ? '…' : '')
                      : "No interests set",
                ),
              ),
              _filterButton(
                onTap: () async {
                  await _openMultiSelect(
                    title: "Select Interests",
                    options: interests,
                    selectedValues: pickedInterests,
                    onApply: (vals) async {
                      setState(() => pickedInterests = vals);
                      await _loadInterest();
                      await _loadHybrid();
                    },
                  );
                },
                onClear: pickedInterests.isNotEmpty
                    ? () async {
                        setState(() => pickedInterests = []);
                        await _loadInterest();
                        await _loadHybrid();
                      }
                    : null,
              ),
            ],
          ),

          // Active filter chips
          if (activeInterests.isNotEmpty) ...[
            const SizedBox(height: 10),
            _filterChips(activeInterests, AppColors.primary),
          ],

          const SizedBox(height: 14),

          if (interestBooks.isEmpty)
            _emptyState(
                "No books for selected interests", Icons.interests_rounded)
          else
            _twoColGrid(interestBooks),
        ],
      ),
    );
  }

  // ── Tab 3: Mood ───────────────────────────────────────────────

  Widget _tabMood() {
    final activeEmotions =
        pickedEmotions.isNotEmpty ? pickedEmotions : savedEmotions;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => await _loadEmotion(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionHeader(
                  "💭 Mood-Based Reads",
                  subtitle: activeEmotions.isNotEmpty
                      ? activeEmotions.take(3).join(', ') +
                          (activeEmotions.length > 3 ? '…' : '')
                      : "No mood set",
                ),
              ),
              _filterButton(
                onTap: () async {
                  await _openMultiSelect(
                    title: "Select Mood",
                    options: emotions,
                    selectedValues: pickedEmotions,
                    onApply: (vals) async {
                      setState(() => pickedEmotions = vals);
                      await _loadEmotion();
                      await _loadHybrid();
                    },
                  );
                },
                onClear: pickedEmotions.isNotEmpty
                    ? () async {
                        setState(() => pickedEmotions = []);
                        await _loadEmotion();
                        await _loadHybrid();
                      }
                    : null,
              ),
            ],
          ),

          if (activeEmotions.isNotEmpty) ...[
            const SizedBox(height: 10),
            _filterChips(activeEmotions, const Color(0xFFE85D75)),
          ],

          const SizedBox(height: 14),

          if (emotionBooks.isEmpty)
            _emptyState("No books for selected moods", Icons.mood_rounded)
          else
            _twoColGrid(emotionBooks),
        ],
      ),
    );
  }

  // ── Tab 4: AI Hybrid ──────────────────────────────────────────

  Widget _tabAIPicks() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => await _loadHybrid(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _sectionHeader(
            "🤖 AI Picks for You",
            subtitle: "Personalized by mood + interests",
          ),
          const SizedBox(height: 12),
          if (isFirstLogin)
            _emptyState(
                "Complete your profile to see AI picks",
                Icons.auto_awesome_rounded)
          else if (hybridBooks.isEmpty)
            _emptyState("No AI picks yet. Update your profile!",
                Icons.psychology_rounded)
          else
            _twoColGrid(hybridBooks),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SHARED UI HELPERS
  // ══════════════════════════════════════════════════════════════

  // ── 2-column BookCards list ───────────────────────────────────
  Widget _twoColGrid(List<BookModel> books) {
    final rows = (books.length / 2).ceil();
    return Column(
      children: List.generate(rows, (rowIndex) {
        final left = books[rowIndex * 2];
        final rightIndex = rowIndex * 2 + 1;
        final right =
            rightIndex < books.length ? books[rightIndex] : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: BookCards(
                  book: left,
                  onTap: () => _openDetails(left.title),
                  isFavorite: _favorites.contains(left.title),
                  onFavoriteToggle: () => _toggleFavorite(left.title),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: right != null
                    ? BookCards(
                        book: right,
                        onTap: () => _openDetails(right.title),
                        isFavorite: _favorites.contains(right.title),
                        onFavoriteToggle: () =>
                            _toggleFavorite(right.title),
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _openDetails(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsScreen(title: title),
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────
  Widget _sectionHeader(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTextAlt,
            letterSpacing: -0.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.mediumText,
            ),
          ),
        ],
      ],
    );
  }

  // ── Filter button + clear ─────────────────────────────────────
  Widget _filterButton({
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded,
                    size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  "Filter",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onClear != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close_rounded,
                size: 16, color: AppColors.error),
          ),
        ],
      ],
    );
  }

  // ── Filter chips row ──────────────────────────────────────────
  Widget _filterChips(List<String> items, Color color) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: color.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────
  Widget _emptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.hintText, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mediumText,
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning,";
    if (hour < 17) return "Good afternoon,";
    return "Good evening,";
  }
}

// ══════════════════════════════════════════════════════════════
//  Compact Search Field
// ══════════════════════════════════════════════════════════════

class _CompactSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool loading;
  final VoidCallback onSubmit;

  const _CompactSearchField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmit(),
      style: TextStyle(
        fontSize: 12.5,
        color: AppColors.darkTextAlt,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.hintText,
          fontSize: 12,
        ),
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        suffixIcon: loading
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            : GestureDetector(
                onTap: onSubmit,
                child: Icon(Icons.arrow_forward_rounded,
                    size: 17, color: AppColors.primary),
              ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}