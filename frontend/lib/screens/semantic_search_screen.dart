import 'package:bookmind/screens/BookDetailsScreen.dart';
import 'package:bookmind/widgets/book_cards.dart';
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import '../config/color.dart';

class SemanticSearchScreen extends StatefulWidget {
  const SemanticSearchScreen({super.key});

  @override
  State<SemanticSearchScreen> createState() => _SemanticSearchScreenState();
}

class _SemanticSearchScreenState extends State<SemanticSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  bool loading = false;
  String? error;
  List<BookModel> results = [];
  bool _showEmptyError = false;          // ← NEW

  final Set<String> _favorites = {};

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
    _loadFavorites();

    // Clear the empty-error as soon as the user starts typing
    _controller.addListener(() {
      if (_showEmptyError && _controller.text.isNotEmpty) {
        setState(() => _showEmptyError = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to update favourites"),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _searchByText() async {
    final text = _controller.text.trim();

    // ── Validate: show inline error if empty ──────────────────
    if (text.isEmpty) {
      setState(() => _showEmptyError = true);
      return;
    }

    setState(() {
      loading = true;
      error = null;
      results = [];
      _showEmptyError = false;
    });

    try {
      final data = await ApiService.getTextRecommendations(text);
      if (!mounted) return;
      setState(() {
        results = data;
        loading = false;
      });
      if (data.isEmpty) {
        setState(() => error = "No books found for this description.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  void _clear() {
    setState(() {
      _controller.clear();
      results = [];
      error = null;
      _showEmptyError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: _buildSearchSection(),
              ),
            ),
            Expanded(child: _buildResultsArea()),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Icon(Icons.auto_awesome_rounded,
                color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Semantic Search",
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextAlt,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                "Describe what you want to read",
                style: TextStyle(fontSize: 11, color: AppColors.mediumText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search Section ─────────────────────────────────────────

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          // Red border when empty-error is shown, normal otherwise
          border: Border.all(
            color: _showEmptyError ? AppColors.error : AppColors.border,
            width: _showEmptyError ? 1.5 : 1,
          ),
          boxShadow: _showEmptyError
              ? [BoxShadow(
                  color: AppColors.error.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )]
              : AppColors.smallShadow,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchByText(),
              style: TextStyle(fontSize: 14, color: AppColors.darkTextAlt),
              decoration: InputDecoration(
                hintText:
                    "E.g. A student learns magic at a school and fights dark forces…",
                hintStyle:
                    TextStyle(color: AppColors.lightText, fontSize: 13),
                filled: true,
                fillColor: _showEmptyError
                    ? AppColors.error.withOpacity(0.04)
                    : AppColors.surfaceWarm,
                prefixIcon: Icon(Icons.edit_note_rounded,
                    color: _showEmptyError ? AppColors.error : AppColors.primary,
                    size: 22),
                // ── Inline error message ─────────────────
                errorText: _showEmptyError
                    ? "Please enter a description to search for books"
                    : null,
                errorStyle: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                errorMaxLines: 2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _showEmptyError ? AppColors.error : AppColors.border,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _showEmptyError ? AppColors.error : AppColors.border,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _showEmptyError ? AppColors.error : AppColors.accent,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.error, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.error, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: loading ? null : _searchByText,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: loading
                            ? LinearGradient(colors: [
                                AppColors.hintText,
                                AppColors.hintText,
                              ])
                            : AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: loading ? [] : AppColors.glowShadow,
                      ),
                      child: loading
                          ? const Center(
                              child: SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  "Find Matching Books",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: loading ? null : _clear,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Text(
                      "Clear",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Results Area ───────────────────────────────────────────

  Widget _buildResultsArea() {
    if (loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 14),
            Text(
              "Finding your books…",
              style: TextStyle(
                color: AppColors.mediumText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (error != null && results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    color: AppColors.errorLight, shape: BoxShape.circle),
                child: Icon(Icons.sentiment_dissatisfied_rounded,
                    color: AppColors.error, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                error!,
                style: TextStyle(color: AppColors.mediumText, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (results.isEmpty) return _buildEmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Row(
            children: [
              Text(
                "Results",
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.accent.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  "${results.length} books",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: (results.length / 2).ceil(),
            itemBuilder: (_, rowIndex) {
              final left = results[rowIndex * 2];
              final rightIndex = rowIndex * 2 + 1;
              final right =
                  rightIndex < results.length ? results[rightIndex] : null;

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
            },
          ),
        ),
      ],
    );
  }

  void _openDetails(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailsScreen(title: title)),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TRY AN EXAMPLE",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _examples
                .map((ex) => _ExampleChip(
                      label: ex,
                      onTap: () {
                        _controller.text = ex;
                        _searchByText();
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Example data ──────────────────────────────────────────────

const _examples = [
  "Magic school with chosen hero",
  "Space opera with political intrigue",
  "Romance in wartime Paris",
  "Detective solves impossible murders",
  "Self-help for building better habits",
  "Philosophical fiction about meaning",
];

// ── Example Chip ──────────────────────────────────────────────

class _ExampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ExampleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.accent.withOpacity(0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 13, color: AppColors.accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}