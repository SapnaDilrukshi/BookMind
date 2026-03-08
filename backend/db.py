# db.py
from pymongo import MongoClient
import os

MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
DB_NAME = os.getenv("DB_NAME", "bookmind")

client = MongoClient(MONGO_URI)
db = client[DB_NAME]

favorites_collection = db["favorites"]
users_collection = db["users"]
reviews_collection = db["reviews"]

posts_collection = db["posts"]
comments_collection = db["comments"]
post_likes_collection = db["post_likes"]

events_collection = db["events"]

notes_collection = db["notes"]
library_collection = db["library"]

# ✅ Defined OUTSIDE try so it's always available
admin_books_collection = db["admin_books"]

# ✅ OPTIONAL indexes (run once on startup safely)
try:
    users_collection.create_index("email", unique=True)

    favorites_collection.create_index(
        [("user_id", 1), ("book_title", 1)], unique=True
    )
    reviews_collection.create_index(
        [("user_id", 1), ("book_title", 1)], unique=True
    )

    posts_collection.create_index([("created_at", -1)])
    comments_collection.create_index([("post_id", 1), ("created_at", -1)])
    post_likes_collection.create_index(
        [("post_id", 1), ("user_id", 1)], unique=True
    )

    events_collection.create_index([("user_id", 1), ("created_at", -1)])

    notes_collection.create_index([("user_id", 1), ("created_at", -1)])
    library_collection.create_index(
        [("user_id", 1), ("status", 1), ("updated_at", -1)]
    )
    library_collection.create_index(
        [("user_id", 1), ("book_title", 1)], unique=True
    )

except Exception as e:
    print("Index create warning:", e)