import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity


class AIEngine:

    def __init__(
        self,
        books,
        pivot_table,
        content_sim,
        index_map,
        book_embeddings=None,
        embedder=None
    ):
        self.books = books.reset_index(drop=True)
        self.pivot_table = pivot_table
        self.content_sim = content_sim
        self.index_map = index_map

        # NEW
        self.book_embeddings = book_embeddings
        self.embedder = embedder

    # -------------------------------------------------
    # 1. Content-based similarity (TF-IDF)
    # -------------------------------------------------
    def get_content_similar(self, title, top_n=20):
        if title not in self.index_map:
            return []

        idx = self.index_map[title]
        sim_scores = list(enumerate(self.content_sim[idx]))
        sim_scores = sorted(sim_scores, key=lambda x: x[1], reverse=True)
        sim_scores = sim_scores[1:top_n + 1]

        return [
            self.books.iloc[i]["Book-Title"]
            for i, _ in sim_scores
            if i < len(self.books)
        ]

    # -------------------------------------------------
    # 2. Emotion-based similarity
    # -------------------------------------------------
    def get_emotion_similar(self, title, top_n=20):
        if "EmotionTags" not in self.books.columns:
            return []

        row = self.books[self.books["Book-Title"] == title]
        if row.empty:
            return []

        emotion = row.iloc[0].get("EmotionTags")
        if pd.isna(emotion) or not emotion:
            return []

        matches = self.books[self.books["EmotionTags"] == emotion]["Book-Title"].tolist()
        return matches[:top_n]

    # -------------------------------------------------
    # 3. Interest-tag similarity
    # -------------------------------------------------
    def get_interest_similar(self, title, top_n=20):
        if "InterestTags" not in self.books.columns:
            return []

        row = self.books[self.books["Book-Title"] == title]
        if row.empty:
            return []

        tags = row.iloc[0].get("InterestTags")
        if pd.isna(tags) or not tags:
            return []

        base_tags = set(t.strip().lower() for t in str(tags).split(","))

        matches = []
        # IMPORTANT: iterating 271k rows is heavy, but OK for now as baseline.
        # Later we can optimize with inverted index.
        for _, r in self.books.iterrows():
            other = r.get("InterestTags")
            if pd.isna(other) or not other:
                continue

            other_tags = set(t.strip().lower() for t in str(other).split(","))
            if base_tags.intersection(other_tags):
                matches.append(r["Book-Title"])

            if len(matches) >= top_n:
                break

        return matches[:top_n]

    # -------------------------------------------------
    # 4. NEW: Semantic similarity (USER TEXT → Embeddings)
    # -------------------------------------------------
    def get_semantic_similar(self, user_text, top_n=10):
        if self.embedder is None or self.book_embeddings is None:
            return []

        user_text = str(user_text).strip()
        if not user_text:
            return []

        user_vec = self.embedder.encode([user_text])
        sims = cosine_similarity(user_vec, self.book_embeddings)[0]

        top_idx = sims.argsort()[::-1][:top_n]
        return self.books.iloc[top_idx]["Book-Title"].tolist()

    # -------------------------------------------------
    # 5. Popular fallback
    # -------------------------------------------------
    def get_popular_books(self, top_n=10):
        return self.books["Book-Title"].head(top_n).tolist()

    # -------------------------------------------------
    # 6. FINAL RECOMMENDER
    # title-based OR user_text-based
    # -------------------------------------------------
    def recommend(self, title=None, user_text=None, top_n=10):
        scores = {}

        # ---------- USER TEXT SEARCH ----------
        if user_text:
            semantic = self.get_semantic_similar(user_text, 30)
            for i, book in enumerate(semantic):
                scores[book] = scores.get(book, 0) + (1.0 * (30 - i))

        # ---------- TITLE BASED ----------
        if title:
            cb = self.get_content_similar(title, 30)
            emo = self.get_emotion_similar(title, 20)
            intr = self.get_interest_similar(title, 20)

            for i, book in enumerate(cb):
                scores[book] = scores.get(book, 0) + (0.6 * (30 - i))

            for book in emo:
                scores[book] = scores.get(book, 0) + (0.3 * 20)

            for book in intr:
                scores[book] = scores.get(book, 0) + (0.5 * 20)

        ranked = sorted(scores.items(), key=lambda x: x[1], reverse=True)
        final = [b for b, _ in ranked if b != title]

        if final:
            return final[:top_n]

        return self.get_popular_books(top_n)
