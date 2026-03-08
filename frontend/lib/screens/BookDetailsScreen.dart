import 'package:bookmind/models/review_model.dart';
import 'package:bookmind/screens/write_review_screen.dart';
import 'package:flutter/material.dart';

import '../models/book_model.dart';
import '../models/community_post_model.dart';
import '../services/api_service.dart';
import '../config/color.dart';
import 'community_post_details_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final String title;
  const BookDetailsScreen({super.key, required this.title});
  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen>
    with TickerProviderStateMixin {
  bool loading = true;
  BookModel? book;
  String? error;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late TabController _tabController;
  bool reviewsLoading = true;
  double avgRating = 0.0;
  int totalReviews = 0;
  List<ReviewModel> reviews = [];
  bool communityLoading = true;
  List<CommunityPostModel> communityPosts = [];
  bool isFavorite = false;
  bool loadingFavorite = true;
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _tabController = TabController(length: 2, vsync: this);
    _loadBook();
    _loadReviews();
    _loadCommunityPosts();
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => reviewsLoading = true);
      final res = await ApiService.getReviewsForBook(widget.title);
      final list = (res["reviews"] as List?) ?? [];
      final parsed = list.map((e) => ReviewModel.fromJson(e)).toList();
      if (!mounted) return;
      setState(() {
        avgRating = (res["avg_rating"] ?? 0).toDouble();
        totalReviews = (res["total_reviews"] ?? 0) is int
            ? res["total_reviews"]
            : int.tryParse(res["total_reviews"].toString()) ?? 0;
        reviews = parsed;
        reviewsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => reviewsLoading = false);
    }
  }

  Future<void> _loadCommunityPosts() async {
    try {
      setState(() => communityLoading = true);
      final posts = await ApiService.fetchPostsByBook(widget.title);
      if (!mounted) return;
      setState(() { communityPosts = posts; communityLoading = false; });
    } catch (e) {
      debugPrint("Community posts error: $e");
      if (!mounted) return;
      setState(() => communityLoading = false);
    }
  }

  Future<void> _loadBook() async {
    try {
      final data = await ApiService.getBookDetails(widget.title);
      if (!mounted) return;
      setState(() { book = data; loading = false; });
      _fadeController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() { error = "Book not found"; loading = false; });
    }
  }

  Future<void> _checkIfFavorite() async {
    try {
      final favorites = await ApiService.fetchFavorites();
      if (favorites.contains(widget.title)) isFavorite = true;
    } catch (_) {}
    if (mounted) setState(() => loadingFavorite = false);
  }

  Future<void> _toggleFavorite() async {
    try {
      if (isFavorite) {
        await ApiService.removeFavorite(widget.title);
        setState(() => isFavorite = false);
        _showSnack("Removed from favorites", const Color(0xFF555555));
      } else {
        await ApiService.addFavorite(widget.title);
        setState(() => isFavorite = true);
        _showSnack("Added to favorites ⭐", AppColors.primary);
      }
    } catch (e) { _showSnack(e.toString(), AppColors.error); }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _toggleLikeCommunity(int index) async {
    try {
      final updated = await ApiService.toggleLike(communityPosts[index].id);
      if (!mounted) return;
      setState(() => communityPosts[index] = updated);
    } catch (e) { debugPrint("Like error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // ── No AppBar — nav icons live inside the left panel ──
      body: loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : error != null
              ? _buildError()
              : FadeTransition(opacity: _fadeAnim, child: _buildContent()),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: Icon(Icons.menu_book_outlined, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(error!, style: TextStyle(color: AppColors.mediumText, fontSize: 16, fontFamily: 'Georgia')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final b = book!;
    // No separate nav bar — the left panel handles back/bookmark
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT 40%
        _LeftCoverPanel(
          b: b,
          avgRating: avgRating,
          totalReviews: totalReviews,
          isFavorite: isFavorite,
          loadingFavorite: loadingFavorite,
          onBack: () => Navigator.pop(context),
          onToggleFavorite: loadingFavorite ? null : _toggleFavorite,
        ),
        // RIGHT 60%
        Expanded(
          flex: 60,
          child: _RightDetailsPanel(
            b: b,
            reviews: reviews, reviewsLoading: reviewsLoading,
            communityPosts: communityPosts, communityLoading: communityLoading,
            tabController: _tabController,
            descExpanded: _descExpanded,
            onToggleDesc: () => setState(() => _descExpanded = !_descExpanded),
            onToggleLike: _toggleLikeCommunity,
            onWriteReview: () async {
              final changed = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => WriteReviewScreen(bookTitle: b.title)));
              if (changed == true) { await _loadReviews(); await _loadCommunityPosts(); }
            },
            onPostTap: (p) async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CommunityPostDetailsScreen(post: p)));
              await _loadCommunityPosts();
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LEFT PANEL (flex: 40) — light background, icons embedded
// ═══════════════════════════════════════════════════════════════

class _LeftCoverPanel extends StatelessWidget {
  final BookModel b;
  final double avgRating;
  final int totalReviews;
  final bool isFavorite;
  final bool loadingFavorite;
  final VoidCallback onBack;
  final VoidCallback? onToggleFavorite;

  const _LeftCoverPanel({
    required this.b,
    required this.avgRating,
    required this.totalReviews,
    required this.isFavorite,
    required this.loadingFavorite,
    required this.onBack,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final panelW = screenW * 0.40;

    return Container(
      width: panelW,
      height: double.infinity,
      // ── Same light background as the rest of the screen ──
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Nav icons row (back + bookmark) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBack,
                  ),
                  _NavIconButton(
                    icon: isFavorite
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isFavorite ? AppColors.primary : null,
                    onTap: onToggleFavorite,
                    isLoading: loadingFavorite,
                  ),
                ],
              ),
              const SizedBox(height: 14),


              // ── Book cover — 72% of panel width ──
              _BookCoverWidget(
                imageUrl: b.image,
                width: panelW * 0.62,
                height: screenH * 0.6,
              ),
              const SizedBox(height: 20),

              // ── Stars — bigger ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  if (i < avgRating.floor())
                    return Icon(Icons.star_rounded, color: Colors.amber, size: 22);
                  else if (i < avgRating)
                    return Icon(Icons.star_half_rounded, color: Colors.amber, size: 22);
                  return Icon(Icons.star_outline_rounded,
                      color: Colors.amber.withOpacity(0.35), size: 22);
                }),
              ),
              const SizedBox(height: 7),

              // ── Rating text — bigger ──
              Text(
                avgRating.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                  letterSpacing: -0.5,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "$totalReviews ratings",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.mediumText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // ── Genre pills — now dark-tinted to suit light bg ──
              if (b.genres.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: b.genres
                      .take(3)
                      .map((g) => _LightGenrePill(label: g))
                      .toList(),
                ),

              const Spacer(),

              // ── Year badge ──
              if (b.year != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2), width: 1),
                  ),
                  child: Text(
                    '${b.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BOOK COVER WIDGET — with "Not Found" fallback
// ═══════════════════════════════════════════════════════════════

class _BookCoverWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  const _BookCoverWidget({required this.imageUrl, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 12), spreadRadius: -4),
          BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? Image.network(imageUrl!, width: width, height: height, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _notFoundWidget(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _loadingWidget();
                })
            : _notFoundWidget(),
      ),
    );
  }

  Widget _notFoundWidget() {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(Icons.auto_stories_rounded, size: 28, color: AppColors.primary.withOpacity(0.65)),
          ),
          const SizedBox(height: 14),
          Text("Book Cover",
              style: TextStyle(color: AppColors.mediumText, fontSize: 11,
                  fontFamily: 'Georgia', fontStyle: FontStyle.italic, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text("Not Found",
              style: TextStyle(color: AppColors.lightText, fontSize: 10,
                  fontFamily: 'Georgia', fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _loadingWidget() {
    return Container(width: width, height: height,
      color: AppColors.primaryLight,
      child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)));
  }
}

// ═══════════════════════════════════════════════════════════════
//  RIGHT PANEL (flex: 60)
// ═══════════════════════════════════════════════════════════════

class _RightDetailsPanel extends StatelessWidget {
  final BookModel b;
  final List<ReviewModel> reviews;
  final bool reviewsLoading;
  final List<CommunityPostModel> communityPosts;
  final bool communityLoading;
  final TabController tabController;
  final bool descExpanded;
  final VoidCallback onToggleDesc;
  final Future<void> Function(int) onToggleLike;
  final VoidCallback onWriteReview;
  final Future<void> Function(CommunityPostModel) onPostTap;

  const _RightDetailsPanel({
    required this.b, required this.reviews, required this.reviewsLoading,
    required this.communityPosts, required this.communityLoading,
    required this.tabController, required this.descExpanded,
    required this.onToggleDesc, required this.onToggleLike,
    required this.onWriteReview, required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), bottomLeft: Radius.circular(28)),
        boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.15), blurRadius: 28, offset: const Offset(-8, 0))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), bottomLeft: Radius.circular(28)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BIG TITLE
              Text(b.title, style: const TextStyle(
                fontFamily: 'Georgia', fontSize: 26, fontWeight: FontWeight.bold,
                color: Color(0xFF0F2A1E), height: 1.25, letterSpacing: -0.4,
              )),
              const SizedBox(height: 10),

              // AUTHOR with accent bar
              Row(
                children: [
                  Container(width: 3.5, height: 18,
                    decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 9),
                  Text("by ", style: TextStyle(fontSize: 13, color: AppColors.lightText,
                      fontStyle: FontStyle.italic, fontFamily: 'Georgia')),
                  Flexible(child: Text(b.author ?? 'Unknown Author',
                    style: TextStyle(fontSize: 14.5, color: AppColors.primary,
                        fontWeight: FontWeight.w700, letterSpacing: 0.2),
                    overflow: TextOverflow.ellipsis)),
                ],
              ),

              const SizedBox(height: 24),
              const _MintDivider(),
              const SizedBox(height: 22),

              // ABOUT
              const _SectionHeader(label: "About"),
              const SizedBox(height: 10),
              _ExpandableText(text: b.description ?? "No description available.",
                  expanded: descExpanded, onToggle: onToggleDesc),

              const SizedBox(height: 22),
              const _MintDivider(),
              const SizedBox(height: 22),

              // AI SUMMARY
              const _SectionHeader(label: "AI Summary"),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.accentLight.withOpacity(0.6)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b.summary ?? "No summary available.",
                    style: TextStyle(height: 1.7, color: AppColors.darkText, fontSize: 13,
                        fontStyle: FontStyle.italic, fontFamily: 'Georgia'))),
                ]),
              ),

              const SizedBox(height: 22),
              const _MintDivider(),
              const SizedBox(height: 22),

              // EMOTIONS + INTERESTS
              if ((b.emotion != null && b.emotion!.isNotEmpty) || b.interestTags.isNotEmpty)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (b.emotion != null && b.emotion!.isNotEmpty)
                    Expanded(child: _TagSection(label: "Emotions", icon: Icons.favorite_rounded,
                        color: const Color(0xFFE85D75),
                        tags: b.emotion!.split(',').map((e) => e.trim()).toList())),
                  if ((b.emotion != null && b.emotion!.isNotEmpty) && b.interestTags.isNotEmpty)
                    const SizedBox(width: 12),
                  if (b.interestTags.isNotEmpty)
                    Expanded(child: _TagSection(label: "Interests", icon: Icons.tag_rounded,
                        color: AppColors.accent, tags: b.interestTags)),
                ]),

              if (b.sentimentLabel != null) ...[
                const SizedBox(height: 14),
                _SentimentBadge(label: b.sentimentLabel!, score: b.sentimentScore),
              ],

              const SizedBox(height: 22),
              const _MintDivider(),
              const SizedBox(height: 22),

              // COMMUNITY
              Row(children: [
                const Expanded(child: _SectionHeader(label: "Community")),
                _WriteReviewButton(onTap: onWriteReview),
              ]),
              const SizedBox(height: 14),

              // Pill Tab Bar
              Container(
                decoration: BoxDecoration(color: AppColors.backgroundAlt, borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.all(3),
                child: TabBar(
                  controller: tabController,
                  indicator: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.mediumText,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.star_rounded, size: 13), SizedBox(width: 5), Text("Reviews")])),
                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.forum_rounded, size: 13), SizedBox(width: 5), Text("Posts")])),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              AnimatedBuilder(
                animation: tabController,
                builder: (context, _) {
                  if (tabController.index == 0) return _buildReviewsTab();
                  return _buildCommunityTab();
                },
              ),

              const SizedBox(height: 24),
              const _MintDivider(),
              const SizedBox(height: 24),

              // WHY THIS BOOK
              const _SectionHeader(label: "Why This Book?"),
              const SizedBox(height: 14),
              _WhyThisBookCard(b: b),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (reviewsLoading) return Padding(padding: const EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    if (reviews.isEmpty) return const _EmptyState(icon: Icons.rate_review_outlined, message: "No reviews yet.\nBe the first! 📝");
    return Column(children: reviews.take(5).map((r) => _ReviewCard(review: r)).toList());
  }

  Widget _buildCommunityTab() {
    if (communityLoading) return Padding(padding: const EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    if (communityPosts.isEmpty) return const _EmptyState(icon: Icons.forum_outlined, message: "No community posts yet.\nBe the first! 👀");
    return Column(
      children: communityPosts.take(5).toList().asMap().entries.map((entry) =>
          _CommunityCard(post: entry.value, onLike: () => onToggleLike(entry.key), onTap: () => onPostTap(entry.value))).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool isLoading;
  const _NavIconButton({required this.icon, this.onTap, this.color, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))]),
        child: isLoading
            ? Center(child: SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
            : Icon(icon, size: 17, color: color ?? AppColors.darkText.withOpacity(0.65)),
      ),
    );
  }
}

