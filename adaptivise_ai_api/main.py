import os
import io
import re
import random
import traceback
import logging
import numpy as np
import PyPDF2
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from sumy.parsers.plaintext import PlaintextParser
from sumy.nlp.tokenizers import Tokenizer
from sumy.summarizers.text_rank import TextRankSummarizer
from rank_bm25 import BM25Okapi
from supabase import create_client, Client
from docx import Document 
from pptx import Presentation
import uvicorn
from dotenv import load_dotenv
import nltk
import httpx
from html.parser import HTMLParser

def _ensure_nltk_data():
    """Download NLTK data to a writable path (required on Cloud Run)."""
    nltk_dirs = [
        os.environ.get("NLTK_DATA", ""),
        "/usr/local/share/nltk_data",
        "/tmp/nltk_data",
    ]
    for path in nltk_dirs:
        if path:
            os.makedirs(path, exist_ok=True)
            if path not in nltk.data.path:
                nltk.data.path.insert(0, path)

    for package in ("punkt", "punkt_tab", "stopwords"):
        try:
            if package in ("punkt", "punkt_tab"):
                nltk.data.find(f"tokenizers/{package}")
            else:
                nltk.data.find(f"corpora/{package}")
        except LookupError:
            download_dir = next(
                (d for d in nltk_dirs if d and os.path.isdir(d)),
                "/tmp/nltk_data",
            )
            os.makedirs(download_dir, exist_ok=True)
            print(f"Downloading NLTK package: {package}")
            nltk.download(package, download_dir=download_dir)

logging.basicConfig(level=logging.INFO)
load_dotenv()

app = FastAPI(title="Adaptivise AI Engine")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allows browser to talk to the server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SUPABASE_URL = os.getenv("SUPABASE_URL", "https://nnqafyfydbpspywuxhtk.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_KEY", "")
supabase: Optional[Client] = None
if SUPABASE_KEY:
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

_STOPWORDS = {
    "about", "after", "also", "been", "being", "between", "could", "each",
    "from", "have", "into", "more", "other", "such", "than", "that", "their",
    "them", "then", "there", "these", "they", "this", "those", "through",
    "under", "very", "were", "what", "when", "where", "which", "while",
    "with", "would", "your",
}


def generate_distractors(answer, all_sentences, count=3):
    pool = [
        s for s in all_sentences
        if s.strip().lower() != answer.strip().lower() and len(s) > 10
    ]
    if len(pool) <= count:
        return pool
    return random.sample(pool, count)

def _fallback_quiz():
    """Provides a safe fallback question if the text is unreadable or too short."""
    return [{
        "question": "Review the uploaded material to understand the core concepts.",
        "answer": "Understood the material.",
        "options": [
            "Understood the material.",
            "I need to read it again.",
            "The material was too complex.",
            "None of the above."
        ]
    }]


