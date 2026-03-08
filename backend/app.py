from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
import re
# from model_loader import load_models
from bson import ObjectId
from bson.errors import InvalidId
# from ai_engine import AIEngine
from db import (
    favorites_collection,
    users_collection,
    reviews_collection,
    posts_collection,
    comments_collection,
    post_likes_collection,
    events_collection,
    notes_collection,
    library_collection,
    admin_books_collection
)

from community_service import (
    create_post, list_posts, delete_post,
    toggle_like,
    list_comments, add_comment, delete_comment
)

from profile_service import (
    safe_str, safe_list_str, normalize_status, clamp_progress, now_utc
)


# -----------------------
# CREATE APP
# -----------------------
app = Flask(__name__)
CORS(
    app,
    resources={r"/*": {"origins": "*"}},
    supports_credentials=False,
    allow_headers=["Content-Type", "X-USER-ID", "X-ADMIN-TOKEN"],
    expose_headers=["Content-Type"],
    methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
)

# -----------------------
# LOAD MODELS
# -----------------------
# models = load_models()

# engine = AIEngine(
#     books=models["books"],
#     pivot_table=models["pivot_table"],
#     content_sim=models["content_sim"],
#     index_map=models["index_map"],
#     book_embeddings=models["book_embeddings"],
#     embedder=models["embedder"]
# )

import pandas as pd
import os
books_df = pd.read_csv(os.path.join(os.path.dirname(__file__), "..", "data", "books_cleaned.csv"), low_memory=False)

# -----------------------
# HELPERS
# -----------------------
def clean(v):
    if v is None:
        return None
    v = str(v).strip()
    if v.lower() in ["nan", "none", ""]:
        return None
    return v

def build_ai_reasons(
    matched_genres=None,
    matched_emotions=None,
    is_hybrid=False,
    from_search=False
):
    reasons = []
    if matched_genres:
        reasons.append(f"Matches your interest in {matched_genres[0]}")
    if matched_emotions:
        reasons.append(f"Emotion aligns with your preference for {matched_emotions[0]}")
    if is_hybrid:
        reasons.append("Recommended using hybrid AI based on your interests and emotions")
    if from_search:
        reasons.append("Similar to books you searched recently")
    reasons.append("Popular choice among readers with similar taste")
    return reasons[:5]

def safe_int(v, default=None):
    try:
        return int(v)
    except Exception:
        return default

def safe_float(v, default=None):
    try:
        return float(v)
    except Exception:
        return default

def require_user():
    raw = request.headers.get("X-USER-ID", "")
    user_id = raw.strip()
    if not user_id:
        return None, (jsonify({"error": "Missing X-USER-ID"}), 401)
    try:
        oid = ObjectId(user_id)
    except (InvalidId, TypeError):
        return None, (jsonify({"error": "Invalid X-USER-ID format (must be 24 hex chars)"}), 401)
    user = users_collection.find_one({"_id": oid})
    if not user:
        return None, (jsonify({"error": "Invalid user"}), 401)
    return user, None

def track_event(user_id, event_type, book_title=None, meta=None):
    try:
        events_collection.insert_one({
            "user_id": str(user_id),
            "type": event_type,
            "book_title": book_title,
            "meta": meta or {},
            "created_at": datetime.utcnow()
        })
    except Exception as e:
        print("track_event error:", e)

def _safe_iso(dt):
    return dt.isoformat() if dt else None

def _title_to_tags(title):
    try:
        row = books_df[books_df["Book-Title"] == title]
        if row.empty:
            return [], []
        r = row.iloc[0]
        genres = [g.strip() for g in str(r.get("PredictedGenre", "")).split(",") if g.strip()]
        emotions = [e.strip() for e in str(r.get("EmotionTags", "")).split(",") if e.strip()]
        return genres, emotions
    except Exception:
        return [], []

# -----------------------
# ROOT
# -----------------------
@app.route("/")
def home():
    return "✅ BookMind AI Backend is running!"


# -----------------------
# SEARCH-BASED RECOMMEND
# -----------------------
@app.route("/recommend", methods=["GET"])
def recommend():
    title = (request.args.get("title") or "").strip()
    if not title:
        return jsonify({"error": "Book title is required"}), 400

    user_id = (request.headers.get("X-USER-ID") or "").strip()
    if user_id:
        track_event(user_id, "recommend_search", book_title=title)

    recommended_titles = engine.recommend(title, top_n=10)
    results = []

    for book_title in recommended_titles:
        row = books_df[books_df["Book-Title"] == book_title]
        if row.empty:
            continue
        r = row.iloc[0]
        genres = str(r.get("PredictedGenre", "")).split(",")
        emotions = str(r.get("EmotionTags", "")).split(",")
        reasons = build_ai_reasons(matched_genres=genres, matched_emotions=emotions, from_search=True)
        results.append({
            "title": clean(r.get("Book-Title")),
            "genres": [g.strip() for g in genres if g.strip()],
            "emotion": clean(r.get("EmotionTags")),
            "image": clean(r.get("Image-URL-L")),
            "ai_reason": reasons,
        })

    return jsonify({"input_book": title, "recommendations": results}), 200


@app.route("/recommend/text", methods=["POST"])
def recommend_by_text():
    data = request.json or {}
    user_text = str(data.get("text", "")).strip()
    if not user_text:
        return jsonify({"error": "text is required"}), 400

    user_id = (request.headers.get("X-USER-ID") or "").strip()
    if user_id:
        track_event(user_id, "recommend_text", meta={"text": user_text[:200]})

    recommended_titles = engine.recommend(user_text=user_text, top_n=12)
    results = []

    for book_title in recommended_titles:
        row = books_df[books_df["Book-Title"] == book_title]
        if row.empty:
            continue
        r = row.iloc[0]
        genres = [g.strip() for g in str(r.get("PredictedGenre", "")).split(",") if g.strip()]
        emotions = clean(r.get("EmotionTags"))
        results.append({
            "title": clean(r.get("Book-Title")),
            "genres": genres or ["General"],
            "emotion": emotions,
            "interest_tags": [t.strip() for t in str(r.get("InterestTags", "")).split(",") if t.strip()],
            "image": clean(r.get("Image-URL-L")),
            "ai_reason": [
                "Matched by meaning from your description (semantic AI)",
                "Recommended using sentence embeddings + cosine similarity",
            ],
        })

    return jsonify({"input_text": user_text, "recommendations": results}), 200


# -----------------------
# BOOK DETAILS
# -----------------------
@app.route("/book")
def get_book_details():
    title = request.args.get("title")
    if not title:
        return jsonify({"error": "Book title required"}), 400

    user_id = request.headers.get("X-USER-ID")
    if user_id:
        track_event(user_id, "view_book", book_title=title)

    row = books_df[books_df["Book-Title"] == title]
    if row.empty:
        return jsonify({"error": "Book not found"}), 404

    r = row.iloc[0]
    genres = str(r.get("PredictedGenre", "")).split(",")
    emotions = str(r.get("EmotionTags", "")).split(",")

    return jsonify({
        "title": clean(r.get("Book-Title")),
        "author": clean(r.get("Book-Author")),
        "year": int(r["Year-Of-Publication"]) if str(r.get("Year-Of-Publication")).isdigit() else None,
        "description": clean(r.get("Description")),
        "summary": clean(r.get("Summary")),
        "sentiment_score": float(r["SentimentScore"]) if str(r.get("SentimentScore")).replace('.', '', 1).isdigit() else None,
        "sentiment_label": clean(r.get("SentimentLabel")),
        "emotion": clean(r.get("EmotionTags")),
        "genres": [g.strip() for g in genres if g.strip()],
        "image": clean(r.get("Image-URL-L")),
        "ai_reason": build_ai_reasons(matched_genres=genres, matched_emotions=emotions, is_hybrid=True)
    })


