import 'package:flutter/material.dart';
import '../models/community_post_model.dart';
import '../models/community_comment_model.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../config/color.dart';

class CommunityPostDetailsScreen extends StatefulWidget {
  final CommunityPostModel post;

  const CommunityPostDetailsScreen({super.key, required this.post});

  @override
  State<CommunityPostDetailsScreen> createState() =>
      _CommunityPostDetailsScreenState();
}

class _CommunityPostDetailsScreenState
    extends State<CommunityPostDetailsScreen> {
  late CommunityPostModel post;
  bool loading = true;
  List<CommunityCommentModel> comments = [];

  final TextEditingController commentCtrl = TextEditingController();
  final FocusNode _commentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    post = widget.post;
    _loadComments();
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.fetchComments(post.id);
      if (!mounted) return;
      setState(() => comments = data);
    } catch (e) {
      debugPrint("Comments load error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addComment() async {
    final isLoggedIn = await UserSession.isLoggedIn();
    if (!isLoggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please login to comment"),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      return;
    }

    final text = commentCtrl.text.trim();
    if (text.isEmpty) return;

    try {
      final created =
          await ApiService.addComment(postId: post.id, text: text);
      commentCtrl.clear();
      _commentFocus.unfocus();

      if (!mounted) return;
      setState(() {
        comments = [...comments, created];
        post = CommunityPostModel(
          id: post.id,
          userId: post.userId,
          username: post.username,
          bookTitle: post.bookTitle,
          text: post.text,
          rating: post.rating,
          emotionTags: post.emotionTags,
          interestTags: post.interestTags,
          likesCount: post.likesCount,
          likedByMe: post.likedByMe,
          commentsCount: post.commentsCount + 1,
          createdAt: post.createdAt,
        );
      });
    } catch (e) {
      debugPrint("Add comment error: $e");
    }
  }

  Future<void> _toggleLike() async {
    try {
      final updated = await ApiService.toggleLike(post.id);
      if (!mounted) return;
      setState(() => post = updated);
    } catch (e) {
      debugPrint("Like error: $e");
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
          post.bookTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 16,
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
      body: Column(
        children: [
          // ── Scrollable content ──────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                // ── Post card ─────────────────────────────────
                _buildPostCard(),
                const SizedBox(height: 20),

                // ── Comments header ───────────────────────────
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
                      "COMMENTS",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${post.commentsCount}",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Comments ──────────────────────────────────
                if (loading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  )
                else if (comments.isEmpty)
                  _buildNoComments()
                else
                  ...comments.map((c) => _CommentCard(comment: c)),
              ],
            ),
          ),

          // ── Comment Input ───────────────────────────────────
          _buildCommentInput(),
        ],
      ),
    );
  }

  // ── Post Card ─────────────────────────────────────────────────
  Widget _buildPostCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppColors.smallShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Author row ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.border, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      post.username.isNotEmpty
                          ? post.username[0].toUpperCase()
                          : "U",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: AppColors.darkTextAlt,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.menu_book_rounded,
                              size: 12,
                              color: AppColors.mediumText),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              post.bookTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mediumText,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (post.rating > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              "${post.rating}/5",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(post.createdAt),
                      style: TextStyle(
                          fontSize: 10.5, color: AppColors.hintText),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(
                color: AppColors.borderLight,
                height: 1,
                thickness: 1),
            const SizedBox(height: 14),

            // ── Full post text ──────────────────────────────
            Text(
              post.text,
              style: TextStyle(
                height: 1.7,
                color: AppColors.darkText,
                fontSize: 14.5,
                fontFamily: 'Georgia',
              ),
            ),

            // ── Emotion + Interest tags ─────────────────────
            if (post.emotionTags.isNotEmpty ||
                post.interestTags.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 6,
                children: [
                  ...post.emotionTags.map((t) => _Tag(
                        label: t,
                        bg: const Color(0xFFE85D75).withOpacity(0.1),
                        color: const Color(0xFFE85D75),
                      )),
                  ...post.interestTags.map((t) => _Tag(
                        label: t,
                        bg: AppColors.primaryLight,
                        color: AppColors.primary,
                      )),
                ],
              ),
            ],

            const SizedBox(height: 14),
            Divider(
                color: AppColors.borderLight,
                height: 1,
                thickness: 1),
            const SizedBox(height: 12),

            // ── Like + comment count ────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        post.likedByMe
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: post.likedByMe
                            ? Colors.red[400]
                            : AppColors.hintText,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${post.likesCount}",
                        style: TextStyle(
                          color: post.likedByMe
                              ? Colors.red[400]
                              : AppColors.hintText,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.hintText, size: 18),
                const SizedBox(width: 6),
                Text(
                  "${post.commentsCount}",
                  style: TextStyle(
                    color: AppColors.hintText,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Comment Input ─────────────────────────────────────────────
  Widget _buildCommentInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
              top: BorderSide(color: AppColors.borderLight, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentCtrl,
                focusNode: _commentFocus,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _addComment(),
                style: TextStyle(
                    fontSize: 13.5, color: AppColors.darkText),
                decoration: InputDecoration(
                  hintText: "Add a comment…",
                  hintStyle: TextStyle(
                      color: AppColors.lightText, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  prefixIcon: Icon(Icons.comment_outlined,
                      color: AppColors.primary, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide:
                        BorderSide(color: AppColors.border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide:
                        BorderSide(color: AppColors.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide:
                        BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _addComment,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.glowShadow,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoComments() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              color: AppColors.hintText, size: 34),
          const SizedBox(height: 10),
          Text(
            "No comments yet",
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 14,
              color: AppColors.mediumText,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Be the first to comment!",
            style: TextStyle(
                fontSize: 12, color: AppColors.hintText),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}

// ─── Comment Card ─────────────────────────────────────────────

class _CommentCard extends StatelessWidget {
  final CommunityCommentModel comment;

  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: AppColors.smallShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                comment.username.isNotEmpty
                    ? comment.username[0].toUpperCase()
                    : "U",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username + time
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.darkTextAlt,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: TextStyle(
                          fontSize: 10.5, color: AppColors.hintText),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Comment text
                Text(
                  comment.text,
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}

// ─── Tag chip ─────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color color;

  const _Tag(
      {required this.label, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}