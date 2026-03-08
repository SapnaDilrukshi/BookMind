import 'package:flutter/material.dart';
import '../config/color.dart';
import '../widgets/web_book_card.dart';

class WebDiscoverPage extends StatefulWidget {
  const WebDiscoverPage({super.key});

  @override
  State<WebDiscoverPage> createState() => _WebDiscoverPageState();
}

class _WebDiscoverPageState extends State<WebDiscoverPage> {
  String selectedMood = "All";
  String selectedGenre = "All";
  bool showFilters = true;

  final List<String> moods = [
    "All",
    "Happy",
    "Sad",
    "Adventurous",
    "Inspirational",
    "Dark",
    "Romantic",
    "Mysterious"
  ];

  final List<String> genres = [
    "All",
    "Fiction",
    "Mystery",
    "Fantasy",
    "Romance",
    "Sci-Fi",
    "Thriller",
    "Historical",
    "Non-Fiction"
  ];

  final List<Map<String, String>> books = [
    {
      "title": "The Lost Kingdom",
      "author": "Jane Author",
      "mood": "Adventurous",
      "genre": "Fantasy"
    },
    {
      "title": "Silent Echoes",
      "author": "John Writer",
      "mood": "Dark",
      "genre": "Mystery"
    },
    {
      "title": "Love Unbound",
      "author": "Sarah Novelist",
      "mood": "Romantic",
      "genre": "Romance"
    },
    {
      "title": "Rise of Tomorrow",
      "author": "Alex Creator",
      "mood": "Inspirational",
      "genre": "Fiction"
    },
    {
      "title": "Quantum Dreams",
      "author": "Emma Tales",
      "mood": "Adventurous",
      "genre": "Sci-Fi"
    },
    {
      "title": "The Last Detective",
      "author": "Michael Pen",
      "mood": "Dark",
      "genre": "Thriller"
    },
    {
      "title": "Forever Yours",
      "author": "Lisa Poetry",
      "mood": "Romantic",
      "genre": "Romance"
    },
    {
      "title": "Hearts Aligned",
      "author": "David Story",
      "mood": "Happy",
      "genre": "Fiction"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // Filter books
    final filteredBooks = books.where((book) {
      final moodMatch =
          selectedMood == "All" || book["mood"] == selectedMood;
      final genreMatch =
          selectedGenre == "All" || book["genre"] == selectedGenre;
      return moodMatch && genreMatch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 2,
        title: const Text(
          "Discover Books",
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.tune, color: AppColors.primary),
              onPressed: () => setState(() => showFilters = !showFilters),
            ),
        ],
      ),
      body: isMobile ? _buildMobileLayout(filteredBooks) : _buildDesktopLayout(context, filteredBooks),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, List<Map<String, String>> filteredBooks) {
    return Row(
      children: [
        // SIDEBAR
        Container(
          width: 280,
          color: AppColors.surface,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Filters",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkTextAlt,
                  ),
                ),
                const SizedBox(height: 24),

                // Mood Filter
                _filterSection("Mood", moods, selectedMood, (value) {
                  setState(() => selectedMood = value);
                }),

                const SizedBox(height: 24),

                // Genre Filter
                _filterSection("Genre", genres, selectedGenre, (value) {
                  setState(() => selectedGenre = value);
                }),

                const SizedBox(height: 24),

                // Reset Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedMood = "All";
                        selectedGenre = "All";
                      });
                    },
                    child: const Text("Reset Filters"),
                  ),
                ),
              ],
            ),
          ),
        ),

        // MAIN CONTENT
        Expanded(
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SEARCH BAR
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search books, authors...",
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.mediumText),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),

                // Results Count
                Text(
                  "${filteredBooks.length} books found",
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.mediumText,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                // Books Grid
                if (filteredBooks.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.mediumText.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No books found",
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.mediumText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) {
                        final book = filteredBooks[index];
                        // return WebBookCard(
                        //   title: book["title"] ?? "",
                        //   author: book["author"] ?? "",
                        //   mood: book["mood"] ?? "",
                        //   genre: book["genre"] ?? "",
                        // );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<Map<String, String>> filteredBooks) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (showFilters)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _filterSection("Mood", moods, selectedMood, (value) {
                    setState(() => selectedMood = value);
                  }),
                  const SizedBox(height: 16),
                  _filterSection("Genre", genres, selectedGenre, (value) {
                    setState(() => selectedGenre = value);
                  }),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${filteredBooks.length} books found",
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.mediumText,
                  ),
                ),
                const SizedBox(height: 16),
                if (filteredBooks.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: AppColors.mediumText.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        const Text("No books found"),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      // return WebBookCard(
                      //   title: book["title"] ?? "",
                      //   author: book["author"] ?? "",
                      //   mood: book["mood"] ?? "",
                      //   genre: book["genre"] ?? "",
                      // );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterSection(
    String title,
    List<String> options,
    String selected,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTextAlt,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((option) {
            final isSelected = selected == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) => onChanged(option),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primaryLight,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.mediumText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
