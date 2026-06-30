import pickle
import numpy as np
import pandas as pd
import re
import os
import json
import time
import uuid
from datetime import datetime, timezone
from typing import Optional
from enum import Enum

from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.metrics.pairwise import cosine_similarity as sk_cosine
from rapidfuzz import process, fuzz

# ==================================================
# LOAD ARTIFACTS
# ==================================================

print("Loading artifacts...")
t0 = time.time()

df = pd.read_pickle("artifacts/data.pkl")

if "combined_features" in df.columns:
    df.drop(columns=["combined_features"], inplace=True)

with open("artifacts/tfidf_matrix.pkl", "rb") as f:
    tfidf_matrix = pickle.load(f)

embeddings_raw  = np.load("artifacts/embeddings.npy", mmap_mode="r")
norms           = np.linalg.norm(embeddings_raw, axis=1, keepdims=True)
embeddings_norm = (embeddings_raw / np.maximum(norms, 1e-8)).astype(np.float32)

with open("artifacts/title_to_index.pkl", "rb") as f:
    title_to_index = pickle.load(f)

with open("artifacts/alias_map.pkl", "rb") as f:
    alias_map = pickle.load(f)

with open("artifacts/joined_title_map.pkl", "rb") as f:
    joined_title_map = pickle.load(f)

# ==================================================
# PRE-CACHE
# ==================================================

titles_list     = df["title"].tolist()
clean_titles    = df["clean_title"].tolist()
genres_list     = df["genres"].tolist()
types_list      = df["content_type"].tolist()
popularity_arr  = np.array(df["popularity"].tolist(), dtype=np.float32)
popularity_norm = popularity_arr / popularity_arr.max()

content_type_counts = df["content_type"].value_counts().to_dict()

VALID_CONTENT_TYPES = {"anime", "kdrama", "bollywood", "indian_cinema", "movie", "tv", "any"}

RELATED_TYPES = {
    "indian_cinema": "bollywood",
    "bollywood":     "indian_cinema",
    "anime":         "tv",
    "kdrama":        "tv",
    "movie":         "tv",
    "tv":            "movie",
}

print(f"Artifacts loaded in {time.time()-t0:.1f}s")
print(f"Dataset: {len(df):,} items | {content_type_counts}")

# ==================================================
# TEXT HELPERS
# ==================================================

_CLEAN_RE1 = re.compile(r"[^a-zA-Z0-9\s]")
_CLEAN_RE2 = re.compile(r"\s+")
_DIGIT_RE  = re.compile(r"\d+")
_STOP      = {"movie", "film", "show", "series", "tv", "anime", "season"}

_GENRE_PATTERNS = [
    (re.compile(r"sci-fi & fantasy",   re.I), "scifi fantasy"),
    (re.compile(r"science fiction",    re.I), "scifi"),
    (re.compile(r"sci-fi",             re.I), "scifi"),
    (re.compile(r"action & adventure", re.I), "action adventure"),
    (re.compile(r"mystery & thriller", re.I), "mystery thriller"),
    (re.compile(r"crime & mystery",    re.I), "crime mystery"),
    (re.compile(r"war & politics",     re.I), "war politics"),
    (re.compile(r"talk show",          re.I), "talkshow"),
    (re.compile(r"reality tv",         re.I), "realitytv"),
    (re.compile(r"tv movie",           re.I), "tvmovie"),
]

def _normalize_genres(genre_str):
    g = str(genre_str)
    for pattern, replacement in _GENRE_PATTERNS:
        g = pattern.sub(replacement, g)
    g = _CLEAN_RE1.sub(" ", g)
    g = _CLEAN_RE2.sub(" ", g).strip().lower()
    return g

def clean_text(text):
    if not isinstance(text, str):
        return ""
    text = text.lower()
    text = _CLEAN_RE1.sub(" ", text)
    text = _CLEAN_RE2.sub(" ", text)
    return text.strip()

def preprocess_query(query):
    query = clean_text(query)
    query = _DIGIT_RE.sub("", query)
    query = _CLEAN_RE2.sub(" ", query).strip()
    tokens = [t for t in query.split() if t not in _STOP]
    return " ".join(tokens)

# Build genre frozensets with normalization
genre_sets = [frozenset(_normalize_genres(g).split()) for g in genres_list]

# ==================================================
# TITLE RESOLUTION
# ==================================================

def _length_penalized_score(query, candidate, raw_score):
    len_ratio = len(query) / max(len(candidate), 1)
    if len_ratio < 0.6:
        return raw_score * len_ratio
    return raw_score

