import io
import os
import PyPDF2
import docx
import nltk
from nltk.corpus import stopwords
from nltk.tokenize import sent_tokenize, word_tokenize
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.cluster import KMeans

# ==========================================
# 1. CLOUD-SAFE NLTK DOWNLOAD
# ==========================================
nltk_data_path = "/tmp/nltk_data"
os.makedirs(nltk_data_path, exist_ok=True)
nltk.data.path.append(nltk_data_path)

packages = ['punkt', 'punkt_tab', 'stopwords']
for package in packages:
    try:
        if 'punkt' in package:
            nltk.data.find(f'tokenizers/{package}')
        else:
            nltk.data.find(f'corpora/{package}')
    except LookupError:
        print(f"Downloading NLTK package: {package}...")
        nltk.download(package, download_dir=nltk_data_path, quiet=True)


# ==========================================
# 2. FILE EXTRACTION UTILITIES
# ==========================================
def extract_text(file_bytes, filename):
    """Extracts raw text from PDF, DOCX, or TXT files."""
    text = ""
    try:
        if filename.endswith(".pdf"):
            reader = PyPDF2.PdfReader(io.BytesIO(file_bytes))
            for page in reader.pages:
                if page.extract_text():
                    text += page.extract_text() + " "
        elif filename.endswith(".docx"):
            doc = docx.Document(io.BytesIO(file_bytes))
            for para in doc.paragraphs:
                text += para.text + "\n"
        elif filename.endswith(".txt"):
            text = file_bytes.decode('utf-8')
    except Exception as e:
        print(f"Error extracting text: {e}")
    
    return text.strip()


# ==========================================
# 3. TEXTRANK SUMMARIZATION LOGIC
# ==========================================
def summarize_text(text_input, num_sentences=3):
    """Summarizes text using the TextRank algorithm (TF-IDF + Cosine Similarity)."""
    if not text_input or len(text_input.strip()) == 0:
        return "No text provided to summarize."

    # Tokenize into sentences
    sentences = sent_tokenize(text_input)
    if len(sentences) <= num_sentences:
        return text_input

    # Clean sentences for TF-IDF processing
    stop_words_list = stopwords.words('english')
    clean_sentences = []
    for sentence in sentences:
        words = word_tokenize(sentence.lower())
        clean_words = [w for w in words if w.isalpha() and w not in stop_words_list]
        clean_sentences.append(" ".join(clean_words))

    # Create TF-IDF matrix
    vectorizer = TfidfVectorizer()
    try:
        tfidf_matrix = vectorizer.fit_transform(clean_sentences)
    except ValueError:
        return text_input 

    # Calculate sentence similarity matrix
    similarity_matrix = cosine_similarity(tfidf_matrix)

    # Score sentences based on similarity (PageRank logic)
    scores = np.zeros(len(sentences))
    for i in range(len(sentences)):
        for j in range(len(sentences)):
            if i != j:
                scores[i] += similarity_matrix[i][j]

    # Rank and extract top sentences
    ranked_sentence_indices = scores.argsort()[-num_sentences:][::-1]
    ranked_sentence_indices.sort() # Keep original chronological order
    
    summary = " ".join([sentences[i] for i in ranked_sentence_indices])
    return summary


# ==========================================
# 4. VARK CLASSIFICATION & K-MEANS LOGIC
# ==========================================
def process_vark_classification(text_input):
    """
    Classifies text into VARK styles using keyword analysis,
    and uses K-Means clustering to find core study topics.
    """
    if not text_input or len(text_input.strip()) == 0:
        return {"vark_style": "Unknown", "topics": [], "details": "No text provided."}

    # 1. VARK Keyword Analysis
    vark_keywords = {
        "Visual": ["see", "look", "picture", "draw", "diagram", "chart", "map", "color", "design", "observe"],
        "Auditory": ["hear", "listen", "sound", "talk", "discuss", "speak", "explain", "say", "music", "audio"],
        "Read/Write": ["read", "write", "notes", "list", "text", "book", "article", "words", "essay", "document"],
        "Kinesthetic": ["do", "feel", "touch", "build", "make", "experience", "practice", "move", "experiment", "action"]
    }

    words = word_tokenize(text_input.lower())
    clean_words = [word for word in words if word.isalpha()]
    
    scores = {"Visual": 0, "Auditory": 0, "Read/Write": 0, "Kinesthetic": 0}
    for word in clean_words:
        for style, keywords in vark_keywords.items():
            if word in keywords:
                scores[style] += 1

    # Determine dominant style
    dominant_style = max(scores, key=scores.get)
    if scores[dominant_style] == 0:
        dominant_style = "Balanced/Mixed"

    # 2. K-Means Clustering for Topic Extraction
    stop_words_list = set(stopwords.words('english'))
    meaningful_words = [w for w in clean_words if w not in stop_words_list and len(w) > 2]
    
    topics = []
    if len(set(meaningful_words)) >= 5:
        vectorizer = TfidfVectorizer()
        X = vectorizer.fit_transform(meaningful_words)
        
        # Cluster into 3 main topics
        num_clusters = min(3, len(set(meaningful_words)))
        kmeans = KMeans(n_clusters=num_clusters, random_state=42, n_init='auto')
        kmeans.fit(X)
        
        # Get top words for each cluster
        order_centroids = kmeans.cluster_centers_.argsort()[:, ::-1]
        terms = vectorizer.get_feature_names_out()
        
        for i in range(num_clusters):
            # Get top 2 words per cluster
            cluster_words = [terms[ind] for ind in order_centroids[i, :2]]
            topics.append(" & ".join(cluster_words))

    return {
        "vark_style": dominant_style,
        "style_scores": scores,
        "topics_found": topics,
        "message": "Processed successfully."
    }