# -----------------------
# SEARCH BOOKS
# -----------------------
@app.route("/search/books", methods=["GET"])
def search_books():
    q = (request.args.get("q") or "").strip()
    limit = int(request.args.get("limit", 10))

    if not q:
        return jsonify({"query": q, "exact": None, "results": []})

    q_lower = q.lower()
    df = books_df.copy()

    if "Book-Title" not in df.columns:
        return jsonify({"error": "books dataset missing 'Book-Title' column"}), 500
    if "Book-Author" not in df.columns:
        df["Book-Author"] = ""

    df["__title_lower"] = df["Book-Title"].fillna("").astype(str).str.lower()
    df["__author_lower"] = df["Book-Author"].fillna("").astype(str).str.lower()

    exact_row = df[df["__title_lower"] == q_lower]
    exact = None
    if not exact_row.empty:
        r = exact_row.iloc[0]
        exact = {
            "title": clean(r.get("Book-Title")),
            "author": clean(r.get("Book-Author")),
            "image": clean(r.get("Image-URL-L")),
        }

    contains = df[
        df["__title_lower"].str.contains(re.escape(q_lower), na=False)
        | df["__author_lower"].str.contains(re.escape(q_lower), na=False)
    ].head(limit)

    results = []
    for _, r in contains.iterrows():
        results.append({
            "title": clean(r.get("Book-Title")),
            "author": clean(r.get("Book-Author")),
            "image": clean(r.get("Image-URL-L")),
        })

    return jsonify({"query": q, "exact": exact, "results": results})


# -----------------------
# FAVORITES
# -----------------------
@app.route("/favorites", methods=["POST"])
def add_favorite():
    user, err = require_user()
    if err:
        return err
    data = request.json or {}
    title = data.get("book_title")
    if not title:
        return jsonify({"error": "book_title required"}), 400
    if favorites_collection.find_one({"user_id": str(user["_id"]), "book_title": title}):
        return jsonify({"message": "Already in favorites"}), 200
    favorites_collection.insert_one({
        "user_id": str(user["_id"]),
        "book_title": title,
        "created_at": datetime.utcnow()
    })
    track_event(user["_id"], "favorite_add", title)
    return jsonify({"message": "Added to favorites"}), 201


@app.route("/favorites", methods=["GET"])
def get_favorites():
    user, err = require_user()
    if err:
        return err
    favs = favorites_collection.find({"user_id": str(user["_id"])}, {"_id": 0, "book_title": 1})
    return jsonify([f["book_title"] for f in favs]), 200


@app.route("/favorites", methods=["DELETE"])
def remove_favorite():
    user, err = require_user()
    if err:
        return err
    book_title = request.args.get("book_title")
    if not book_title:
        return jsonify({"error": "book_title required"}), 400
    track_event(str(user["_id"]), "favorite_remove", book_title=book_title)
    favorites_collection.delete_one({"user_id": str(user["_id"]), "book_title": book_title})
    return jsonify({"message": "Removed from favorites"}), 200


# -----------------------
# AUTH
# -----------------------
@app.route("/register", methods=["POST"])
def register():
    data = request.json
    if not data.get("username") or not data.get("email") or not data.get("password"):
        return jsonify({"error": "Username, email and password required"}), 400
    if users_collection.find_one({"email": data["email"]}):
        return jsonify({"error": "User already exists"}), 409
    users_collection.insert_one({
        "username": data["username"],
        "email": data["email"],
        "password": generate_password_hash(data["password"]),
        "interests": data.get("interests", []),
        "preferred_emotions": data.get("preferred_emotions", []),
        "created_at": datetime.utcnow()
    })
    return jsonify({"message": "User registered successfully"}), 201


@app.route("/login", methods=["POST"])
def login():
    data = request.json
    user = users_collection.find_one({"email": data.get("email")})
    if not user or not check_password_hash(user["password"], data.get("password")):
        return jsonify({"error": "Invalid credentials"}), 401
    return jsonify({
        "message": "Login successful",
        "user": {
            "id": str(user["_id"]),
            "username": user["username"],
            "email": user["email"],
            "interests": user.get("interests", []),
            "preferred_emotions": user.get("preferred_emotions", [])
        }
    })


# -----------------------
# INTEREST / EMOTION / HYBRID
# -----------------------
@app.route("/recommend/interest", methods=["POST"])
def recommend_by_interest():
    interests = [i.lower().strip() for i in request.json.get("interests", [])]
    if not interests:
        return jsonify([])
    results = []
    for _, r in books_df.iterrows():
        tags = str(r.get("InterestTags", "")).lower()
        if not tags:
            continue
        tag_list = [t.strip() for t in tags.split(",")]
        matched = list(set(interests).intersection(tag_list))
        if not matched:
            continue
        reasons = build_ai_reasons(matched_genres=matched)
        results.append({
            "title": clean(r.get("Book-Title")),
            "genres": tag_list,
            "emotion": clean(r.get("EmotionTags")),
            "image": clean(r.get("Image-URL-L")),
            "ai_reason": reasons
        })
        if len(results) >= 20:
            break
    return jsonify(results)


@app.route("/recommend/emotion", methods=["POST"])
def recommend_by_emotion():
    emotions = [e.lower().strip() for e in request.json.get("emotions", [])]
    if not emotions:
        return jsonify([])
    results = []
    for _, r in books_df.iterrows():
        emo = clean(r.get("EmotionTags"))
        if not emo:
            continue
        emo_list = [e.strip().lower() for e in emo.split(",")]
        matched = [e for e in emo_list if e in emotions]
        if not matched:
            continue
        reasons = build_ai_reasons(matched_emotions=matched)
        results.append({
            "title": clean(r.get("Book-Title")),
            "genres": str(r.get("PredictedGenre", "")).split(","),
            "emotion": emo,
            "image": clean(r.get("Image-URL-L")),
            "ai_reason": reasons
        })
        if len(results) >= 20:
            break
    return jsonify(results)


