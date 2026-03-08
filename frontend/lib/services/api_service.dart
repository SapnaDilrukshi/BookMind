import 'dart:convert';
import 'package:bookmind/models/community_comment_model.dart';
import 'package:bookmind/models/community_post_model.dart';
import 'package:bookmind/models/review_model.dart';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';
import 'user_session.dart';

class ApiService {
  static const String baseUrl = "http://localhost:5000";
  static const String _adminToken = "bookmind-admin-secret";

  // -------------------------
  // HELPERS
  // -------------------------
  static Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final userId = await UserSession.getUserId();
    return {
      if (json) "Content-Type": "application/json",
      if (userId != null && userId.trim().isNotEmpty) "X-USER-ID": userId.trim(),
    };
  }

  static Exception _apiError(http.Response res, {String fallback = "Request failed"}) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded["error"] != null) {
        return Exception(decoded["error"].toString());
      }
    } catch (_) {}
    return Exception("$fallback: ${res.statusCode} ${res.body}");
  }

  static Map<String, String> _adminHeaders({bool json = true}) {
    return {
      if (json) "Content-Type": "application/json",
      "X-ADMIN-TOKEN": _adminToken,
    };
  }

  // -------------------------
  // REGISTER
  // -------------------------
  static Future<void> register(
    String username,
    String email,
    String password,
    List<String> interests,
    List<String> preferredEmotions,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "interests": interests,
        "preferred_emotions": preferredEmotions,
      }),
    );

    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body["error"] ?? "Register failed");
    }

    await login(email, password);
  }

  // -------------------------
  // LOGIN
  // -------------------------
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data["error"]);

    final user = data["user"];
    await UserSession.saveUser(
      userId: user["id"],
      email: user["email"],
      username: user["username"],
      interests: List<String>.from(user["interests"]),
      emotions: List<String>.from(user["preferred_emotions"]),
      isFirstLogin: false,
    );

    return user;
  }

  // -------------------------
  // LOGOUT
  // -------------------------
  static Future<void> logout() async {
    await UserSession.logout();
  }

  // -------------------------
  // BOOK DETAILS
  // -------------------------
  static Future<BookModel> getBookDetails(String title) async {
    final res = await http.get(Uri.parse("$baseUrl/book?title=$title"));
    if (res.statusCode == 200) return BookModel.fromJson(jsonDecode(res.body));
    throw Exception("Book not found");
  }

  // -------------------------
  // FAVORITES
  // -------------------------
  static Future<void> addFavorite(String title) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse("$baseUrl/favorites"),
      headers: headers,
      body: jsonEncode({"book_title": title}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Failed to add favorite");
    }
  }

  static Future<void> removeFavorite(String title) async {
    final headers = await _authHeaders(json: false);
    final uri = Uri.parse("$baseUrl/favorites").replace(queryParameters: {"book_title": title});
    final res = await http.delete(uri, headers: headers);
    if (res.statusCode != 200) throw Exception("Failed to remove favorite");
  }

  static Future<List<String>> fetchFavorites() async {
    final headers = await _authHeaders(json: false);
    final res = await http.get(Uri.parse("$baseUrl/favorites"), headers: headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<String>.from(data is List ? data : []);
    }
    throw Exception("Failed to load favorites");
  }

  // -------------------------
  // RECOMMENDATIONS
  // -------------------------
  static Future<List<BookModel>> getRecommendations(String title) async {
    final res = await http.get(Uri.parse("$baseUrl/recommend?title=$title"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List list = data["recommendations"];
      return list.map((e) => BookModel.fromJson(e)).toList();
    }
    throw Exception("Failed to fetch recommendations");
  }

  static Future<List<BookModel>> getInterestRecommendations(List<String> interests) async {
    final res = await http.post(
      Uri.parse("$baseUrl/recommend/interest"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"interests": interests}),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => BookModel.fromJson(e)).toList();
    }
    throw Exception("Interest recommendations failed");
  }

  static Future<List<BookModel>> getEmotionRecommendations(List<String> emotions) async {
    final res = await http.post(
      Uri.parse("$baseUrl/recommend/emotion"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"emotions": emotions}),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => BookModel.fromJson(e)).toList();
    }
    throw Exception("Emotion recommendations failed");
  }

  static Future<List<BookModel>> getHybridRecommendations(
    List<String> interests,
    List<String> emotions,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/recommend/hybrid"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"interests": interests, "emotions": emotions}),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => BookModel.fromJson(e)).toList();
    }
    throw Exception("Hybrid recommendations failed");
  }

  static Future<List<BookModel>> getTextRecommendations(String text) async {
    final res = await http.post(
      Uri.parse("$baseUrl/recommend/text"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List list = data["recommendations"] ?? [];
      return list.map((e) => BookModel.fromJson(e)).toList();
    }
    final body = jsonDecode(res.body);
    throw Exception(body["error"] ?? "Text recommendation failed");
  }

  // -------------------------
  // REVIEWS
  // -------------------------
  static Future<void> saveReview({
    required String userId,
    required String username,
    required String bookTitle,
    required int rating,
    required String reviewText,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/reviews"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "username": username,
        "book_title": bookTitle,
        "rating": rating,
        "review_text": reviewText,
      }),
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data["error"] ?? "Failed to save review");
    }
  }

  static Future<Map<String, dynamic>> getReviewsForBook(String title) async {
    final res = await http.get(Uri.parse("$baseUrl/reviews/book?title=${Uri.encodeComponent(title)}"));
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data["error"] ?? "Failed to load reviews");
    }
    return jsonDecode(res.body);
  }

  static Future<List<ReviewModel>> getMyReviews(String userId) async {
    final res = await http.get(Uri.parse("$baseUrl/reviews/user?user_id=${Uri.encodeComponent(userId)}"));
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data["error"] ?? "Failed to load my reviews");
    }
    final List list = jsonDecode(res.body);
    return list.map((e) => ReviewModel.fromJson(e)).toList();
  }

  static Future<void> deleteReview({required String userId, required String bookTitle}) async {
    final res = await http.delete(Uri.parse(
      "$baseUrl/reviews?user_id=${Uri.encodeComponent(userId)}&book_title=${Uri.encodeComponent(bookTitle)}",
    ));
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data["error"] ?? "Failed to delete review");
    }
  }

  // -------------------------
  // COMMUNITY
  // -------------------------
  static Future<List<CommunityPostModel>> fetchCommunityPosts({int limit = 20}) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse("$baseUrl/community/posts?limit=$limit"), headers: headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => CommunityPostModel.fromJson(e)).toList();
    }
    throw Exception("Failed to fetch posts: ${res.body}");
  }

  static Future<CommunityPostModel> createCommunityPost({
    required String text,
    required String bookTitle,
    int rating = 0,
    List<String> emotionTags = const [],
    List<String> interestTags = const [],
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse("$baseUrl/community/posts"),
      headers: headers,
      body: jsonEncode({
        "text": text,
        "book_title": bookTitle,
        "rating": rating,
        "emotion_tags": emotionTags,
        "interest_tags": interestTags,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return CommunityPostModel.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to create post: ${res.body}");
  }

  static Future<CommunityPostModel> toggleLike(String postId) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse("$baseUrl/community/posts/$postId/like"), headers: headers);
    if (res.statusCode == 200) return CommunityPostModel.fromJson(jsonDecode(res.body));
    throw Exception("Failed to like: ${res.body}");
  }

  static Future<List<CommunityCommentModel>> fetchComments(String postId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse("$baseUrl/community/posts/$postId/comments"), headers: headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => CommunityCommentModel.fromJson(e)).toList();
    }
    throw Exception("Failed to fetch comments: ${res.body}");
  }

  static Future<CommunityCommentModel> addComment({required String postId, required String text}) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse("$baseUrl/community/posts/$postId/comments"),
      headers: headers,
      body: jsonEncode({"text": text}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return CommunityCommentModel.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to add comment: ${res.body}");
  }

  static Future<List<CommunityPostModel>> fetchPostsByBook(String bookTitle) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse("$baseUrl/community/posts/by-book?book_title=${Uri.encodeComponent(bookTitle)}"),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => CommunityPostModel.fromJson(e)).toList();
    }
    throw Exception("Failed to fetch book posts: ${res.body}");
  }

  // -------------------------
  // SEARCH
  // -------------------------
  static Future<Map<String, dynamic>> searchBooks(String query, {int limit = 10}) async {
    final res = await http.get(Uri.parse("$baseUrl/search/books?q=${Uri.encodeComponent(query)}&limit=$limit"));
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception("Search failed: ${res.body}");
  }

  // -------------------------
  // INSIGHTS
  // -------------------------
  static Future<List<dynamic>> getInsightsActivity({int limit = 50}) async {
    final userId = await UserSession.getUserId();
    final uid = (userId ?? "").toString().trim();
    if (uid.isEmpty) throw Exception("Missing user id. Please login again.");

    final res = await http.get(
      Uri.parse("$baseUrl/insights/activity?limit=$limit"),
      headers: {"X-USER-ID": uid},
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return (decoded["events"] as List?) ?? [];
    }
    throw Exception("Insights activity failed: ${res.body}");
  }

  static Future<Map<String, dynamic>> getInsightsMe() async {
    final userId = await UserSession.getUserId();
    final uid = (userId ?? "").toString().trim();
    if (uid.isEmpty) throw Exception("Missing user id. Please login again.");

    final res = await http.get(
      Uri.parse("$baseUrl/insights/me"),
      headers: {"X-USER-ID": uid},
    );

    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception("Insights me failed: ${res.body}");
  }

  // -------------------------
  // PROFILE
  // -------------------------
  static Future<Map<String, dynamic>> getMyProfile() async {
    final headers = await _authHeaders(json: false);
    final res = await http.get(Uri.parse("$baseUrl/users/me"), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw _apiError(res, fallback: "Failed to load profile");
  }

  static Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final res = await http.put(Uri.parse("$baseUrl/users/me"), headers: headers, body: jsonEncode(payload));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return (decoded["user"] as Map<String, dynamic>?) ?? decoded;
    }
    throw _apiError(res, fallback: "Failed to update profile");
  }

  // -------------------------
  // NOTES
  // -------------------------
  static Future<Map<String, dynamic>> createNote(Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse("$baseUrl/notes"), headers: headers, body: jsonEncode(payload));
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw _apiError(res, fallback: "Create note failed");
  }

  static Future<List<dynamic>> fetchNotes({int limit = 50, String? q}) async {
    final headers = await _authHeaders(json: false);
    final query = <String, String>{"limit": "$limit"};
    if (q != null && q.trim().isNotEmpty) query["q"] = q.trim();
    final uri = Uri.parse("$baseUrl/notes").replace(queryParameters: query);
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return data;
      if (data is Map && data["notes"] != null) return data["notes"] as List<dynamic>;
      return data is List ? data : [];
    }
    throw _apiError(res, fallback: "Load notes failed");
  }

  static Future<Map<String, dynamic>> updateNote(String noteId, Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final res = await http.patch(Uri.parse("$baseUrl/notes/$noteId"), headers: headers, body: jsonEncode(payload));
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw _apiError(res, fallback: "Update note failed");
  }

  static Future<void> deleteNote(String noteId) async {
    final headers = await _authHeaders(json: false);
    final res = await http.delete(Uri.parse("$baseUrl/notes/$noteId"), headers: headers);
    if (res.statusCode != 200) throw _apiError(res, fallback: "Delete note failed");
  }

  // -------------------------
  // LIBRARY
  // -------------------------
  static Future<Map<String, dynamic>> addToLibrary(Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse("$baseUrl/library"), headers: headers, body: jsonEncode(payload));
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw _apiError(res, fallback: "Add to library failed");
  }

  static Future<List<dynamic>> fetchLibrary({String? status, int limit = 200}) async {
    final headers = await _authHeaders(json: false);
    final query = <String, String>{"limit": "$limit"};
    if (status != null && status.trim().isNotEmpty) query["status"] = status.trim();
    final uri = Uri.parse("$baseUrl/library").replace(queryParameters: query);
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return data;
      if (data is Map && data["items"] != null) return data["items"] as List<dynamic>;
      return data as List<dynamic>;
    }
    throw _apiError(res, fallback: "Load library failed");
  }

  static Future<Map<String, dynamic>> updateLibraryItem(String itemId, Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final res = await http.patch(Uri.parse("$baseUrl/library/$itemId"), headers: headers, body: jsonEncode(payload));
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw _apiError(res, fallback: "Update library failed");
  }

  static Future<void> deleteLibraryItem(String itemId) async {
    final headers = await _authHeaders(json: false);
    final res = await http.delete(Uri.parse("$baseUrl/library/$itemId"), headers: headers);
    if (res.statusCode != 200) throw _apiError(res, fallback: "Delete library item failed");
  }

  // ============================
  // 🔹 ADMIN — DASHBOARD
  // ============================
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final res = await http.get(Uri.parse("$baseUrl/admin/dashboard"), headers: _adminHeaders(json: false));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw _apiError(res, fallback: "Admin dashboard failed");
  }

  // ============================
  // 🔹 ADMIN — BOOK MANAGEMENT
  // ============================
  static Future<Map<String, dynamic>> getAdminBooks({int page = 1, int limit = 20, String? q}) async {
    final query = <String, String>{"page": "$page", "limit": "$limit"};
    if (q != null && q.trim().isNotEmpty) query["q"] = q.trim();
    final uri = Uri.parse("$baseUrl/admin/books").replace(queryParameters: query);
    final res = await http.get(uri, headers: _adminHeaders(json: false));
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw _apiError(res, fallback: "Load admin books failed");
  }

  static Future<Map<String, dynamic>> addAdminBook(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse("$baseUrl/admin/books"),
      headers: _adminHeaders(),
      body: jsonEncode(payload),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw _apiError(res, fallback: "Add book failed");
  }

  static Future<Map<String, dynamic>> updateAdminBook(String bookId, Map<String, dynamic> payload) async {
    final res = await http.put(
      Uri.parse("$baseUrl/admin/books/$bookId"),
      headers: _adminHeaders(),
      body: jsonEncode(payload),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw _apiError(res, fallback: "Update book failed");
  }

  static Future<void> deleteAdminBook(String bookId) async {
    final res = await http.delete(Uri.parse("$baseUrl/admin/books/$bookId"), headers: _adminHeaders(json: false));
    if (res.statusCode != 200) throw _apiError(res, fallback: "Delete book failed");
  }

  // ============================
  // 🔹 ADMIN — USER MONITORING
  // ============================
  static Future<List<dynamic>> getAdminUsers({int limit = 50}) async {
    final uri = Uri.parse("$baseUrl/admin/users").replace(queryParameters: {"limit": "$limit"});
    final res = await http.get(uri, headers: _adminHeaders(json: false));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw _apiError(res, fallback: "Load users failed");
  }

  static Future<void> deleteAdminUser(String userId) async {
    final res = await http.delete(Uri.parse("$baseUrl/admin/users/$userId"), headers: _adminHeaders(json: false));
    if (res.statusCode != 200) throw _apiError(res, fallback: "Delete user failed");
  }

  // ============================
  // 🔹 ADMIN — POSTS MANAGEMENT
  // ============================
  static Future<List<dynamic>> getAdminPosts({int limit = 50}) async {
    final uri = Uri.parse("$baseUrl/admin/posts").replace(queryParameters: {"limit": "$limit"});
    final res = await http.get(uri, headers: _adminHeaders(json: false));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw _apiError(res, fallback: "Load posts failed");
  }

  static Future<void> deleteAdminPost(String postId) async {
    final res = await http.delete(Uri.parse("$baseUrl/admin/posts/$postId"), headers: _adminHeaders(json: false));
    if (res.statusCode != 200) throw _apiError(res, fallback: "Delete post failed");
  }

  // ============================
  // 🔹 ADMIN — REVIEWS MANAGEMENT
  // ============================
  static Future<List<dynamic>> getAdminReviews({int limit = 50}) async {
    final uri = Uri.parse("$baseUrl/admin/reviews").replace(queryParameters: {"limit": "$limit"});
    final res = await http.get(uri, headers: _adminHeaders(json: false));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw _apiError(res, fallback: "Load reviews failed");
  }

  static Future<void> deleteAdminReview(String reviewId) async {
    final res = await http.delete(Uri.parse("$baseUrl/admin/reviews/$reviewId"), headers: _adminHeaders(json: false));
    if (res.statusCode != 200) throw _apiError(res, fallback: "Delete review failed");
  }

  // ============================
  // 🔹 ADMIN — ANALYTICS
  // ============================

  /// Sentiment analytics: rating distribution, emotion trends, top rated books
  static Future<Map<String, dynamic>> getAdminSentimentAnalytics() async {
    final res = await http.get(
      Uri.parse("$baseUrl/admin/analytics/sentiment"),
      headers: _adminHeaders(json: false),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw _apiError(res, fallback: "Sentiment analytics failed");
  }

  /// AI model tracking: CTR, recommendation stats, dataset coverage
  static Future<Map<String, dynamic>> getAdminAiMetrics() async {
    final res = await http.get(
      Uri.parse("$baseUrl/admin/analytics/ai-metrics"),
      headers: _adminHeaders(json: false),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw _apiError(res, fallback: "AI metrics failed");
  }

  /// Engagement analytics: daily active users, top users, event breakdown
  static Future<Map<String, dynamic>> getAdminEngagementAnalytics() async {
    final res = await http.get(
      Uri.parse("$baseUrl/admin/analytics/engagement"),
      headers: _adminHeaders(json: false),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw _apiError(res, fallback: "Engagement analytics failed");
  }
}