def generate_semantic_quiz(text: str, max_questions: int = 5) -> list:
    """
    Semantic question generation using BM25 sentence ranking.
    Includes chunking fallbacks for PDFs with bad punctuation.
    """
    try:
        cleaned = " ".join(text.split())
        if len(cleaned) < 15:
            return _fallback_quiz()

        # Try to split by punctuation
        sentences = [
            s.strip() for s in re.split(r"(?<=[.!?]) +", cleaned)
            if len(s.strip()) > 12
        ]

        # FIX: If no punctuation was found, artificially chunk the text!
        if len(sentences) == 0:
            sentences = [cleaned[i:i+120] for i in range(0, len(cleaned), 120) if len(cleaned[i:i+120]) > 12]

        if len(sentences) == 1:
            sentence = sentences[0][:150] + "..." if len(sentences[0]) > 150 else sentences[0]
            return [{
                "question": "Which statement best matches the material?",
                "answer": sentence,
                "options": [
                    sentence,
                    "This topic is unrelated to the uploaded material.",
                    "The material contradicts this statement.",
                    "None of the above."
                ],
            }]

        tokenized = [s.lower().split() for s in sentences if s.strip()]
        if not tokenized:
            return _fallback_quiz()

        bm25 = BM25Okapi(tokenized)
        scores = list(bm25.get_scores(cleaned.lower().split()))
        ranked = sorted(range(len(sentences)), key=lambda i: scores[i], reverse=True)
        selected = ranked[: min(max_questions, len(ranked))]

        quiz = []
        for idx in selected:
            sentence = sentences[idx]
            keywords = [
                w for w in re.findall(r"\b[A-Za-z]{4,}\b", sentence)
                if w.lower() not in _STOPWORDS
            ]

            if keywords:
                key_term = max(keywords, key=len)
                question = f"According to the material, which statement is correct about '{key_term}'?"
            else:
                question = "According to the material, which statement is correct?"

            answer = sentence
            distractor_pool = [
                sentences[i] for i in ranked
                if i != idx and sentences[i].strip().lower() != answer.strip().lower()
            ]
            
            distractors = generate_distractors(answer, distractor_pool, count=3)
            if len(distractors) < 3:
                distractors.extend([
                    "This statement is unrelated to the uploaded material.",
                    "The material contradicts this statement.",
                    "None of the above apply.",
                ])
                
            options = list(dict.fromkeys([answer] + distractors))[:4]
            random.shuffle(options)

            quiz.append({
                "question": question,
                "answer": answer,
                "options": options,
            })

        return quiz if quiz else _fallback_quiz()

    except Exception as e:
        print(f"======== CRITICAL ERROR IN SEMANTIC QUIZ: {e} ========")
        traceback.print_exc()
        return _fallback_quiz()

def extract_text_from_pptx(content: bytes) -> str:
    text_runs = []
    # Load the presentation from memory
    prs = Presentation(io.BytesIO(content))
    
    for slide_index, slide in enumerate(prs.slides):
        for shape in slide.shapes:
            if hasattr(shape, "text") and shape.text.strip():
                # We add a space to prevent words from sticking together
                text_runs.append(shape.text.strip())
                
    # Joining with newlines helps the TextRank parser see sentence boundaries
    return "\n".join(text_runs)

def extract_text_from_file(content: bytes, filename: str) -> str:
    text = ""
    file_extension = filename.split('.')[-1].lower()

    # 1. Handle PDF
    if file_extension == 'pdf':
        pdf_reader = PyPDF2.PdfReader(io.BytesIO(content))
        for page in pdf_reader.pages:
            text += page.extract_text() or ""

    # 2. Handle WORD (.docx)
    elif file_extension == 'docx':
        doc = Document(io.BytesIO(content))
        text = "\n".join([para.text for para in doc.paragraphs])

    # 3. Handle POWERPOINT (.pptx)
    elif file_extension == 'pptx':
        text = extract_text_from_pptx(content)

    # 4. Handle plain text
    elif file_extension == 'txt':
        text = content.decode("utf-8", errors="replace")

    return text

class _HTMLTextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self._parts = []

    def handle_data(self, data):
        text = data.strip()
        if text:
            self._parts.append(text)

    def get_text(self):
        return " ".join(self._parts)


def extract_text_from_html(content: bytes) -> str:
    html = content.decode("utf-8", errors="replace")
    parser = _HTMLTextExtractor()
    parser.feed(html)
    return parser.get_text()


def extract_text_from_url(url: str) -> str:
    with httpx.Client(timeout=20.0, follow_redirects=True) as client:
        response = client.get(url)
        response.raise_for_status()
        content_type = response.headers.get("content-type", "").lower()
        if "html" in content_type or url.lower().endswith((".html", ".htm")):
            return extract_text_from_html(response.content)
        return response.text

