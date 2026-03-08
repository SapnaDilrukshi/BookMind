import os
import pickle
import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.abspath(os.path.join(BASE_DIR, ".."))

def load_models():
    models = {}

    models["books"] = pd.read_csv(
        os.path.join(PROJECT_DIR, "data", "books_cleaned.csv"),
        low_memory=False
    )

    # LOAD SENTENCE EMBEDDINGS
    models["book_embeddings"] = np.load(
        os.path.join(PROJECT_DIR, "models", "book_embeddings.npy")
    )

    with open(os.path.join(PROJECT_DIR, "models", "tfidf.pkl"), "rb") as f:
        models["tfidf"] = pickle.load(f)

    models["content_sim"] = np.load(
        os.path.join(PROJECT_DIR, "models", "content_sim.npy")
    )

    with open(os.path.join(PROJECT_DIR, "models", "pivot_table.pkl"), "rb") as f:
        models["pivot_table"] = pickle.load(f)

    with open(os.path.join(PROJECT_DIR, "models", "index_map.pkl"), "rb") as f:
        models["index_map"] = pickle.load(f)

    models["embedder"] = SentenceTransformer("all-MiniLM-L6-v2")

    print("✅ books:", models["books"].shape)
    print("✅ embeddings:", models["book_embeddings"].shape)

    return models
