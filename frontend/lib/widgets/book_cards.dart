import 'package:flutter/material.dart';
import '../config/color.dart';
import '../models/book_model.dart';

/// Reusable compact horizontal book card.
/// Fixed height 148 px · cover LEFT · details RIGHT · heart always TOP-RIGHT.
class BookCards extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;

  /// Optional star rating override (0–5).
  final double? rating;

  /// Whether this book is already in favourites.
  final bool isFavorite;

  /// Called when the heart icon is tapped. Pass null to hide the icon.
  final VoidCallback? onFavoriteToggle;

  const BookCards({
    super.key,
    required this.book,
    required this.onTap,
    this.rating,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  double get _displayRating {
    if (rating != null) return rating!.clamp(0.0, 5.0);
    if (book.sentimentScore != null) {
      return (book.sentimentScore! * 4 + 1).clamp(1.0, 5.0);
    }
    return 0.0;
  }

  String? get _emotionLabel {
    if (book.emotion != null && book.emotion!.isNotEmpty) {
      return book.emotion!.split(',').first.trim();
    }
    if (book.sentimentLabel != null && book.sentimentLabel!.isNotEmpty) {
      return book.sentimentLabel;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 148,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppColors.smallShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cover ──────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
              child: SizedBox(
                width: 88,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    (book.image != null && book.image!.isNotEmpty)
                        ? Image.network(
                            book.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return _coverLoading();
                            },
                          )
                        : _placeholder(),

                    // Year badge — bottom-left of cover
                    if (book.year != null)
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          color: Colors.black.withOpacity(0.48),
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            '${book.year}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white, fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Details ────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── ROW 1: genre pill + heart (always top-right) ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Genre pill (shrinks if long)
                        if (book.genres.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                book.genres.first,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                        // Pushes heart to the right regardless of pill presence
                        const Spacer(),

                        // Heart icon — anchored top-right, always visible
                        if (onFavoriteToggle != null)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onFavoriteToggle,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFavorite
                                    ? Colors.red[400]
                                    : AppColors.hintText,
                                size: 19,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // ── ROW 2: Title ──────────────────────────────
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextAlt,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 3),

                    // ── ROW 3: Author ─────────────────────────────
                    if (book.author != null)
                      Text(
                        book.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.mediumText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                    const Spacer(),

                    // ── ROW 4: Stars + numeric + emotion ──────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_displayRating > 0) ...[
                          // Star icons
                          ...List.generate(5, (i) {
                            final filled = i < _displayRating.floor();
                            final half = !filled && (_displayRating - i) >= 0.5;
                            return Icon(
                              filled
                                  ? Icons.star_rounded
                                  : half
                                      ? Icons.star_half_rounded
                                      : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 14,
                            );
                          }),
                          const SizedBox(width: 4),
                          // Numeric rating
                          Text(
                            _displayRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Emotion / sentiment badge
                        if (_emotionLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.accent.withOpacity(0.28),
                                  width: 1),
                            ),
                            child: Text(
                              _emotionLabel!,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primaryDark,
      child: Center(
        child: Icon(Icons.menu_book_rounded, color: AppColors.accent, size: 28),
      ),
    );
  }

  Widget _coverLoading() {
    return Container(
      color: AppColors.primaryLight,
      child: Center(
        child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 1.5),
      ),
    );
  }
}