def simple_summarize(text_input: str, num_sentences=3):
    """A lightweight summarizer based on word frequency."""
    # Split into sentences based on punctuation
    sentences = re.split(r'(?<=[.!?]) +', text_input)
    if len(sentences) <= num_sentences:
        return text_input
        
    # Count word frequency (ignoring very short words)
    words = [w.lower() for w in re.findall(r'\w+', text_input.lower()) if len(w) > 3]
    freq = {}
    for w in words:
        freq[w] = freq.get(w, 0) + 1
        
    # Score sentences by word frequency
    scores = []
    for s in sentences:
        s_words = re.findall(r'\w+', s.lower())
        score = sum(freq.get(w, 0) for w in s_words if len(w) > 3)
        scores.append(score)
        
    # Pick top sentences, keeping them in chronological order
    indices = np.argsort(scores)[-num_sentences:]
    indices.sort()
    return " ".join([sentences[i] for i in indices])

# --- 2. DEFINE DATA MODELS ---
class NotesRequest(BaseModel):
    text: str

class VarkScores(BaseModel):
    scores: List[int]

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.post("/ai/process-note")
async def process_note(
    file: UploadFile = File(...),
    user_id: str = Form(...),
    storage_path: str = Form(...),
    folder_id: str = Form(None),
):
    """Extract text and summarize. The Flutter app saves results to Supabase."""
    logging.info("Processing started for file: %s", file.filename)
    try:
        content = await file.read()
        logging.info("File read successfully (%d bytes).", len(content))
        raw_text = extract_text_from_file(content, file.filename)
        logging.info("Text extracted, length: %d", len(raw_text))

        if not raw_text.strip():
            raise HTTPException(status_code=400, detail="Could not extract text from file.")

        cleaned_text = " ".join(raw_text.split())
        summary_text = simple_summarize(cleaned_text)
        quiz_content = generate_semantic_quiz(cleaned_text)

        response = {
            "status": "success",
            "user_id": user_id,
            "storage_path": storage_path,
            "file_name": file.filename,
            "raw_text": cleaned_text,
            "summary": summary_text,
            "quiz_content": quiz_content,
        }
        if folder_id:
            response["folder_id"] = folder_id

        return response

    except HTTPException:
        raise
    except Exception as e:
        error_trace = traceback.format_exc()
        logging.error("CRASHED during processing: %s", error_trace)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/ai/process-url")