@app.route("/recommend/hybrid", methods=["POST"])
def recommend_hybrid():
    data = request.json
    interests = [i.lower() for i in data.get("interests", [])]
    emotions = [e.lower() for e in data.get("emotions", [])]
    scored = []
    for _, r in books_df.iterrows():
        score = 0
        genre = str(r.get("PredictedGenre", "")).lower()
        emotion = str(r.get("EmotionTags", "")).lower()
        if any(i in genre for i in interests):
            score += 2
        if any(e in emotion for e in emotions):
            score += 2
        if score > 0:
            scored.append((score, r))
    scored.sort(reverse=True, key=lambda x: x[0])
    final = []
    for _, r in scored[:20]:
        genre = str(r.get("PredictedGenre", "")).lower()
        emotion = str(r.get("EmotionTags", "")).lower()
        matched_genres = [i for i in interests if i in genre]
        matched_emotions = [e for e in emotions if e in emotion]
        reasons = build_ai_reasons(matched_genres=matched_genres, matched_emotions=matched_emotions, is_hybrid=True)
        final.append({
            "title": clean(r.get("Book-Title")),
            "genres": genre.split(","),
            "emotion": clean(r.get("EmotionTags")),
            "image": clean(r.get("Image-URL-L")),
            "ai_reason": reasons
        })
    return jsonify(final)


# -----------------------
# REVIEWS
# -----------------------
@app.route("/reviews", methods=["POST"])
def add_or_update_review():
    data = request.json or {}
    user_id = (data.get("user_id") or "").strip()
    username = (data.get("username") or "").strip()
    book_title = (data.get("book_title") or "").strip()
    rating = safe_int(data.get("rating"))
    review_text = (data.get("review_text") or "").strip()

    if not user_id or not book_title:
        return jsonify({"error": "user_id and book_title are required"}), 400
    if rating is None or rating < 1 or rating > 5:
        return jsonify({"error": "rating must be between 1 and 5"}), 400

    track_event(user_id, "review_save", book_title=book_title, meta={"rating": rating})

    doc = {
        "user_id": user_id,
        "username": username or "Anonymous",
        "book_title": book_title,
        "rating": rating,
        "review_text": review_text,
        "updated_at": datetime.utcnow(),
    }

    reviews_collection.update_one(
        {"user_id": user_id, "book_title": book_title},
        {"$set": doc, "$setOnInsert": {"created_at": datetime.utcnow()}},
        upsert=True,
    )
    return jsonify({"message": "Review saved"}), 200


@app.route("/reviews/book", methods=["GET"])
def get_reviews_for_book():
    title = (request.args.get("title") or "").strip()
    if not title:
        return jsonify({"error": "title is required"}), 400
    cursor = reviews_collection.find({"book_title": title}, {"_id": 0}).sort("created_at", -1)
    reviews = list(cursor)
    avg = sum(r.get("rating", 0) for r in reviews) / len(reviews) if reviews else 0.0
    return jsonify({"title": title, "avg_rating": round(avg, 2), "total_reviews": len(reviews), "reviews": reviews})


@app.route("/reviews/user", methods=["GET"])
def get_reviews_for_user():
    user_id = (request.args.get("user_id") or "").strip()
    if not user_id:
        return jsonify({"error": "user_id is required"}), 400
    cursor = reviews_collection.find({"user_id": user_id}, {"_id": 0}).sort("updated_at", -1)
    return jsonify(list(cursor))


@app.route("/reviews", methods=["DELETE"])
def delete_review():
    user_id = (request.args.get("user_id") or "").strip()
    book_title = (request.args.get("book_title") or "").strip()
    if not user_id or not book_title:
        return jsonify({"error": "user_id and book_title are required"}), 400
    reviews_collection.delete_one({"user_id": user_id, "book_title": book_title})
    return jsonify({"message": "Review deleted"}), 200


# -----------------------
# COMMUNITY
# -----------------------
@app.route("/community/posts", methods=["GET"])
def community_list_posts():
    user, err = require_user()
    if err:
        return err
    limit = safe_int(request.args.get("limit"), 30) or 30
    limit = max(1, min(limit, 100))
    items = list_posts(posts_collection, post_likes_collection, str(user["_id"]), limit=limit)
    track_event(str(user["_id"]), "community_feed_open", meta={"limit": limit})
    out = []
    for p in items:
        post_id_str = str(p.get("_id") or p.get("id"))
        liked_by_me = p.get("liked_by_me")
        if liked_by_me is None:
            liked_by_me = post_likes_collection.find_one({"post_id": post_id_str, "user_id": str(user["_id"])}) is not None
        created_at = p.get("created_at")
        created_at_iso = created_at.isoformat() if hasattr(created_at, "isoformat") else created_at
        out.append({
            "id": post_id_str,
            "user_id": p.get("user_id"),
            "username": p.get("username", ""),
            "text": p.get("text", ""),
            "book_title": p.get("book_title", ""),
            "rating": p.get("rating", 0),
            "emotion_tags": p.get("emotion_tags", []) or [],
            "interest_tags": p.get("interest_tags", []) or [],
            "likes_count": p.get("likes_count", 0),
            "comments_count": p.get("comments_count", 0),
            "created_at": created_at_iso,
            "liked_by_me": bool(liked_by_me),
        })
    return jsonify(out), 200


@app.route("/community/posts", methods=["POST"])
def community_create_post():
    user, err = require_user()
    if err:
        return err
    payload = request.json or {}
    text = (payload.get("text") or "").strip()
    book_title = (payload.get("book_title") or "").strip()
    if not text:
        return jsonify({"error": "text is required"}), 400
    if not book_title:
        return jsonify({"error": "book_title is required"}), 400
    post, err = create_post(posts_collection, user, payload)
    if err:
        msg, code = err
        return jsonify({"error": msg}), code
    track_event(str(user["_id"]), "community_post_create", book_title=book_title, meta={"text_preview": text[:120]})
    created_at = post.get("created_at")
    created_at_iso = created_at.isoformat() if created_at else None
    return jsonify({
        "id": str(post["_id"]),
        "user_id": post.get("user_id"),
        "username": post.get("username", ""),
        "text": post.get("text", ""),
        "book_title": post.get("book_title", ""),
        "rating": post.get("rating", 0),
        "emotion_tags": post.get("emotion_tags", []) or [],
        "interest_tags": post.get("interest_tags", []) or [],
        "likes_count": post.get("likes_count", 0),
        "comments_count": post.get("comments_count", 0),
        "created_at": created_at_iso,
        "liked_by_me": False,
    }), 201


@app.route("/community/posts/by-book", methods=["GET"])
def community_list_posts_by_book():
    user, err = require_user()
    if err:
        return err
    book_title = (request.args.get("book_title") or "").strip()
    limit = safe_int(request.args.get("limit"), 20) or 20
    limit = max(1, min(limit, 100))
    if not book_title:
        return jsonify([]), 200
    track_event(str(user["_id"]), "community_open_book", book_title=book_title)
    query = {"book_title": {"$regex": f"^{re.escape(book_title)}$", "$options": "i"}}
    cursor = posts_collection.find(query).sort("created_at", -1).limit(limit)
    posts = list(cursor)
    out = []
    for p in posts:
        post_id_str = str(p["_id"])
        liked_by_me = post_likes_collection.find_one({"post_id": post_id_str, "user_id": str(user["_id"])}) is not None
        out.append({
            "id": post_id_str,
            "user_id": p.get("user_id"),
            "username": p.get("username", ""),
            "text": p.get("text", ""),
            "book_title": p.get("book_title", ""),
            "rating": p.get("rating", 0),
            "emotion_tags": p.get("emotion_tags", []) or [],
            "interest_tags": p.get("interest_tags", []) or [],
            "likes_count": p.get("likes_count", 0),
            "comments_count": p.get("comments_count", 0),
            "created_at": p.get("created_at").isoformat() if p.get("created_at") else None,
            "liked_by_me": liked_by_me,
        })
    return jsonify(out), 200


