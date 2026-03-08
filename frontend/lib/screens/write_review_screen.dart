import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../config/color.dart';

class WriteReviewScreen extends StatefulWidget {
  final String bookTitle;

  const WriteReviewScreen({super.key, required this.bookTitle});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  int rating = 5;
  final TextEditingController reviewCtrl = TextEditingController();
  bool saving = false;

  // ── Rating label ───────────────────────────────────────────────
  String get _ratingLabel {
    switch (rating) {
      case 1: return "Poor";
      case 2: return "Fair";
      case 3: return "Good";
      case 4: return "Great";
      case 5: return "Excellent!";
      default: return "";
    }
  }

  Color get _ratingColor {
    switch (rating) {
      case 1: return AppColors.error;
      case 2: return Colors.orange;
      case 3: return Colors.amber;
      case 4: return AppColors.primary;
      case 5: return AppColors.accent;
      default: return AppColors.primary;
    }
  }

  Future<void> _submit() async {
    final userId = await UserSession.getUserId();
    final username = await UserSession.getUsername();

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please login to review."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final text = reviewCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please write your review first."),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await ApiService.saveReview(
        userId: userId,
        username: username ?? "Anonymous",
        bookTitle: widget.bookTitle,
        rating: rating,
        reviewText: text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Save failed: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryDark),
        title: Text(
          "Write a Review",
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTextAlt,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, thickness: 1, color: AppColors.borderLight),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Book title card ──────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.border, width: 1),
                  boxShadow: AppColors.smallShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Reviewing",
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mediumText,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.bookTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkTextAlt,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Rating section ────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.border, width: 1),
                  boxShadow: AppColors.smallShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Your Rating",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkTextAlt,
                          ),
                        ),
                        const Spacer(),
                        // Rating label pill
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _ratingColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _ratingColor.withOpacity(0.4),
                                width: 1),
                          ),
                          child: Text(
                            _ratingLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _ratingColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Stars row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final filled = (i + 1) <= rating;
                        return GestureDetector(
                          onTap: saving
                              ? null
                              : () => setState(() => rating = i + 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: filled
                                  ? Colors.amber
                                  : AppColors.hintText,
                              size: 38,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Review text section ───────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.border, width: 1),
                  boxShadow: AppColors.smallShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Text(
                        "Your Review",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkTextAlt,
                        ),
                      ),
                    ),
                    TextField(
                      controller: reviewCtrl,
                      maxLines: 6,
                      enabled: !saving,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkText,
                        height: 1.6,
                        fontFamily: 'Georgia',
                      ),
                      decoration: InputDecoration(
                        hintText:
                            "Share your thoughts about this book…",
                        hintStyle: TextStyle(
                          color: AppColors.lightText,
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.fromLTRB(
                            16, 10, 16, 16),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Submit button ─────────────────────────────
              GestureDetector(
                onTap: saving ? null : _submit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: saving
                        ? LinearGradient(colors: [
                            AppColors.hintText,
                            AppColors.hintText
                          ])
                        : AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: saving ? [] : AppColors.glowShadow,
                  ),
                  child: saving
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_outline_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Submit Review",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
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