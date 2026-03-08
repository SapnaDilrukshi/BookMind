# BookMind
Intelligent Book Recommendation System for a Personalized Experience Using Machine Learning

📚 BookMind
An AI-powered book recommendation and community platform built with Flutter (frontend) and Python/Flask (backend).

⚠️ Important: Missing Files (Not in Repository)
ML Model Files (/models/)
The following large model files are excluded from this repository due to GitHub file size limits:
book_embeddings.npy - Book vector embeddings
content_sim.npy     - Content similarity matrix
cf_model.pkl        - Collaborative filtering model
emotion_classifier.pkl - Emotion classification model
index_map.pkl        -Book index mapping 
kmeans_genre_model.pkl - Genre clustering model 
pivot_table.pkl    - User-book pivot table
tfidf.pkl     - TF-IDF vectorizer

To regenerate these models, run the training scripts (see Setup below).


Large Data Files
The following CSV files exceed GitHub's recommended 50MB limit but are included with a warning:

* data/books_cleaned.csv (~90 MB)
* data/books_with_descriptions.csv (~70 MB)

Virtual Environments
.venv/ folders are excluded. Recreate them using the setup instructions below.



🛠️ Tech Stack
Frontend: Flutter (Dart) —  web Application
Backend: Python, Flask
Database: MongoDB (via db.py)
AI/ML: scikit-learn, NumPy, TF-IDF, KMeans, Collaborative Filtering


📌 Notes
Make sure to create a .env file in the backend with your environment variables (MongoDB URI, secret keys, etc.)
Model files must be generated before running AI features
.venv/ and __pycache__/ are gitignored — do not commit them
