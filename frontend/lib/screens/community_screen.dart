import 'package:flutter/material.dart';
import '../models/community_post_model.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../config/color.dart';
import 'community_post_details_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool loading = true;
  List<CommunityPostModel> posts = [];

  final TextEditingController postTextCtrl = TextEditingController();
  final TextEditingController bookTitleCtrl = TextEditingController();
  int rating = 0;

  final List<String> selectedEmotions = [];
  final List<String> selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    postTextCtrl.dispose();
    bookTitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.fetchCommunityPosts(limit: 30);
      if (!mounted) return;
      setState(() => posts = data);
    } catch (e) {
      debugPrint("Community load error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _createPost() async {
    final isLoggedIn = await UserSession.isLoggedIn();
    if (!isLoggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please login to create a post"),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      return;
    }

    final text = postTextCtrl.text.trim();
    final bookTitle = bookTitleCtrl.text.trim();
    if (text.isEmpty || bookTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill in book title and your thoughts"),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      final created = await ApiService.createCommunityPost(
        text: text,
        bookTitle: bookTitle,
        rating: rating,
        emotionTags: selectedEmotions,
        interestTags: selectedInterests,
      );

      postTextCtrl.clear();
      bookTitleCtrl.clear();
      setState(() {
        rating = 0;
        posts = [created, ...posts];
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Posted successfully ✅"),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      debugPrint("Create post error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleLike(int index) async {
    try {
      final updated = await ApiService.toggleLike(posts[index].id);
      if (!mounted) return;
      setState(() => posts[index] = updated);
    } catch (e) {
      debugPrint("Like error: $e");
    }
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit_outlined,
                        color: AppColors.primary, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Share Your Thoughts",
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkTextAlt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _sheetField(
                controller: bookTitleCtrl,
                hint: "Book title (e.g. Atomic Habits)",
                icon: Icons.menu_book_rounded,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: postTextCtrl,
                maxLines: 4,
                style: TextStyle(fontSize: 13.5, color: AppColors.darkText),
                decoration: InputDecoration(
                  hintText: "Share your thoughts about this book…",
                  hintStyle: TextStyle(
                      color: AppColors.lightText,
                      fontSize: 13,
                      fontStyle: FontStyle.italic),
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppColors.accent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    "Rating:",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ...List.generate(5, (i) {
                    final filled = (i + 1) <= rating;
                    return GestureDetector(
                      onTap: () =>
                          setSheet(() => rating = (rating == i + 1) ? 0 : i + 1),
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: filled ? Colors.amber : AppColors.hintText,
                        size: 26,
                      ),
                    );
                  }),
                  const Spacer(),
                  if (rating > 0)
                    Text(
                      _ratingLabel(rating),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _createPost();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.glowShadow,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        "Post",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
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

  Widget _sheetField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 13.5, color: AppColors.darkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.lightText, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceWarm,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }

  String _ratingLabel(int r) {
    const labels = ["", "Poor", "Fair", "Good", "Great", "Excellent"];
    return labels[r.clamp(0, 5)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverHeader()],
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadPosts,
          child: loading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : posts.isEmpty
                  ? _buildEmptyState()
                  : _buildGrid(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_outlined, color: Colors.white),
        label: const Text(
          "New Post",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        elevation: 3,
      ),
    );
  }

  // ── Sliver Header ─────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                              "COMMUNITY",
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
                        Text(
                          "Reader Discussions",
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
                  if (!loading && posts.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(30),
                        border:
                            Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Text(
                        "${posts.length} posts",
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

  // ── 3-column Grid ─────────────────────────────────────────────
  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.75,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) => _PostCard(
        post: posts[i],
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityPostDetailsScreen(post: posts[i]),
            ),
          );
          await _loadPosts();
        },
        onLike: () => _toggleLike(i),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.forum_outlined,
                    color: AppColors.primary, size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                "No posts yet",
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextAlt,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Be the first to share your thoughts!",
                style: TextStyle(
                    color: AppColors.mediumText, fontSize: 13.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Post Card (vertical, compact for 3-column grid) ─────────────────────────

class _PostCard extends StatelessWidget {
  final CommunityPostModel post;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _PostCard({
    required this.post,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppColors.smallShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar + username ─────────────────────────
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.border, width: 1.2),
                    ),
                    child: Center(
                      child: Text(
                        post.username.isNotEmpty
                            ? post.username[0].toUpperCase()
                            : "U",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      post.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppColors.darkTextAlt,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Book title ────────────────────────────────
              Row(
                children: [
                  Icon(Icons.menu_book_rounded,
                      size: 10, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      post.bookTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              // ── Rating stars ──────────────────────────────
              if (post.rating > 0)
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < post.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: i < post.rating
                          ? Colors.amber
                          : AppColors.borderLight,
                      size: 11,
                    ),
                  ),
                ),

              if (post.rating > 0) const SizedBox(height: 7),

              // ── Post text ─────────────────────────────────
              Expanded(
                child: Text(
                  post.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    height: 1.45,
                    color: AppColors.darkText,
                    fontSize: 11,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Divider(
                  color: AppColors.borderLight, height: 1, thickness: 1),

              const SizedBox(height: 7),

              // ── Footer: likes + comments + time ──────────
              Row(
                children: [
                  GestureDetector(
                    onTap: onLike,
                    child: Row(
                      children: [
                        Icon(
                          post.likedByMe
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: post.likedByMe
                              ? Colors.red[400]
                              : AppColors.hintText,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "${post.likesCount}",
                          style: TextStyle(
                            color: post.likedByMe
                                ? Colors.red[400]
                                : AppColors.hintText,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: AppColors.hintText, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        "${post.commentsCount}",
                        style: TextStyle(
                          color: AppColors.hintText,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _timeAgo(post.createdAt),
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.hintText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";
    return "${dt.day}/${dt.month}";
  }
}