/// Light-background genre pill (replaces the dark glass pill)
class _LightGenrePill extends StatelessWidget {
  final String label;
  const _LightGenrePill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Text(label,
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          )),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: TextStyle(fontFamily: 'Georgia', fontSize: 17,
          fontWeight: FontWeight.bold, color: AppColors.darkTextAlt)),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1,
        decoration: BoxDecoration(gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.3), Colors.transparent])))),
    ]);
  }
}

class _MintDivider extends StatelessWidget {
  const _MintDivider();
  @override
  Widget build(BuildContext context) {
    return Container(height: 1,
      decoration: BoxDecoration(gradient: LinearGradient(
          colors: [Colors.transparent, AppColors.border, Colors.transparent])));
  }
}

class _ExpandableText extends StatelessWidget {
  final String text;
  final bool expanded;
  final VoidCallback onToggle;
  const _ExpandableText({required this.text, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(text, style: TextStyle(height: 1.75, color: AppColors.mediumText, fontSize: 13.5, fontFamily: 'Georgia'),
          maxLines: expanded ? null : 5,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis),
      if (text.length > 200) ...[
        const SizedBox(height: 6),
        GestureDetector(onTap: onToggle,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(expanded ? "Show less" : "Read more",
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
            const SizedBox(width: 3),
            Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 16, color: AppColors.primary),
          ])),
      ],
    ]);
  }
}

