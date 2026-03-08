import 'package:flutter/material.dart';
import '../config/color.dart';
import '../models/book_model.dart';

class WebDashboard extends StatefulWidget {
  const WebDashboard({super.key});

  @override
  State<WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends State<WebDashboard> {
  int selectedTab = 0;
  final List<String> moods = [
    "Happy",
    "Adventurous",
    "Mysterious",
    "Romantic",
    "Dark",
    "Inspirational"
  ];
  final List<String> genres = [
    "Fantasy",
    "Sci-Fi",
    "Mystery",
    "Romance",
    "Non-Fiction",
    "Biography"
  ];

  List<String> selectedMoods = [];
  List<String> selectedGenres = [];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // SIDEBAR NAVIGATION
          Container(
            width: 280,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "BookMind",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkTextAlt,
                          ),
                        ),
                        Text(
                          "AI Book Finder",
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.mediumText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Navigation Items
                _navItem(
                  icon: Icons.home_outlined,
                  label: "Home",
                  index: 0,
                ),
                _navItem(
                  icon: Icons.search_outlined,
                  label: "Discover",
                  index: 1,
                ),
                _navItem(
                  icon: Icons.auto_awesome_outlined,
                  label: "AI Search",
                  index: 2,
                ),
                _navItem(
                  icon: Icons.favorite_outline,
                  label: "Favorites",
                  index: 3,
                ),
                _navItem(
                  icon: Icons.trending_up_outlined,
                  label: "Stats",
                  index: 4,
                ),

                const Spacer(),

                // User Profile Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            "U",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "User Name",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkText,
                              ),
                            ),
                            Text(
                              "user@email.com",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.mediumText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // MAIN CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // TOP BAR
                Container(
                  height: 70,
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedTab == 0
                            ? "Discover Books"
                            : selectedTab == 1
                                ? "Advanced Search"
                                : selectedTab == 2
                                    ? "AI Recommendations"
                                    : selectedTab == 3
                                        ? "My Favorites"
                                        : "Reading Stats",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkTextAlt,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_outlined),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // QUICK FILTERS ROW
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "What's Your Mood Today?",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: moods
                                    .map((mood) => FilterChip(
                                          label: Text(mood),
                                          selected: selectedMoods.contains(mood),
                                          onSelected: (v) {
                                            setState(() {
                                              if (v) {
                                                selectedMoods.add(mood);
                                              } else {
                                                selectedMoods.remove(mood);
                                              }
                                            });
                                          },
                                          backgroundColor: AppColors.surface,
                                          selectedColor: AppColors.primary,
                                          labelStyle: TextStyle(
                                            color: selectedMoods.contains(mood)
                                                ? Colors.white
                                                : AppColors.darkText,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // GENRE FILTERS
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Pick Your Genre",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: genres
                                    .map((genre) => FilterChip(
                                          label: Text(genre),
                                          selected: selectedGenres.contains(genre),
                                          onSelected: (v) {
                                            setState(() {
                                              if (v) {
                                                selectedGenres.add(genre);
                                              } else {
                                                selectedGenres.remove(genre);
                                              }
                                            });
                                          },
                                          backgroundColor: AppColors.surface,
                                          selectedColor: AppColors.secondary,
                                          labelStyle: TextStyle(
                                            color: selectedGenres.contains(genre)
                                                ? Colors.white
                                                : AppColors.darkText,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // RECOMMENDED BOOKS GRID
                        const Text(
                          "Perfect Recommendations For You",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkTextAlt,
                          ),
                        ),
                        const SizedBox(height: 20),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: 8,
                          itemBuilder: (context, index) {
                            return _bookCard();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => selectedTab = index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.mediumText,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.mediumText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.smallShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Book Cover
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.auto_stories,
                  size: 60,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ),

          // Book Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Book Title Here",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Author Name",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mediumText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                        SizedBox(width: 2),
                        Text(
                          "4.8",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.favorite_outline,
                        size: 16,
                        color: AppColors.error,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
