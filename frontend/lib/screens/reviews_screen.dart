import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../config/color.dart';
import 'BookDetailsScreen.dart';
import 'write_review_screen.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  bool loading = true;
  String? error;
  List<ReviewModel> myReviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() { loading = true; error = null; });
      final userId = await UserSession.getUserId();
      if (userId == null) {
        setState(() { loading = false; error = "Please login to see your reviews."; });
        return;
      }
      final data = await ApiService.getMyReviews(userId);
      if (!mounted) return;
      setState(() { myReviews = data; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString(); });
    }
  }

  Future<void> _delete(ReviewModel r) async {
    final userId = await UserSession.getUserId();
    if (userId == null) return;
    try {
      await ApiService.deleteReview(userId: userId, bookTitle: r.bookTitle);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e"),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverHeader()],
        body: loading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : error != null
                ? _buildErrorState()
                : myReviews.isEmpty
                    ? _buildEmptyState()
                    : _buildGrid(),
      ),
    );
  }

  // ── Sliver Header ─────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      automaticallyImplyLeading: false,   // ← removes back icon
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: label + title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "MY REVIEWS",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // ── Single line title ─────────────────
                        Text(
                          "Your Reading Opinions",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

                  // Right: count badge
                  if (!loading && myReviews.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: AppColors.border, width: 1),
                      ),
                      child: Text(
                        "${myReviews.length} reviews",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
            height: 1, thickness: 1, color: AppColors.borderLight),
      ),
    );
  }

  // ── 2-column grid ─────────────────────────────────────────────
  Widget _buildGrid() {
    final rows = (myReviews.length / 2).ceil();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        itemCount: rows,
        itemBuilder: (_, rowIndex) {
          final left = myReviews[rowIndex * 2];
          final rightIndex = rowIndex * 2 + 1;
          final right =
              rightIndex < myReviews.length ? myReviews[rightIndex] : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT
                Expanded(
                  child: _ReviewCard(
                    review: left,
                    onView: () => _openDetails(left.bookTitle),
                    onEdit: () => _openEdit(left),
                    onDelete: () => _showDeleteDialog(left),
                  ),
                ),
                const SizedBox(width: 10),
                // RIGHT (or empty spacer)
                Expanded(
                  child: right != null
                      ? _ReviewCard(
                          review: right,
                          onView: () => _openDetails(right.bookTitle),
                          onEdit: () => _openEdit(right),
                          onDelete: () => _showDeleteDialog(right),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openDetails(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailsScreen(title: title)),
    );
  }

  Future<void> _openEdit(ReviewModel r) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => WriteReviewScreen(bookTitle: r.bookTitle)),
    );
    if (changed == true) _load();
  }

  // ── Empty / Error states ──────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(Icons.rate_review_outlined,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              "No reviews yet",
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.darkTextAlt,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Start reviewing books to see them here!",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.mediumText, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: AppColors.errorLight, shape: BoxShape.circle),
              child:
                  Icon(Icons.error_outline, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 12),
            Text("Unable to load reviews",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextAlt)),
            const SizedBox(height: 6),
            Text(error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.mediumText, fontSize: 12.5)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _load,
              icon: Icon(Icons.refresh, color: AppColors.primary),
              label: Text("Retry",
                  style: TextStyle(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(ReviewModel r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Review",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkTextAlt)),
        content: Text("Remove your review for\n\"${r.bookTitle}\"?",
            style:
                TextStyle(color: AppColors.mediumText, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(color: AppColors.mediumText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () { Navigator.pop(context); _delete(r); },
            child: const Text("Delete",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Compact Review Card (2-col) ──────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.review,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onView,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppColors.smallShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top: book icon + rating badge ───────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.menu_book_rounded,
                        color: AppColors.primary, size: 17),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${review.rating}/5",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Title ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                review.bookTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.darkTextAlt,
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 5),

            // ── Stars ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: List.generate(5, (i) => Icon(
                  i < review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 13,
                )),
              ),
            ),

            const SizedBox(height: 8),

            // ── Review snippet ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                review.reviewText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  height: 1.5,
                  color: AppColors.mediumText,
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 10),
            Divider(
                color: AppColors.borderLight,
                height: 1,
                thickness: 1),

            // ── Action row ────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Edit
                  Expanded(
                    child: GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 12, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              "Edit",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Delete
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.delete_outline_rounded,
                          color: AppColors.error, size: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}