def resolve_title(user_input):
    user_input = preprocess_query(user_input)
    if not user_input:
        return None
    tokens = set(user_input.split())

    # 1. Space correction O(1)
    corrected = joined_title_map.get(user_input.replace(" ", ""))
    if corrected:
        return title_to_index[corrected]

    # 2. Alias lookup
    if user_input in alias_map:
        for alias_target in alias_map[user_input]:
            t_clean = clean_text(alias_target)
            match, score, _ = process.extractOne(
                t_clean, clean_titles, scorer=fuzz.token_set_ratio
            )
            if score >= 75:
                return title_to_index[match]

    # 3. Exact match
    if user_input in title_to_index:
        return title_to_index[user_input]

    # 4. Fuzzy with length penalty
    matches = process.extract(
        user_input, clean_titles, scorer=fuzz.token_set_ratio, limit=20
    )
    best_match, best_score = None, 0
    for match, score, _ in matches:
        if not tokens.intersection(match.split()):
            continue
        penalized = _length_penalized_score(user_input, match, score)
        if penalized >= 75 and penalized > best_score:
            best_match = match
            best_score = penalized

    if best_match:
        return title_to_index[best_match]

    return None

# ==================================================
# RECOMMENDER — 5-STEP FALLBACK CHAIN
# ==================================================

def _score_candidates(idx, candidates, input_genres, min_overlap, sbert_floor):
    if not candidates:
        return []

    sbert_scores  = embeddings_norm @ embeddings_norm[idx]
    tfidf_scores  = sk_cosine(tfidf_matrix[idx], tfidf_matrix)[0]
    hybrid_scores = (0.6 * sbert_scores) + (0.4 * tfidf_scores)

    results = []
    for i in candidates:
        if i == idx:
            continue
        if sbert_floor > 0 and sbert_scores[i] < sbert_floor:
            continue
        overlap = len(input_genres.intersection(genre_sets[i]))
        if overlap < min_overlap:
            continue
        final_score = (
            0.80 * hybrid_scores[i]   +
            0.10 * popularity_norm[i] +
            0.10 * (overlap / 5.0)
        )
        results.append((i, float(final_score), overlap))

    results.sort(key=lambda x: x[1], reverse=True)
    return results


def get_recommendations(title, content_type=None, top_k=10):
    idx = resolve_title(title)
    if idx is None:
        return None, [], -1

    if content_type is None:
        content_type = types_list[idx]

    filter_type  = (content_type != "any")
    input_genres = genre_sets[idx]
    min_overlap  = 1 if len(input_genres) <= 2 else 2

    def pool(ct):
        if ct == "any":
            return list(range(len(types_list)))
        return [i for i, t in enumerate(types_list) if t == ct]

    same_type_pool    = pool(content_type) if filter_type else pool("any")
    related_type_pool = pool(RELATED_TYPES.get(content_type, "movie"))

    # Step 1: exact type, min_overlap, SBERT >= 0.30
    results = _score_candidates(idx, same_type_pool, input_genres, min_overlap, 0.30)
    if len(results) >= 3:
        return idx, results[:top_k], 0

    # Step 2: exact type, overlap >= 1, SBERT >= 0.25
    results = _score_candidates(idx, same_type_pool, input_genres, 1, 0.25)
    if len(results) >= 3:
        return idx, results[:top_k], 1

    # Step 3: exact type, overlap >= 1, no SBERT floor
    results = _score_candidates(idx, same_type_pool, input_genres, 1, 0.0)
    if len(results) >= 3:
        return idx, results[:top_k], 2

    # Step 4: related type pool
    results = _score_candidates(idx, related_type_pool, input_genres, 1, 0.0)
    if len(results) >= 3:
        return idx, results[:top_k], 3

    # Step 5: popularity fallback — never empty
    pop_fallback = sorted(
        same_type_pool, key=lambda i: popularity_norm[i], reverse=True
    )[:top_k]
    results = [(i, float(popularity_norm[i]), 0) for i in pop_fallback if i != idx]
    return idx, results[:top_k], 4

# ==================================================
# AUTOCOMPLETE
# ==================================================

def autocomplete(query, limit=10):
    query = preprocess_query(query)
    if not query:
        return []
    matches = process.extract(
        query, clean_titles, scorer=fuzz.partial_ratio, limit=limit
    )
    return [
        {
            "title":        titles_list[idx],
            "content_type": types_list[idx],
            "score":        score,
        }
        for match, score, idx in matches
        if score > 60
    ]

# ==================================================
# FIREBASE
# ==================================================

FIREBASE_ENABLED = False
db = None

try:
    import firebase_admin
    from firebase_admin import credentials, firestore

    firebase_key_str = os.getenv("FIREBASE_KEY")
    if firebase_key_str:
        firebase_key_dict = json.loads(firebase_key_str)
        cred = credentials.Certificate(firebase_key_dict)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        FIREBASE_ENABLED = True
        print("Firebase connected.")

except Exception as e:
    print(f"Firebase disabled: {e}")

# ==================================================
# FASTAPI
# ==================================================