@app.route("/community/posts/<post_id>/like", methods=["POST"])
def community_toggle_like(post_id):
    user, err = require_user()
    if err:
        return err
    data, error = toggle_like(posts_collection, post_likes_collection, post_id, str(user["_id"]))
    if error:
        msg, code = error
        return jsonify({"error": msg}), code
    track_event(str(user["_id"]), "community_like_toggle", meta={"post_id": post_id, "liked_by_me": data.get("liked_by_me")})
    return jsonify(data), 200


@app.route("/community/posts/<post_id>/comments", methods=["GET"])
def community_list_comments(post_id):
    user, err = require_user()
    if err:
        return err
    limit = safe_int(request.args.get("limit"), 100) or 100
    limit = max(1, min(limit, 200))
    items, error = list_comments(comments_collection, post_id, limit=limit)
    if error:
        msg, code = error
        return jsonify({"error": msg}), code
    normalized = []
    for c in items:
        cid = c.get("id") or c.get("_id") or c.get("comment_id")
        created_at = c.get("created_at")
        created_at_iso = created_at.isoformat() if hasattr(created_at, "isoformat") else created_at
        normalized.append({
            "id": str(cid),
            "post_id": c.get("post_id"),
            "user_id": c.get("user_id"),
            "username": c.get("username"),
            "text": c.get("text"),
            "created_at": created_at_iso,
        })
    track_event(str(user["_id"]), "community_comments_open", meta={"post_id": post_id})
    return jsonify(normalized), 200


@app.route("/community/posts/<post_id>/comments", methods=["POST"])
def community_add_comment(post_id):
    user, err = require_user()
    if err:
        return err
    payload = request.json or {}
    text = (payload.get("text") or "").strip()
    if not text:
        return jsonify({"error": "text is required"}), 400
    comment, error = add_comment(posts_collection, comments_collection, post_id, user, payload)
    if error:
        msg, code = error
        return jsonify({"error": msg}), code
    track_event(str(user["_id"]), "community_comment_add", meta={"post_id": post_id, "text_preview": text[:120]})
    return jsonify({
        "id": str(comment["_id"]),
        "post_id": post_id,
        "user_id": str(user["_id"]),
        "username": user.get("username"),
        "text": comment["text"],
        "created_at": comment["created_at"].isoformat(),
    }), 201


@app.route("/community/comments/<comment_id>", methods=["DELETE"])
def community_delete_comment(comment_id):
    user, err = require_user()
    if err:
        return err
    error = delete_comment(posts_collection, comments_collection, comment_id, str(user["_id"]))
    if error:
        msg, code = error
        return jsonify({"error": msg}), code
    track_event(str(user["_id"]), "community_comment_delete", meta={"comment_id": comment_id})
    return jsonify({"message": "comment deleted"}), 200


# -----------------------
# AI INSIGHTS
# -----------------------
@app.route("/insights/activity", methods=["GET"])
def insights_activity():
    user, err = require_user()
    if err:
        return err
    limit = safe_int(request.args.get("limit"), 50) or 50
    limit = max(1, min(limit, 200))
    cursor = events_collection.find({"user_id": str(user["_id"])}, {"_id": 0}).sort("created_at", -1).limit(limit)
    items = list(cursor)
    for it in items:
        it["created_at"] = _safe_iso(it.get("created_at"))
    return jsonify({"user_id": str(user["_id"]), "count": len(items), "events": items}), 200


