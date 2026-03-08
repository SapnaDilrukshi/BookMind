import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../config/color.dart';
import 'favorites_screen.dart';
import 'reviews_screen.dart';

class MyLibraryPage1 extends StatefulWidget {
  const MyLibraryPage1({super.key});

  @override
  State<MyLibraryPage1> createState() => _MyLibraryPage1State();
}

class _MyLibraryPage1State extends State<MyLibraryPage1> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _insightsMe;
  List<String> _favorites = [];
  List<dynamic> _libraryAll = [];
  String _activeTab = "reading";
  String _librarySearch = "";

  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _loadAll();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await ApiService.getMyProfile();
      final insights = await ApiService.getInsightsMe();
      final favs = await ApiService.fetchFavorites();
      final library = await ApiService.fetchLibrary(limit: 500);

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _insightsMe = insights;
        _favorites = favs;
        _libraryAll = library;
        _usernameCtrl.text = (profile["username"] ?? "").toString();
        _bioCtrl.text = (profile["bio"] ?? "").toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      _toast("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  int _safeInt(dynamic v) {
    try {
      if (v is int) return v;
      return int.parse(v.toString());
    } catch (_) {
      return 0;
    }
  }

  List<dynamic> get _libraryByTab {
    var items = _libraryAll.where((it) {
      return (it["status"] ?? "").toString() == _activeTab;
    }).toList();

    final q = _librarySearch.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((it) {
        final t = (it["book_title"] ?? "").toString().toLowerCase();
        return t.contains(q);
      }).toList();
    }
    return items;
  }

  Future<void> _addToLibraryDialog() async {
    final titleCtrl = TextEditingController();
    int progress = 0;
    String status = _activeTab;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Add Book to Library",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: "Book title *",
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        labelText: "Status",
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: "to_read", child: Text("📚 To Read")),
                        DropdownMenuItem(value: "reading", child: Text("📖 Currently Reading")),
                        DropdownMenuItem(value: "finished", child: Text("✅ Finished")),
                        DropdownMenuItem(value: "later", child: Text("⏰ Read Later")),
                      ],
                      onChanged: (v) => setLocal(() => status = v ?? "to_read"),
                    ),
                    if (status == "reading") ...[
                      const SizedBox(height: 14),
                      Text("Progress: $progress%", style: const TextStyle(fontWeight: FontWeight.w600)),
                      Slider(
                        value: progress.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: (v) => setLocal(() => progress = v.round()),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            onPressed: () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                _toast("Title is required");
                                return;
                              }
                              try {
                                await ApiService.addToLibrary({
                                  "book_title": title,
                                  "status": status,
                                  "progress": status == "reading" ? progress : 0,
                                });
                                if (mounted) Navigator.pop(ctx);
                                _toast("Added ✅");
                                await _loadAll();
                              } catch (e) {
                                _toast("Error: $e");
                              }
                            },
                            child: const Text("Add", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    titleCtrl.dispose();
  }

  Future<void> _deleteLibraryItem(String itemId) async {
    try {
      await ApiService.deleteLibraryItem(itemId);
      _toast("Deleted ✅");
      await _loadAll();
    } catch (e) {
      _toast("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = (_profile?["username"] ?? "User").toString();
    final stats = _insightsMe?["stats"] as Map<String, dynamic>? ?? {};
    final views = _safeInt(stats["total_book_views"]);
    final favCount = _favorites.length;
    final reviews = _safeInt(stats["reviews_count"]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "📚 My Library",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addToLibraryDialog,
        label: const Text("Add Book"),
        icon: const Icon(Icons.library_add),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 80, color: AppColors.error.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text("Error loading library", style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.mediumText)),
                        const SizedBox(height: 24),
                        ElevatedButton(onPressed: _loadAll, child: const Text("Retry")),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadAll,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      children: [
                        // Profile header
                        _buildProfileCard(username, views, favCount, reviews),
                        const SizedBox(height: 20),
                        
                        // Stats cards with graphs
                        _buildLibraryStats(),
                        const SizedBox(height: 20),
                        
                        // Reading tracker
                        _buildReadingTracker(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileCard(String username, int views, int favCount, int reviews) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  username.isEmpty ? "?" : username[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkTextAlt),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Reader & Book Collector",
                      style: TextStyle(fontSize: 13, color: AppColors.mediumText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard("👁 Views", views),
              const SizedBox(width: 10),
              _statCard("❤️ Favorites", favCount),
              const SizedBox(width: 10),
              _statCard("⭐ Reviews", reviews),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              "$value",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mediumText)),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryStats() {
    final toRead = _libraryAll.where((x) => x["status"] == "to_read").length;
    final reading = _libraryAll.where((x) => x["status"] == "reading").length;
    final finished = _libraryAll.where((x) => x["status"] == "finished").length;
    final later = _libraryAll.where((x) => x["status"] == "later").length;
    final total = _libraryAll.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                "Library Overview",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkTextAlt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Simple bar chart representation
          _buildBar("📚 To Read", toRead, total),
          const SizedBox(height: 12),
          _buildBar("📖 Reading", reading, total),
          const SizedBox(height: 12),
          _buildBar("✅ Finished", finished, total),
          const SizedBox(height: 12),
          _buildBar("⏰ Later", later, total),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Books",
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkText),
                ),
                Text(
                  "$total",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, int count, int total) {
    final percentage = total == 0 ? 0.0 : (count / total) * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text("$count", style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 50 ? AppColors.primary : AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadingTracker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                "Reading Progress",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkTextAlt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tab bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _tabButton("To Read", "to_read"),
                const SizedBox(width: 8),
                _tabButton("Reading", "reading"),
                const SizedBox(width: 8),
                _tabButton("Finished", "finished"),
                const SizedBox(width: 8),
                _tabButton("Later", "later"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Search
          TextField(
            onChanged: (v) => setState(() => _librarySearch = v),
            decoration: InputDecoration(
              hintText: "Search books...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Books list
          _libraryByTab.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.library_add_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          "No books here yet",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Add a book to get started!",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: _libraryByTab.take(10).map((book) {
                    final id = (book["id"] ?? "").toString();
                    final title = (book["book_title"] ?? "").toString();
                    final status = (book["status"] ?? "").toString();
                    final progress = _safeInt(book["progress"]);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildBookTile(id, title, status, progress),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, String value) {
    final active = _activeTab == value;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.mediumText,
          ),
        ),
      ),
    );
  }

  Widget _buildBookTile(String id, String title, String status, int progress) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteLibraryItem(id),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: "Delete",
              ),
            ],
          ),
          if (status == "reading") ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text("$progress%", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case "to_read":
        return "📚 To Read";
      case "reading":
        return "📖 Reading";
      case "finished":
        return "✅ Finished";
      case "later":
        return "⏰ Later";
      default:
        return status;
    }
  }
}