class _TagSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> tags;
  const _TagSection({required this.label, required this.icon, required this.color, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color, letterSpacing: 1.2)),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6,
        children: tags.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2), width: 1)),
          child: Text(t, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        )).toList()),
    ]);
  }
}

class _SentimentBadge extends StatelessWidget {
  final String label;
  final double? score;
  const _SentimentBadge({required this.label, this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.backgroundAlt, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight, width: 1)),
      child: Row(children: [
        Icon(Icons.psychology_rounded, size: 16, color: AppColors.mediumText),
        const SizedBox(width: 8),
        Text("Sentiment: ", style: TextStyle(fontSize: 12.5, color: AppColors.mediumText)),
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.darkText)),
        if (score != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(score!.toStringAsFixed(2),
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11.5)),
          ),
        ],
      ]),
    );
  }
}

class _WriteReviewButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WriteReviewButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.edit_outlined, color: Colors.white, size: 13),
          SizedBox(width: 5),
          Text("Write Review", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceWarm, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight, width: 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: Center(child: Text(
              review.username.isNotEmpty ? review.username[0].toUpperCase() : "U",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(review.username, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText, fontSize: 13.5)),
            const SizedBox(height: 3),
            Row(children: List.generate(5, (i) => Icon(
              i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 12))),
          ])),
        ]),
        const SizedBox(height: 10),
        Text(review.reviewText, style: TextStyle(height: 1.65, color: AppColors.mediumText, fontSize: 13, fontFamily: 'Georgia'),
            maxLines: 4, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final CommunityPostModel post;
  final VoidCallback onLike;
  final VoidCallback onTap;
  const _CommunityCard({required this.post, required this.onLike, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.surfaceWarm, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight, width: 1)),
      child: Material(color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14),
          child: Padding(padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 34, height: 34,
                  decoration: const BoxDecoration(gradient: AppColors.accentGradient, shape: BoxShape.circle),
                  child: Center(child: Text(
                    post.username.isNotEmpty ? post.username[0].toUpperCase() : "U",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)))),
                const SizedBox(width: 8),
                Expanded(child: Text(post.username,
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText, fontSize: 13.5))),
                if (post.rating > 0) Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                  const SizedBox(width: 3),
                  Text("${post.rating}", style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.mediumText, fontSize: 12.5)),
                ]),
              ]),
              const SizedBox(height: 9),
              Text(post.text, style: TextStyle(height: 1.6, color: AppColors.mediumText, fontSize: 13, fontFamily: 'Georgia')),
              const SizedBox(height: 10),
              Row(children: [
                GestureDetector(onTap: onLike, child: Row(children: [
                  Icon(post.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: post.likedByMe ? Colors.red[400] : AppColors.hintText, size: 17),
                  const SizedBox(width: 4),
                  Text("${post.likesCount}", style: TextStyle(
                      color: post.likedByMe ? Colors.red[400] : AppColors.lightText,
                      fontWeight: FontWeight.w600, fontSize: 12.5)),
                ])),
                const SizedBox(width: 14),
                Icon(Icons.chat_bubble_outline_rounded, color: AppColors.hintText, size: 15),
                const SizedBox(width: 4),
                Text("${post.commentsCount}", style: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.w600, fontSize: 12.5)),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: AppColors.hintText, size: 11),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _WhyThisBookCard extends StatelessWidget {
  final BookModel b;
  const _WhyThisBookCard({required this.b});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.accentLight],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Row(children: [
            Icon(Icons.auto_awesome, color: AppColors.primary, size: 15),
            const SizedBox(width: 7),
            Text("Curated For You", style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            if (b.emotion != null && b.emotion!.isNotEmpty)
              _reasonRow("Matches your mood", "Emotions like ${b.emotion}", Icons.mood_rounded),
            if (b.interestTags.isNotEmpty)
              _reasonRow("Aligned with your interests", b.interestTags.join(', '), Icons.interests_rounded),
            if (b.genres.isNotEmpty)
              _reasonRow("Genre match", b.genres.join(', '), Icons.category_rounded),
            if (b.aiReason.isNotEmpty) ...[
              Divider(color: AppColors.primary.withOpacity(0.15), height: 20),
              ...b.aiReason.map((r) => _reasonRow("AI Insight", r, Icons.psychology_rounded)),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _reasonRow(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 30, height: 30,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary, size: 14)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText, fontSize: 13)),
          const SizedBox(height: 2),
          Text(description, style: TextStyle(height: 1.5, color: AppColors.mediumText, fontSize: 12)),
        ])),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(color: AppColors.backgroundAlt, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight)),
      child: Column(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary.withOpacity(0.5), size: 26)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.lightText, height: 1.55, fontSize: 13,
                fontFamily: 'Georgia', fontStyle: FontStyle.italic)),
      ]),
    );
  }
}