app = FastAPI(
    title="CineMatch API — V2",
    description="Hybrid SBERT + TF-IDF recommender. 6 content types. 5-step fallback.",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================================================
# MODELS
# ==================================================

class VoteType(str, Enum):
    up           = "up"
    down         = "down"
    not_relevant = "not_relevant"

class FeedbackRequest(BaseModel):
    user_id:           str
    query_title:       str
    query_type:        Optional[str] = None
    recommended_title: str
    recommended_rank:  int   = Field(..., ge=1, le=50)
    vote:              VoteType
    fallback_level:    int   = Field(0, ge=0, le=4)
    score:             Optional[float] = None

# ==================================================
# ROUTES
# ==================================================

@app.get("/")
def root():
    return {
        "message":       "CineMatch API V2",
        "version":       "2.0.0",
        "content_types": sorted(VALID_CONTENT_TYPES - {"any"}),
        "total_items":   len(df),
    }


@app.get("/autocomplete")
def autocomplete_api(query: str = Query(..., min_length=1)):
    return {"results": autocomplete(query)}


@app.get("/recommend")
def recommend_api(
    title:        str = Query(...),
    content_type: str = Query(None),
    user_id:      str = Query(None),
    top_k:        int = Query(10, ge=1, le=50),
):
    if content_type and content_type not in VALID_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid content_type '{content_type}'. "
                   f"Valid: {sorted(VALID_CONTENT_TYPES)}"
        )

    resolved_idx, results, fallback_level = get_recommendations(
        title, content_type, top_k
    )

    if resolved_idx is None:
        return {
            "query":          title,
            "detected_type":  None,
            "filter_applied": content_type or "auto",
            "fallback_level": -1,
            "results":        [],
            "count":          0,
        }

    if FIREBASE_ENABLED and user_id:
        try:
            db.collection("user_activity").add({
                "user_id":        user_id,
                "query":          title,
                "content_type":   content_type,
                "detected_type":  types_list[resolved_idx],
                "fallback_level": fallback_level,
                "results":        [titles_list[i] for i, _, _ in results],
                "version":        "v2",
            })
        except Exception:
            pass

    return {
        "query":          title,
        "detected_type":  types_list[resolved_idx],
        "filter_applied": content_type or "auto",
        "fallback_level": fallback_level,
        "results": [
            {
                "title":         titles_list[i],
                "type":          types_list[i],
                "score":         round(score, 4),
                "genre_overlap": overlap,
                "rank":          rank + 1,
            }
            for rank, (i, score, overlap) in enumerate(results)
        ],
        "count": len(results),
    }


@app.post("/feedback")
def feedback_api(payload: FeedbackRequest):
    if not FIREBASE_ENABLED:
        raise HTTPException(
            status_code=503,
            detail="Feedback storage not configured. Set FIREBASE_KEY env variable."
        )

    feedback_doc = {
        "feedback_id":        str(uuid.uuid4()),
        "user_id":            payload.user_id,
        "query_title":        payload.query_title,
        "query_type":         payload.query_type,
        "recommended_title":  payload.recommended_title,
        "recommended_rank":   payload.recommended_rank,
        "vote":               payload.vote.value,
        "fallback_level":     payload.fallback_level,
        "score":              payload.score,
        "timestamp":          datetime.now(timezone.utc),
        "app_version":        "v2",
    }

    try:
        db.collection("feedback").add(feedback_doc)

        # Update pair-level summary
        pair_id  = f"{clean_text(payload.query_title)}___{clean_text(payload.recommended_title)}"
        pair_ref = db.collection("feedback_summary").document(pair_id)
        pair_doc = pair_ref.get()

        if pair_doc.exists:
            data  = pair_doc.to_dict()
            data[payload.vote.value] = data.get(payload.vote.value, 0) + 1
            total = data.get("up", 0) + data.get("down", 0)
            data["quality_score"] = round(data["up"] / total, 4) if total > 0 else 0.5
            data["last_updated"]  = datetime.now(timezone.utc)
            pair_ref.set(data)
        else:
            pair_ref.set({
                "pair_id":           pair_id,
                "query_title":       payload.query_title,
                "recommended_title": payload.recommended_title,
                "up":                1 if payload.vote == VoteType.up else 0,
                "down":              1 if payload.vote == VoteType.down else 0,
                "not_relevant":      1 if payload.vote == VoteType.not_relevant else 0,
                "quality_score":     1.0 if payload.vote == VoteType.up else 0.0,
                "last_updated":      datetime.now(timezone.utc),
            })

        return {"status": "ok", "feedback_id": feedback_doc["feedback_id"]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Firebase write failed: {str(e)}")


@app.get("/content-types")
def content_types_api():
    return {"content_types": content_type_counts}


# ==================================================
# ENTRY POINT
# ==================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main_v2:app", host="0.0.0.0", port=8000, reload=False)