import 'package:bookmind/screens/BookDetailsScreen.dart';
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import '../config/color.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool loading = false;

  // ✅ IMPORTANT: keep original results from API
  List<BookModel> allResults = [];

  // ✅ filtered list shown in UI
  List<BookModel> filteredResults = [];

  String selectedEmotion = "All";
  String selectedInterest = "All";
  String selectedSort = "Relevance";

  final emotions = [
    "All",
    "Happy",
    "Inspirational",
    "Dark",
    "Romantic",
    "Adventurous",
    "mysterious",
    "scary",
    "philosophical",
  ];

  final interests = [
    "All",
    "fantasy",
    "historical",
    "biography",
    "self-help",
    "psychology",
    "business",
    "finance",
    "technology",
    "programming",
    "data-science",
    "art",
    "design",
    "poetry",
    "education",
    "travel",
    "health",
    "fitness",
    "mythology",
    "politics",
    "law",
    "environment",
    "spirituality",
    "children",
    "young-adult",
    "parenting",
    "sports",
    "cook"
  ];

  final sortOptions = [
    "Relevance",
    "Newest",
    "Oldest",
  ];

  // 🔍 SEARCH
  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => loading = true);

    try {
      final data = await ApiService.getRecommendations(query);

      // ✅ store original data
      allResults = data;

      // ✅ apply filters now
      _applyFilters();
    } catch (e) {
      debugPrint("Discover error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ✅ FILTER LOGIC (THIS FIXES YOUR ISSUE)
  void _applyFilters() {
    List<BookModel> list = List<BookModel>.from(allResults);

    // ---- Emotion filter ----
    if (selectedEmotion != "All") {
      final emo = selectedEmotion.toLowerCase().trim();
      list = list.where((b) {
        final raw = (b.emotion ?? "").toLowerCase();
        return raw.split(",").map((e) => e.trim()).contains(emo);
      }).toList();
    }

    // ---- Interest filter ----
    if (selectedInterest != "All") {
      final intr = selectedInterest.toLowerCase().trim();
      list = list.where((b) {
        final tags = b.interestTags.map((t) => t.toLowerCase().trim()).toList();
        return tags.contains(intr);
      }).toList();
    }

    // ---- Sorting ----
    if (selectedSort == "Newest") {
      list.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
    } else if (selectedSort == "Oldest") {
      list.sort((a, b) => (a.year ?? 0).compareTo(b.year ?? 0));
    }
    // Relevance = keep as-is

    setState(() => filteredResults = list);
  }

  void _resetFilters() {
    setState(() {
      selectedEmotion = "All";
      selectedInterest = "All";
      selectedSort = "Relevance";
      allResults.clear();
      filteredResults.clear();
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("🔍 Discover Books"),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: "Search books or authors",
                hintStyle: const TextStyle(color: AppColors.lightText),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
                  onPressed: _search,
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),

          // 🎛 FILTER BAR
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _filterChip(
                  label: "Emotion",
                  value: selectedEmotion,
                  items: emotions,
                  onChanged: (v) {
                    setState(() => selectedEmotion = v);
                    _applyFilters();
                  },
                ),
                _filterChip(
                  label: "Interest",
                  value: selectedInterest,
                  items: interests,
                  onChanged: (v) {
                    setState(() => selectedInterest = v);
                    _applyFilters();
                  },
                ),
                _filterChip(
                  label: "Sort",
                  value: selectedSort,
                  items: sortOptions,
                  onChanged: (v) {
                    setState(() => selectedSort = v);
                    _applyFilters();
                  },
                ),
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reset"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 📚 RESULTS GRID
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filteredResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppColors.lightText,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Search and filter books 📚",
                              style: TextStyle(
                                color: AppColors.mediumText,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: filteredResults.length,
                        itemBuilder: (_, i) {
                          final book = filteredResults[i];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookDetailsScreen(title: book.title),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 1,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ✅ fixed height image (no huge image)
                                  SizedBox(
                                    height: 150,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                      child: Image.network(
                                        book.image ?? "",
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.book, size: 40),
                                            ),
                                      ),
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      book.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // 🎛 FILTER CHIP WITH LABEL
  Widget _filterChip({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mediumText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: const Border(
                bottom: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                items: items.map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (v) => onChanged(v!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