@app.route("/insights/me", methods=["GET"])
def insights_me():
    user, err = require_user()
    if err:
        return err
    uid = str(user["_id"])
    total_views = events_collection.count_documents({"user_id": uid, "type": "view_book"})
    total_reco_search = events_collection.count_documents({"user_id": uid, "type": "recommend_search"})
    total_text_reco = events_collection.count_documents({"user_id": uid, "type": "recommend_text"})
    total_fav_add = events_collection.count_documents({"user_id": uid, "type": "favorite_add"})
    total_reviews = reviews_collection.count_documents({"user_id": uid})
    total_posts = posts_collection.count_documents({"user_id": uid})
    reviews = list(reviews_collection.find({"user_id": uid}, {"_id": 0, "rating": 1}))
    avg_rating = round(sum(r.get("rating", 0) for r in reviews) / len(reviews), 2) if reviews else 0.0
    recent = list(events_collection.find({"user_id": uid}, {"_id": 0}).sort("created_at", -1).limit(10))
    for it in recent:
        it["created_at"] = _safe_iso(it.get("created_at"))
    pipeline_top_books = [
        {"$match": {"user_id": uid, "type": "view_book", "book_title": {"$ne": None}}},
        {"$group": {"_id": "$book_title", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 10},
    ]
    top_books = list(events_collection.aggregate(pipeline_top_books))
    top_books = [{"title": x["_id"], "count": x["count"]} for x in top_books]
    genre_counts = {}
    emotion_counts = {}
    for b in top_books:
        genres, emotions = _title_to_tags(b["title"])
        for g in genres:
            genre_counts[g] = genre_counts.get(g, 0) + b["count"]
        for e in emotions:
            emotion_counts[e] = emotion_counts.get(e, 0) + b["count"]
    top_genres = sorted(genre_counts.items(), key=lambda x: x[1], reverse=True)[:8]
    top_emotions = sorted(emotion_counts.items(), key=lambda x: x[1], reverse=True)[:8]
    return jsonify({
        "user": {"id": uid, "username": user.get("username"), "email": user.get("email")},
        "stats": {
            "total_book_views": total_views,
            "total_recommend_searches": total_reco_search,
            "total_text_recommendations": total_text_reco,
            "favorites_added": total_fav_add,
            "reviews_count": total_reviews,
            "posts_count": total_posts,
            "avg_rating": avg_rating,
        },
        "top": {
            "books_viewed": top_books,
            "genres": [{"name": k, "score": v} for k, v in top_genres],
            "emotions": [{"name": k, "score": v} for k, v in top_emotions],
        },
        "recent_activity": recent
    })


# -----------------------
# PROFILE
# -----------------------
@app.route("/users/me", methods=["GET"])
def get_me():
    user, err = require_user()
    if err:
        return err
    return jsonify({
        "id": str(user["_id"]),
        "username": user.get("username"),
        "email": user.get("email"),
        "bio": user.get("bio"),
        "vision": user.get("vision"),
        "mission": user.get("mission"),
        "goals": user.get("goals", []),
        "interests": user.get("interests", []),
        "preferred_emotions": user.get("preferred_emotions", []),
        "created_at": _safe_iso(user.get("created_at")),
        "updated_at": _safe_iso(user.get("updated_at")),
    }), 200


@app.route("/users/me", methods=["PUT"])
def update_me():
    user, err = require_user()
    if err:
        return err
    data = request.json or {}
    update_doc = {"updated_at": datetime.utcnow()}
    if "username" in data:
        update_doc["username"] = (data.get("username") or "").strip()
    if "bio" in data:
        update_doc["bio"] = (data.get("bio") or "").strip()
    if "vision" in data:
        update_doc["vision"] = (data.get("vision") or "").strip()
    if "mission" in data:
        update_doc["mission"] = (data.get("mission") or "").strip()
    if "goals" in data and isinstance(data["goals"], list):
        update_doc["goals"] = [str(x).strip() for x in data["goals"] if str(x).strip()]
    if "interests" in data and isinstance(data["interests"], list):
        update_doc["interests"] = [str(x).strip() for x in data["interests"] if str(x).strip()]
    if "preferred_emotions" in data and isinstance(data["preferred_emotions"], list):
        update_doc["preferred_emotions"] = [str(x).strip() for x in data["preferred_emotions"] if str(x).strip()]
    users_collection.update_one({"_id": user["_id"]}, {"$set": update_doc})
    track_event(str(user["_id"]), "profile_update", meta={"fields": list(update_doc.keys())})
    fresh = users_collection.find_one({"_id": user["_id"]})
    return jsonify({
        "message": "Profile updated",
        "user": {
            "id": str(fresh["_id"]),
            "username": fresh.get("username"),
            "email": fresh.get("email"),
            "bio": fresh.get("bio"),
            "vision": fresh.get("vision"),
            "mission": fresh.get("mission"),
            "goals": fresh.get("goals", []),
            "interests": fresh.get("interests", []),
            "preferred_emotions": fresh.get("preferred_emotions", []),
            "updated_at": _safe_iso(fresh.get("updated_at")),
        }
    }), 200


# -----------------------
# NOTES
# -----------------------
@app.route("/notes", methods=["POST"])
def create_note():
    user, err = require_user()
    if err:
        return err
    payload = request.json or {}
    text = safe_str(payload.get("text"))
    if not text:
        return jsonify({"error": "text is required"}), 400
    title = safe_str(payload.get("title"))
    tags = safe_list_str(payload.get("tags"))
    mood = safe_str(payload.get("mood")) or "neutral"
    pinned = payload.get("pinned", False) == True
    doc = {
        "user_id": str(user["_id"]),
        "title": title,
        "text": text,
        "tags": tags,
        "mood": mood,
        "pinned": pinned,
        "created_at": now_utc(),
        "updated_at": now_utc(),
    }
    ins = notes_collection.insert_one(doc)
    track_event(str(user["_id"]), "note_create", meta={"title": title[:80] if title else "", "tags": tags[:10]})
    return jsonify({
        "id": str(ins.inserted_id),
        "title": title,
        "text": text,
        "tags": tags,
        "mood": mood,
        "pinned": pinned,
        "created_at": _safe_iso(doc["created_at"]),
        "updated_at": _safe_iso(doc["updated_at"]),
    }), 201


@app.route("/notes", methods=["GET"])
def list_notes():
    user, err = require_user()
    if err:
        return err
    limit = safe_int(request.args.get("limit"), 50) or 50
    limit = max(1, min(limit, 200))
    cursor = notes_collection.find({"user_id": str(user["_id"])}, {"user_id": 0}).sort("created_at", -1).limit(limit)
    items = list(cursor)
    out = []
    for n in items:
        out.append({
            "id": str(n["_id"]),
            "title": n.get("title", ""),
            "text": n.get("text", ""),
            "tags": n.get("tags", []),
            "mood": n.get("mood", "neutral"),
            "pinned": n.get("pinned", False),
            "created_at": _safe_iso(n.get("created_at")),
            "updated_at": _safe_iso(n.get("updated_at")),
        })
    track_event(str(user["_id"]), "note_list_open", meta={"limit": limit})
    return jsonify({"count": len(out), "notes": out}), 200


@app.route("/notes/<note_id>", methods=["DELETE"])
def delete_note(note_id):
    user, err = require_user()
    if err:
        return err
    try:
        oid = ObjectId(note_id)
    except Exception:
        return jsonify({"error": "Invalid note id"}), 400
    res = notes_collection.delete_one({"_id": oid, "user_id": str(user["_id"])})
    if res.deleted_count == 0:
        return jsonify({"error": "Note not found"}), 404
    track_event(str(user["_id"]), "note_delete", meta={"note_id": note_id})
    return jsonify({"message": "Note deleted"}), 200


# -----------------------
# LIBRARY
# -----------------------
@app.route("/library", methods=["POST"])
def library_add():
    user, err = require_user()
    if err:
        return err
    payload = request.json or {}
    book_title = safe_str(payload.get("book_title"))
    if not book_title:
        return jsonify({"error": "book_title is required"}), 400
    status = normalize_status(payload.get("status")) or "to_read"
    progress = clamp_progress(payload.get("progress"))
    author = safe_str(payload.get("author"))
    doc = {
        "user_id": str(user["_id"]),
        "book_title": book_title,
        "author": author,
        "status": status,
        "progress": progress,
        "started_at": payload.get("started_at"),
        "finished_at": payload.get("finished_at"),
        "updated_at": now_utc(),
    }
    set_on_insert = {"created_at": now_utc()}
    library_collection.update_one(
        {"user_id": str(user["_id"]), "book_title": book_title},
        {"$set": doc, "$setOnInsert": set_on_insert},
        upsert=True
    )
    saved = library_collection.find_one({"user_id": str(user["_id"]), "book_title": book_title})
    track_event(str(user["_id"]), "library_add", book_title=book_title, meta={"status": status})
    return jsonify({
        "id": str(saved["_id"]),
        "book_title": saved.get("book_title"),
        "author": saved.get("author"),
        "status": saved.get("status"),
        "progress": saved.get("progress", 0),
        "started_at": saved.get("started_at"),
        "finished_at": saved.get("finished_at"),
        "created_at": _safe_iso(saved.get("created_at")),
        "updated_at": _safe_iso(saved.get("updated_at")),
    }), 201


@app.route("/library", methods=["GET"])
def library_list():
    user, err = require_user()
    if err:
        return err
    status = normalize_status(request.args.get("status"))
    limit = safe_int(request.args.get("limit"), 50) or 50
    limit = max(1, min(limit, 200))
    q = {"user_id": str(user["_id"])}
    if status:
        q["status"] = status
    cursor = library_collection.find(q).sort("updated_at", -1).limit(limit)
    items = list(cursor)
    out = []
    for it in items:
        out.append({
            "id": str(it["_id"]),
            "book_title": it.get("book_title"),
            "author": it.get("author"),
            "status": it.get("status"),
            "progress": it.get("progress", 0),
            "started_at": it.get("started_at"),
            "finished_at": it.get("finished_at"),
            "created_at": _safe_iso(it.get("created_at")),
            "updated_at": _safe_iso(it.get("updated_at")),
        })
    track_event(str(user["_id"]), "library_open", meta={"status": status, "limit": limit})
    return jsonify(out), 200


@app.route("/library/<item_id>", methods=["PATCH"])
def library_update(item_id):
    user, err = require_user()
    if err:
        return err
    try:
        oid = ObjectId(item_id)
    except Exception:
        return jsonify({"error": "Invalid library id"}), 400
    payload = request.json or {}
    update = {}
    if "status" in payload:
        st = normalize_status(payload.get("status"))
        if not st:
            return jsonify({"error": "Invalid status"}), 400
        update["status"] = st
    if "progress" in payload:
        update["progress"] = clamp_progress(payload.get("progress"))
    if "started_at" in payload:
        update["started_at"] = payload.get("started_at")
    if "finished_at" in payload:
        update["finished_at"] = payload.get("finished_at")
    if not update:
        return jsonify({"error": "Nothing to update"}), 400
    update["updated_at"] = now_utc()
    res = library_collection.update_one({"_id": oid, "user_id": str(user["_id"])}, {"$set": update})
    if res.matched_count == 0:
        return jsonify({"error": "Library item not found"}), 404
    updated = library_collection.find_one({"_id": oid})
    track_event(str(user["_id"]), "library_update", meta={"item_id": item_id, "fields": list(update.keys())})
    return jsonify({
        "id": str(updated["_id"]),
        "book_title": updated.get("book_title"),
        "author": updated.get("author"),
        "status": updated.get("status"),
        "progress": updated.get("progress", 0),
        "started_at": updated.get("started_at"),
        "finished_at": updated.get("finished_at"),
        "created_at": _safe_iso(updated.get("created_at")),
        "updated_at": _safe_iso(updated.get("updated_at")),
    }), 200


@app.route("/library/<item_id>", methods=["DELETE"])
def library_delete(item_id):
    user, err = require_user()
    if err:
        return err
    try:
        oid = ObjectId(item_id)
    except Exception:
        return jsonify({"error": "Invalid library id"}), 400
    res = library_collection.delete_one({"_id": oid, "user_id": str(user["_id"])})
    if res.deleted_count == 0:
        return jsonify({"error": "Library item not found"}), 404
    track_event(str(user["_id"]), "library_delete", meta={"item_id": item_id})
    return jsonify({"message": "Removed from library"}), 200


# =======================
# 🔐 ADMIN CONFIG
# =======================
ADMIN_USERNAME = "Admin"
ADMIN_PASSWORD = "admin@123"
ADMIN_STATIC_TOKEN = "bookmind-admin-secret"


def require_admin():
    token = request.headers.get("X-ADMIN-TOKEN")
    if token != ADMIN_STATIC_TOKEN:
        return None, (jsonify({"error": "Unauthorized admin access"}), 401)
    return True, None


@app.route("/admin/login", methods=["POST"])
def admin_login():
    data = request.json or {}
    if data.get("username") == ADMIN_USERNAME and data.get("password") == ADMIN_PASSWORD:
        return jsonify({"message": "Admin login successful", "admin_token": ADMIN_STATIC_TOKEN}), 200
    return jsonify({"error": "Invalid admin credentials"}), 401


# -----------------------
# 📊 ADMIN DASHBOARD
# -----------------------
@app.route("/admin/dashboard", methods=["GET"])
def admin_dashboard():
    ok, err = require_admin()
    if err:
        return err

    total_users = users_collection.count_documents({})
    total_posts = posts_collection.count_documents({})
    total_reviews = reviews_collection.count_documents({})
    total_favorites = favorites_collection.count_documents({})
    total_events = events_collection.count_documents({})
    total_admin_books = admin_books_collection.count_documents({})

    # Recent signups (last 7 days)
    from datetime import timedelta
    seven_days_ago = datetime.utcnow() - timedelta(days=7)
    new_users_week = users_collection.count_documents({"created_at": {"$gte": seven_days_ago}})
    new_posts_week = posts_collection.count_documents({"created_at": {"$gte": seven_days_ago}})

    return jsonify({
        "total_users": total_users,
        "total_posts": total_posts,
        "total_reviews": total_reviews,
        "total_favorites": total_favorites,
        "total_events": total_events,
        "total_admin_books": total_admin_books,
        "new_users_week": new_users_week,
        "new_posts_week": new_posts_week,
    }), 200


# -----------------------
# 📚 ADMIN: BOOK MANAGEMENT
# -----------------------
@app.route("/admin/books", methods=["GET"])
def admin_list_books():
    ok, err = require_admin()
    if err:
        return err

    limit = safe_int(request.args.get("limit"), 50) or 50
    limit = max(1, min(limit, 200))
    page = safe_int(request.args.get("page"), 1) or 1
    skip = (page - 1) * limit

    q_str = (request.args.get("q") or "").strip()
    query = {}
    if q_str:
        query["$or"] = [
            {"title": {"$regex": re.escape(q_str), "$options": "i"}},
            {"author": {"$regex": re.escape(q_str), "$options": "i"}},
        ]

    total = admin_books_collection.count_documents(query)
    cursor = admin_books_collection.find(query).sort("created_at", -1).skip(skip).limit(limit)

    books = []
    for b in cursor:
        books.append({
            "id": str(b["_id"]),
            "title": b.get("title"),
            "author": b.get("author"),
            "year": b.get("year"),
            "description": b.get("description"),
            "genres": b.get("genres", []),
            "emotion": b.get("emotion"),
            "image": b.get("image"),
            "created_at": _safe_iso(b.get("created_at")),
            "updated_at": _safe_iso(b.get("updated_at")),
        })

    return jsonify({"total": total, "page": page, "limit": limit, "books": books}), 200


@app.route("/admin/books", methods=["POST"])
def admin_add_book():
    ok, err = require_admin()
    if err:
        return err

    data = request.json or {}
    if not data.get("title") or not data.get("author"):
        return jsonify({"error": "title and author are required"}), 400

    doc = {
        "title": data.get("title"),
        "author": data.get("author"),
        "year": data.get("year"),
        "description": data.get("description"),
        "genres": data.get("genres", []),
        "emotion": data.get("emotion"),
        "image": data.get("image"),
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }

    ins = admin_books_collection.insert_one(doc)
    return jsonify({"message": "Book added", "id": str(ins.inserted_id)}), 201


@app.route("/admin/books/<book_id>", methods=["PUT"])
def admin_update_book(book_id):
    ok, err = require_admin()
    if err:
        return err

    try:
        oid = ObjectId(book_id)
    except Exception:
        return jsonify({"error": "Invalid book id"}), 400

    data = request.json or {}
    update = {"updated_at": datetime.utcnow()}

    for field in ["title", "author", "year", "description", "emotion", "image"]:
        if field in data:
            update[field] = data[field]
    if "genres" in data and isinstance(data["genres"], list):
        update["genres"] = data["genres"]

    if len(update) == 1:
        return jsonify({"error": "Nothing to update"}), 400

    res = admin_books_collection.update_one({"_id": oid}, {"$set": update})
    if res.matched_count == 0:
        return jsonify({"error": "Book not found"}), 404

    updated = admin_books_collection.find_one({"_id": oid})
    return jsonify({
        "message": "Book updated",
        "book": {
            "id": str(updated["_id"]),
            "title": updated.get("title"),
            "author": updated.get("author"),
            "year": updated.get("year"),
            "description": updated.get("description"),
            "genres": updated.get("genres", []),
            "emotion": updated.get("emotion"),
            "image": updated.get("image"),
            "updated_at": _safe_iso(updated.get("updated_at")),
        }
    }), 200


@app.route("/admin/books/<book_id>", methods=["DELETE"])
def admin_delete_book(book_id):
    ok, err = require_admin()
    if err:
        return err

    try:
        oid = ObjectId(book_id)
    except Exception:
        return jsonify({"error": "Invalid book id"}), 400

    res = admin_books_collection.delete_one({"_id": oid})
    if res.deleted_count == 0:
        return jsonify({"error": "Book not found"}), 404

    return jsonify({"message": "Book deleted"}), 200


# -----------------------
# 👥 ADMIN: USER MONITORING
# -----------------------
@app.route("/admin/users", methods=["GET"])
def admin_list_users():
    ok, err = require_admin()
    if err:
        return err

    limit = safe_int(request.args.get("limit"), 50) or 50
    limit = max(1, min(limit, 200))

    cursor = users_collection.find({}, {"password": 0}).sort("created_at", -1).limit(limit)

    users = []
    for u in cursor:
        uid = str(u["_id"])
        # Engagement metrics per user
        event_count = events_collection.count_documents({"user_id": uid})
        review_count = reviews_collection.count_documents({"user_id": uid})
        post_count = posts_collection.count_documents({"user_id": uid})
        fav_count = favorites_collection.count_documents({"user_id": uid})

        users.append({
            "id": uid,
            "username": u.get("username"),
            "email": u.get("email"),
            "interests": u.get("interests", []),
            "preferred_emotions": u.get("preferred_emotions", []),
            "created_at": _safe_iso(u.get("created_at")),
            "engagement": {
                "events": event_count,
                "reviews": review_count,
                "posts": post_count,
                "favorites": fav_count,
            }
        })

    return jsonify(users), 200


@app.route("/admin/users/<user_id>", methods=["DELETE"])
def admin_delete_user(user_id):
    ok, err = require_admin()
    if err:
        return err

    try:
        oid = ObjectId(user_id)
    except Exception:
        return jsonify({"error": "Invalid user id"}), 400

    res = users_collection.delete_one({"_id": oid})
    if res.deleted_count == 0:
        return jsonify({"error": "User not found"}), 404

    # Clean up user data across collections
    uid_str = user_id
    favorites_collection.delete_many({"user_id": uid_str})
    reviews_collection.delete_many({"user_id": uid_str})
    posts_collection.delete_many({"user_id": uid_str})
    notes_collection.delete_many({"user_id": uid_str})
    library_collection.delete_many({"user_id": uid_str})
    events_collection.delete_many({"user_id": uid_str})

    return jsonify({"message": "User and all associated data deleted"}), 200


# -----------------------
# 📝 ADMIN: POSTS MANAGEMENT
# -----------------------
@app.route("/admin/posts", methods=["GET"])
def admin_list_posts():
    ok, err = require_admin()
    if err:
        return err

    limit = safe_int(request.args.get("limit"), 50) or 50
    limit = max(1, min(limit, 200))

    cursor = posts_collection.find({}).sort("created_at", -1).limit(limit)

    result = []
    for p in cursor:
        result.append({
            "id": str(p["_id"]),
            "user_id": p.get("user_id"),
            "username": p.get("username"),
            "text": p.get("text"),
            "book_title": p.get("book_title"),
            "rating": p.get("rating", 0),
            "likes_count": p.get("likes_count", 0),
            "comments_count": p.get("comments_count", 0),
            "created_at": _safe_iso(p.get("created_at")),
        })

    return jsonify(result), 200


@app.route("/admin/posts/<post_id>", methods=["DELETE"])
def admin_delete_post(post_id):
    ok, err = require_admin()
    if err:
        return err

    try:
        oid = ObjectId(post_id)
    except Exception:
        return jsonify({"error": "Invalid post id"}), 400

    res = posts_collection.delete_one({"_id": oid})
    if res.deleted_count == 0:
        return jsonify({"error": "Post not found"}), 404

    # Clean up comments and likes
    comments_collection.delete_many({"post_id": post_id})
    post_likes_collection.delete_many({"post_id": post_id})

    return jsonify({"message": "Post deleted"}), 200


# -----------------------
# ⭐ ADMIN: REVIEWS MANAGEMENT
# -----------------------
@app.route("/admin/reviews", methods=["GET"])
def admin_list_reviews():
    ok, err = require_admin()
    if err:
        return err

    limit = safe_int(request.args.get("limit"), 50) or 50
    limit = max(1, min(limit, 200))

    cursor = reviews_collection.find({}, {"_id": 1, "user_id": 1, "username": 1, "book_title": 1, "rating": 1, "review_text": 1, "created_at": 1}).sort("created_at", -1).limit(limit)

    result = []
    for r in cursor:
        result.append({
            "id": str(r["_id"]),
            "user_id": r.get("user_id"),
            "username": r.get("username"),
            "book_title": r.get("book_title"),
            "rating": r.get("rating"),
            "review_text": r.get("review_text"),
            "created_at": _safe_iso(r.get("created_at")),
        })

    return jsonify(result), 200


@app.route("/admin/reviews/<review_id>", methods=["DELETE"])
def admin_delete_review(review_id):
    ok, err = require_admin()
    if err:
        return err

    try:
        oid = ObjectId(review_id)
    except Exception:
        return jsonify({"error": "Invalid review id"}), 400

    res = reviews_collection.delete_one({"_id": oid})
    if res.deleted_count == 0:
        return jsonify({"error": "Review not found"}), 404

    return jsonify({"message": "Review deleted"}), 200


# -----------------------
# 📈 ADMIN: SENTIMENT ANALYTICS
# -----------------------
@app.route("/admin/analytics/sentiment", methods=["GET"])
def admin_sentiment_analytics():
    ok, err = require_admin()
    if err:
        return err

    # Rating distribution (1-5 stars)
    rating_pipeline = [
        {"$group": {"_id": "$rating", "count": {"$sum": 1}}},
        {"$sort": {"_id": 1}},
    ]
    rating_dist_raw = list(reviews_collection.aggregate(rating_pipeline))
    rating_distribution = {str(i): 0 for i in range(1, 6)}
    for rd in rating_dist_raw:
        rating_distribution[str(rd["_id"])] = rd["count"]

    # Avg rating overall
    all_reviews = list(reviews_collection.find({}, {"rating": 1}))
    total_reviews = len(all_reviews)
    avg_rating = round(sum(r.get("rating", 0) for r in all_reviews) / total_reviews, 2) if total_reviews else 0.0

    # Sentiment label distribution from books_df
    sentiment_counts = {}
    if "SentimentLabel" in books_df.columns:
        for label in books_df["SentimentLabel"].dropna():
            label = str(label).strip()
            if label and label.lower() not in ["nan", "none", ""]:
                sentiment_counts[label] = sentiment_counts.get(label, 0) + 1

    # Top rated books (from reviews)
    top_books_pipeline = [
        {"$group": {
            "_id": "$book_title",
            "avg_rating": {"$avg": "$rating"},
            "total": {"$sum": 1}
        }},
        {"$match": {"total": {"$gte": 2}}},  # at least 2 reviews
        {"$sort": {"avg_rating": -1}},
        {"$limit": 10},
    ]
    top_books = list(reviews_collection.aggregate(top_books_pipeline))
    top_rated_books = [
        {"title": b["_id"], "avg_rating": round(b["avg_rating"], 2), "review_count": b["total"]}
        for b in top_books
    ]

    # Emotion tag distribution from books_df
    emotion_counts = {}
    if "EmotionTags" in books_df.columns:
        for tags in books_df["EmotionTags"].dropna():
            for tag in str(tags).split(","):
                tag = tag.strip().lower()
                if tag and tag not in ["nan", "none", ""]:
                    emotion_counts[tag] = emotion_counts.get(tag, 0) + 1

    top_emotions = sorted(emotion_counts.items(), key=lambda x: x[1], reverse=True)[:12]

    # Genre distribution from books_df
    genre_counts = {}
    if "PredictedGenre" in books_df.columns:
        for genres in books_df["PredictedGenre"].dropna():
            for g in str(genres).split(","):
                g = g.strip()
                if g and g.lower() not in ["nan", "none", ""]:
                    genre_counts[g] = genre_counts.get(g, 0) + 1

    top_genres = sorted(genre_counts.items(), key=lambda x: x[1], reverse=True)[:12]

    return jsonify({
        "overview": {
            "total_reviews": total_reviews,
            "avg_rating": avg_rating,
        },
        "rating_distribution": rating_distribution,
        "sentiment_labels": [{"label": k, "count": v} for k, v in sorted(sentiment_counts.items(), key=lambda x: x[1], reverse=True)],
        "top_rated_books": top_rated_books,
        "emotion_distribution": [{"emotion": k, "count": v} for k, v in top_emotions],
        "genre_distribution": [{"genre": k, "count": v} for k, v in top_genres],
    }), 200


# -----------------------
# 🤖 ADMIN: AI MODEL METRICS
# -----------------------
@app.route("/admin/analytics/ai-metrics", methods=["GET"])
def admin_ai_metrics():
    ok, err = require_admin()
    if err:
        return err

    # Compute real usage metrics from events
    total_recommend_search = events_collection.count_documents({"type": "recommend_search"})
    total_recommend_text = events_collection.count_documents({"type": "recommend_text"})
    total_view_book = events_collection.count_documents({"type": "view_book"})
    total_favorite_add = events_collection.count_documents({"type": "favorite_add"})
    total_library_add = events_collection.count_documents({"type": "library_add"})

    # Click-through: users who viewed a book after a recommendation
    # Proxy: views / recommendations as CTR
    total_recommendations = total_recommend_search + total_recommend_text
    ctr = round((total_view_book / total_recommendations) * 100, 2) if total_recommendations > 0 else 0.0

    # Favorite rate: favorites / views
    favorite_rate = round((total_favorite_add / total_view_book) * 100, 2) if total_view_book > 0 else 0.0

    # Library adoption: library adds / views
    library_rate = round((total_library_add / total_view_book) * 100, 2) if total_view_book > 0 else 0.0

    # Dataset coverage
    total_books_in_df = int(len(books_df)) if books_df is not None else 0
    books_with_genres = int(books_df["PredictedGenre"].notna().sum()) if "PredictedGenre" in books_df.columns else 0
    books_with_emotions = int(books_df["EmotionTags"].notna().sum()) if "EmotionTags" in books_df.columns else 0
    books_with_sentiment = int(books_df["SentimentLabel"].notna().sum()) if "SentimentLabel" in books_df.columns else 0

    genre_coverage = round((books_with_genres / total_books_in_df) * 100, 2) if total_books_in_df > 0 else 0.0
    emotion_coverage = round((books_with_emotions / total_books_in_df) * 100, 2) if total_books_in_df > 0 else 0.0
    sentiment_coverage = round((books_with_sentiment / total_books_in_df) * 100, 2) if total_books_in_df > 0 else 0.0

    # Top searched titles
    pipeline_searches = [
        {"$match": {"type": "recommend_search", "book_title": {"$ne": None}}},
        {"$group": {"_id": "$book_title", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 10},
    ]
    top_searches = list(events_collection.aggregate(pipeline_searches))
    top_searches = [{"title": x["_id"], "count": x["count"]} for x in top_searches]

    # Event type breakdown
    event_pipeline = [
        {"$group": {"_id": "$type", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
    ]
    event_breakdown = list(events_collection.aggregate(event_pipeline))
    event_breakdown = [{"type": x["_id"], "count": x["count"]} for x in event_breakdown]

    return jsonify({
        "recommendation_stats": {
            "total_search_based": total_recommend_search,
            "total_text_based": total_recommend_text,
            "total_recommendations": total_recommendations,
            "total_book_views": total_view_book,
            "click_through_rate_pct": ctr,
            "favorite_rate_pct": favorite_rate,
            "library_adoption_rate_pct": library_rate,
        },
        "dataset_coverage": {
            "total_books": total_books_in_df,
            "genre_coverage_pct": genre_coverage,
            "emotion_coverage_pct": emotion_coverage,
            "sentiment_coverage_pct": sentiment_coverage,
        },
        "top_searched_books": top_searches,
        "event_breakdown": event_breakdown,
    }), 200


# -----------------------
# 📊 ADMIN: ENGAGEMENT ANALYTICS
# -----------------------
@app.route("/admin/analytics/engagement", methods=["GET"])
def admin_engagement_analytics():
    ok, err = require_admin()
    if err:
        return err

    from datetime import timedelta

    # Daily active users (last 14 days)
    days = 14
    now = datetime.utcnow()
    daily_stats = []

    for i in range(days - 1, -1, -1):
        day_start = (now - timedelta(days=i)).replace(hour=0, minute=0, second=0, microsecond=0)
        day_end = day_start + timedelta(days=1)

        active_users = len(events_collection.distinct("user_id", {
            "created_at": {"$gte": day_start, "$lt": day_end}
        }))
        event_count = events_collection.count_documents({
            "created_at": {"$gte": day_start, "$lt": day_end}
        })
        new_users = users_collection.count_documents({
            "created_at": {"$gte": day_start, "$lt": day_end}
        })

        daily_stats.append({
            "date": day_start.strftime("%Y-%m-%d"),
            "active_users": active_users,
            "events": event_count,
            "new_users": new_users,
        })

    # Most active users
    user_activity_pipeline = [
        {"$group": {"_id": "$user_id", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 10},
    ]
    top_users_raw = list(events_collection.aggregate(user_activity_pipeline))
    top_users = []
    for u in top_users_raw:
        uid = u["_id"]
        user_doc = users_collection.find_one({"_id": ObjectId(uid)} if len(uid) == 24 else {"_id": uid}, {"username": 1, "email": 1})
        top_users.append({
            "user_id": uid,
            "username": user_doc.get("username") if user_doc else "Unknown",
            "event_count": u["count"],
        })

    # Overall totals
    total_events = events_collection.count_documents({})
    total_users = users_collection.count_documents({})
    total_posts = posts_collection.count_documents({})
    total_reviews = reviews_collection.count_documents({})

    return jsonify({
        "overview": {
            "total_users": total_users,
            "total_events": total_events,
            "total_posts": total_posts,
            "total_reviews": total_reviews,
        },
        "daily_stats": daily_stats,
        "top_active_users": top_users,
    }), 200


# -----------------------
# START SERVER
# -----------------------
if __name__ == "__main__":
    app.run(debug=True)