from datetime import datetime
from bson import ObjectId


def clean(v):
    if v is None:
        return None
    v = str(v).strip()
    if v.lower() in ["nan", "none", ""]:
        return None
    return v


def oid(v):
    """Safe ObjectId conversion."""
    try:
        return ObjectId(str(v))
    except Exception:
        return None


def now():
    return datetime.utcnow()


# -----------------------
# POSTS
# -----------------------
def create_post(posts_collection, user, payload):
    text = clean(payload.get("text"))
    if not text:
        return None, ("text is required", 400)

    post = {
        "user_id": str(user["_id"]),
        "username": user.get("username", "User"),
        "text": text,
        "book_title": clean(payload.get("book_title")),
        "rating": payload.get("rating"),
        "emotion_tags": payload.get("emotion_tags", []) or [],
        "interest_tags": payload.get("interest_tags", []) or [],
        "likes_count": 0,
        "comments_count": 0,
        "created_at": now(),
        "updated_at": now(),
    }

    res = posts_collection.insert_one(post)
    post["_id"] = str(res.inserted_id)
    return post, None


def list_posts(posts_collection, post_likes_collection, current_user_id, limit=30):
    limit = max(1, min(int(limit), 100))

    cursor = posts_collection.find({}, {"_id": 1, "user_id": 1, "username": 1, "text": 1,
                                        "book_title": 1, "rating": 1,
                                        "emotion_tags": 1, "interest_tags": 1,
                                        "likes_count": 1, "comments_count": 1,
                                        "created_at": 1}).sort("created_at", -1).limit(limit)

    posts = []
    for p in cursor:
        pid = str(p["_id"])

        liked = post_likes_collection.find_one({
            "post_id": pid,
            "user_id": current_user_id
        }) is not None

        posts.append({
            "id": pid,
            "user_id": p.get("user_id"),
            "username": p.get("username"),
            "text": p.get("text"),
            "book_title": p.get("book_title"),
            "rating": p.get("rating"),
            "emotion_tags": p.get("emotion_tags", []) or [],
            "interest_tags": p.get("interest_tags", []) or [],
            "likes_count": int(p.get("likes_count", 0)),
            "comments_count": int(p.get("comments_count", 0)),
            "liked_by_me": liked,
            "created_at": p.get("created_at").isoformat() if p.get("created_at") else None
        })

    return posts


def delete_post(posts_collection, comments_collection, post_likes_collection, post_id, current_user_id):
    post_oid = oid(post_id)
    if not post_oid:
        return ("invalid post id", 400)

    post = posts_collection.find_one({"_id": post_oid})
    if not post:
        return ("post not found", 404)

    if str(post.get("user_id")) != str(current_user_id):
        return ("not allowed", 403)

    # delete post + related comments + likes
    posts_collection.delete_one({"_id": post_oid})
    comments_collection.delete_many({"post_id": str(post_oid)})
    post_likes_collection.delete_many({"post_id": str(post_oid)})

    return None


# -----------------------
# LIKES (toggle)
# -----------------------
def toggle_like(posts_collection, post_likes_collection, post_id, current_user_id):
    post_oid = oid(post_id)
    if not post_oid:
        return None, ("invalid post id", 400)

    post = posts_collection.find_one({"_id": post_oid})
    if not post:
        return None, ("post not found", 404)

    existing = post_likes_collection.find_one({
        "post_id": str(post_oid),
        "user_id": str(current_user_id)
    })

    if existing:
        post_likes_collection.delete_one({"_id": existing["_id"]})
        posts_collection.update_one({"_id": post_oid}, {"$inc": {"likes_count": -1}})
        post = posts_collection.find_one({"_id": post_oid})
        return {
            "liked": False,
            "likes_count": int(post.get("likes_count", 0))
        }, None

    post_likes_collection.insert_one({
        "post_id": str(post_oid),
        "user_id": str(current_user_id),
        "created_at": now()
    })
    posts_collection.update_one({"_id": post_oid}, {"$inc": {"likes_count": 1}})
    post = posts_collection.find_one({"_id": post_oid})
    return {
        "liked": True,
        "likes_count": int(post.get("likes_count", 0))
    }, None


# -----------------------
# COMMENTS
# -----------------------
def list_comments(comments_collection, post_id, limit=100):
    post_oid = oid(post_id)
    if not post_oid:
        return None, ("invalid post id", 400)

    limit = max(1, min(int(limit), 200))

    cursor = comments_collection.find(
        {"post_id": str(post_oid)},
        {"_id": 1, "user_id": 1, "username": 1, "text": 1, "created_at": 1},
    ).sort("created_at", 1).limit(limit)

    items = []
    for c in cursor:
        items.append({
            "id": str(c["_id"]),
            "user_id": c.get("user_id"),
            "username": c.get("username"),
            "text": c.get("text"),
            "created_at": c.get("created_at").isoformat() if c.get("created_at") else None
        })
    return items, None


def add_comment(posts_collection, comments_collection, post_id, user, payload):
    post_oid = oid(post_id)
    if not post_oid:
        return None, ("invalid post id", 400)

    post = posts_collection.find_one({"_id": post_oid})
    if not post:
        return None, ("post not found", 404)

    text = clean(payload.get("text"))
    if not text:
        return None, ("text is required", 400)

    comment = {
        "post_id": str(post_oid),
        "user_id": str(user["_id"]),
        "username": user.get("username", "User"),
        "text": text,
        "created_at": now(),
    }

    res = comments_collection.insert_one(comment)
    posts_collection.update_one({"_id": post_oid}, {"$inc": {"comments_count": 1}})
    comment["_id"] = str(res.inserted_id)
    return comment, None


def delete_comment(posts_collection, comments_collection, comment_id, current_user_id):
    comment_oid = oid(comment_id)
    if not comment_oid:
        return ("invalid comment id", 400)

    comment = comments_collection.find_one({"_id": comment_oid})
    if not comment:
        return ("comment not found", 404)

    if str(comment.get("user_id")) != str(current_user_id):
        return ("not allowed", 403)

    comments_collection.delete_one({"_id": comment_oid})

    # decrease counter safely
    post_oid = oid(comment.get("post_id"))
    if post_oid:
        posts_collection.update_one({"_id": post_oid}, {"$inc": {"comments_count": -1}})

    return None
