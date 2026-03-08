import 'package:flutter/material.dart';
import 'package:bookmind/services/api_service.dart';
import 'package:bookmind/screens/BookDetailsScreen.dart';
import '../config/color.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<String>> favorites;

  @override
  void initState() {
    super.initState();
    favorites = ApiService.fetchFavorites();
  }

  Future<void> _refresh() async {
    setState(() {
      favorites = ApiService.fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("⭐ My Favorites"),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: FutureBuilder<List<String>>(
          future: favorites,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 150),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite_outline,
                          size: 64,
                          color: AppColors.lightText,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No favorites yet",
                          style: TextStyle(
                            color: AppColors.mediumText,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final favs = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: favs.length,
              itemBuilder: (context, index) {
                final title = favs[index];

                return Card(
                  color: AppColors.surface,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.book,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      onPressed: () async {
                        await ApiService.removeFavorite(title);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Removed from favorites ❌"),
                            backgroundColor: AppColors.success,
                          ),
                        );

                        _refresh();
                      },
                    ),
                    onTap: () async {
                      final book = await ApiService.getBookDetails(title);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookDetailsScreen(title: book.title),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