async def process_url(
    url: str = Form(...),
    user_id: str = Form(...),
    storage_path: str = Form(...),
    folder_id: str = Form(None),
):
    """Fetch a web page and generate adaptive study content."""
    logging.info("Processing URL: %s", url)
    try:
        raw_text = extract_text_from_url(url.strip())
        if not raw_text.strip():
            raise HTTPException(status_code=400, detail="Could not extract text from URL.")

        cleaned_text = " ".join(raw_text.split())
        summary_text = simple_summarize(cleaned_text)
        quiz_content = generate_semantic_quiz(cleaned_text)

        response = {
            "status": "success",
            "user_id": user_id,
            "storage_path": storage_path,
            "file_name": url.split("/")[-1] or "web-page.html",
            "raw_text": cleaned_text,
            "summary": summary_text,
            "quiz_content": quiz_content,
        }
        if folder_id:
            response["folder_id"] = folder_id
        return response
    except HTTPException:
        raise
    except Exception as e:
        logging.error("URL processing failed: %s", traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/ai/summarize")
async def summarize_notes(request: NotesRequest):
    try:
        _ensure_nltk_data()
        cleaned_text = " ".join(request.text.split())
        parser = PlaintextParser.from_string(cleaned_text, Tokenizer("english"))
        sentences = parser.document.sentences
        
        # 1. Prepare BM25
        sentence_list = [str(s) for s in sentences]
        tokenized_corpus = [s.split(" ") for s in sentence_list]
        bm25 = BM25Okapi(tokenized_corpus)
        
        # Get BM25 scores (Relevance of sentence to the whole document)
        bm25_raw_scores = bm25.get_scores(cleaned_text.split(" "))
        # Normalize BM25 to 0-1
        max_bm25 = max(bm25_raw_scores) if max(bm25_raw_scores) > 0 else 1
        norm_bm25 = [score / max_bm25 for score in bm25_raw_scores]
        
        # 2. Get TextRank Scores
        summarizer = TextRankSummarizer()
        tr_scores_dict = summarizer.rate_sentences(parser.document)
        # Normalize TextRank to 0-1
        max_tr = max(tr_scores_dict.values()) if tr_scores_dict.values() else 1

        # 3. Apply Hybrid Scoring: (TR * 0.5) + (BM25 * 0.5)
        hybrid_scored_list = []
        for i, sentence in enumerate(sentences):
            tr_score = tr_scores_dict.get(sentence, 0) / max_tr
            bm25_score = norm_bm25[i]
            
            final_score = (tr_score * 0.5) + (bm25_score * 0.5)
            hybrid_scored_list.append((sentence, final_score))
        
        # 4. Final Selection
        # Sort by hybrid score (highest first)
        hybrid_scored_list.sort(key=lambda x: x[1], reverse=True)
        
        summary_length = max(1, int(len(sentences) * 0.3))
        top_sentences = hybrid_scored_list[:summary_length]
        
        # Sort back to original sentence order for readability
        top_sentences.sort(key=lambda x: sentences.index(x[0]))
        
        summary_text = " ".join([str(s[0]) for s in top_sentences])

        return {
            "summary": summary_text,
            "bm25_relevance_peak": max(bm25_raw_scores) if len(bm25_raw_scores) > 0 else 0,
            "keywords": [] 
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/ai/generate-quiz")
async def generate_quiz(request: NotesRequest):
    """Semantic question generation for kinesthetic learners (BM25-based)."""
    try:
        cleaned_text = " ".join(request.text.split())
        #guarantees an array is returned, never crashing!
        return {"quiz_content": generate_semantic_quiz(cleaned_text)}
    except Exception as e:
        print("======== FASTAPI ROUTE ERROR ========")
        traceback.print_exc()
        return {"quiz_content": _fallback_quiz()}

@app.post("/ai/classify-vark")
async def classify_vark(request: VarkScores):
    scores = request.scores # Expecting List[int] e.g., [6, 6, 2, 2]
    
    result = lightweight_weighted_kmeans(scores)
    detected_styles = result["learning_style"]
    
    # 2. Determine if it's a single or multimodal result for the DB
    primary_style = " & ".join(detected_styles) if len(detected_styles) > 1 else detected_styles[0]
    
    return {
        "learning_style": detected_styles, # Returns ['Visual', 'A']
        "formatted_style": primary_style   # Returns "Visual & A"
    }

def lightweight_weighted_kmeans(user_scores, threshold=1.5):
    """
    user_scores: [Visual, Auditory, Read/Write, Kinesthetic] e.g., [7, 7, 1, 1]
    Replaces sklearn KMeans with pure Euclidean distance math.
    """
    X = np.array(user_scores)
    w = np.array([1.0, 1.1, 1.0, 1.1]) # Weights
    
    # Theoretical extremes for a 16-question set
    centroids = np.array([
        [16, 0, 0, 0], # Visual-Center
        [0, 16, 0, 0], # A-Center
        [0, 0, 16, 0], # R-Center
        [0, 0, 0, 16]  # K-Center
    ])

    # Calculate Weighted Euclidean Distances to each center
    distances = [np.sqrt(np.sum(w * (X - center)**2)) for center in centroids]
    
    min_dist = min(distances)
    styles = ['Visual', 'Auditory', 'Read/Write', 'Kinesthetic']
    style_codes = ['Visual', 'Auditory', 'Read/Write', 'Kinesthetic']
    
    detected_styles = [style_codes[i] for i, d in enumerate(distances) if d <= min_dist + threshold]
    primary_style = " & ".join(detected_styles) if len(detected_styles) > 1 else detected_styles[0]
    
    return {"learning_style": detected_styles, "formatted_style": primary_style}

if __name__ == "__main__":
    # Get the port from the environment, defaulting to 8080
    port = int(os.environ.get("PORT", 8080))
    # Host must be 0.0.0.0 for Cloud Run
    uvicorn.run(app, host="0.0.0.0", port=port)