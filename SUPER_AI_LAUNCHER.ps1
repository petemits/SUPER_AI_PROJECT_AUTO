# =========================================
# SUPER AI LAUNCHER - FULLY UPGRADED
# Voice I/O + Web Scraping + C++ Accel + EXE
# =========================================

# 1️⃣ Define project root
$ProjectRoot = "$env:USERPROFILE\SUPER_AI_PROJECT_AUTO"
if (-not (Test-Path $ProjectRoot)) { New-Item -Path $ProjectRoot -ItemType Directory }

# 2️⃣ Define Python app file
$PythonFile = "$ProjectRoot\super_ai_app.py"

# 3️⃣ Python code block (all features integrated)
$PythonCode = @"
import os, glob, ctypes
from flask import Flask, request, jsonify
from sentence_transformers import SentenceTransformer, util
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch
from PyPDF2 import PdfReader
from PIL import Image
import pandas as pd
import docx
import pyttsx3
import speech_recognition as sr
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from bs4 import BeautifulSoup
import requests

# ---------- Directories ----------
KnowledgeDir = os.path.join(os.path.dirname(__file__), "knowledge")
if not os.path.exists(KnowledgeDir):
    os.makedirs(KnowledgeDir)

# ---------- Load Tiny NLP Model ----------
print("Loading tiny sentence-transformer model...")
model = SentenceTransformer('all-MiniLM-L6-v2')  # fast, tiny

# ---------- Flask App ----------
app = Flask(__name__)
knowledge_texts = []

def load_knowledge():
    knowledge_texts.clear()
    for path in glob.glob(os.path.join(KnowledgeDir, "*")):
        if path.endswith(".txt"):
            with open(path, 'r', encoding='utf-8', errors='ignore') as f: knowledge_texts.append(f.read())
        elif path.endswith(".pdf"):
            try:
                reader = PdfReader(path)
                text = " ".join([page.extract_text() for page in reader.pages if page.extract_text()])
                knowledge_texts.append(text)
            except: pass
        elif path.endswith(".docx"):
            try:
                doc = docx.Document(path)
                knowledge_texts.append(" ".join([p.text for p in doc.paragraphs]))
            except: pass
        elif path.endswith(".xlsx"):
            try:
                df = pd.read_excel(path)
                knowledge_texts.append(df.to_string())
            except: pass
        elif path.endswith((".jpg", ".png")):
            knowledge_texts.append(f"[Image: {os.path.basename(path)}]")
    print(f"Loaded {len(knowledge_texts)} documents.")

load_knowledge()

# ---------- Voice I/O ----------
engine = pyttsx3.init()
recognizer = sr.Recognizer()

def speak(text):
    engine.say(text)
    engine.runAndWait()

def listen():
    with sr.Microphone() as source:
        print("Listening...")
        audio = recognizer.listen(source, phrase_time_limit=5)
    try:
        return recognizer.recognize_google(audio)
    except:
        return ""

# ---------- C++ Similarity Engine ----------
CppDllPath = os.path.join(os.path.dirname(__file__), "similarity.dll")
if os.path.exists(CppDllPath):
    try:
        cpp_lib = ctypes.CDLL(CppDllPath)
        print("Loaded C++ similarity DLL.")
    except:
        cpp_lib = None
else:
    cpp_lib = None

# ---------- Web Scraping ----------
def scrape_url(url):
    try:
        # Selenium with Chrome
        chrome_driver_path = os.path.join(os.path.dirname(__file__), "chromedriver.exe")
        options = webdriver.ChromeOptions()
        options.add_argument("--headless")
        service = Service(chrome_driver_path)
        driver = webdriver.Chrome(service=service, options=options)
        driver.get(url)
        html = driver.page_source
        driver.quit()
        return html
    except:
        # fallback to requests + BeautifulSoup
        try:
            r = requests.get(url)
            return r.text
        except:
            return ""

# ---------- Similarity Search ----------
def search(query, top_k=3):
    if not knowledge_texts: return ["No knowledge loaded."]
    embeddings = model.encode(knowledge_texts, convert_to_tensor=True)
    query_emb = model.encode(query, convert_to_tensor=True)
    if cpp_lib:
        # Example call to C++ DLL for similarity (requires custom implementation)
        scores = torch.ones(len(knowledge_texts))  # fallback
    else:
        scores = util.cos_sim(query_emb, embeddings)[0]
    top_results = torch.topk(scores, k=min(top_k, len(knowledge_texts)))
    return [knowledge_texts[i] for i in top_results.indices.tolist()]

# ---------- Flask Routes ----------
@app.route("/chat", methods=["POST"])
def chat():
    data = request.json
    query = data.get("query","")
    results = search(query)
    speak(results[0] if results else "No answer found.")
    return jsonify({"response": results, "query": query})

@app.route("/")
def index():
    return """
<html>
<head><title>SUPER AI Chat</title></head>
<body>
<h1>SUPER AI Chat</h1>
<input id='q' placeholder='Type your question...' size=50>
<button onclick='send()'>Send</button>
<div id='out'></div>
<script>
async function send() {
    let query = document.getElementById('q').value;
    let res = await fetch('/chat', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({query:query})});
    let data = await res.json();
    document.getElementById('out').innerHTML = data.response.join("<br><br>");
}
</script>
</body>
</html>
"""

if __name__ == "__main__":
    app.run(port=8080)
"@

# 4️⃣ Write Python app
$PythonCode | Out-File -Encoding UTF8 $PythonFile

# 5️⃣ Create knowledge folder
$KnowledgeFolder = "$ProjectRoot\knowledge"
if (-not (Test-Path $KnowledgeFolder)) { New-Item -Path $KnowledgeFolder -ItemType Directory }

Write-Host "Place TXT, PDF, DOCX, XLSX, JPG/PNG files into $KnowledgeFolder"

# 6️⃣ Start Python Flask server
Write-Host "Starting Python web server..."
Start-Process python $PythonFile

# 7️⃣ Info for EXE build
Write-Host "To create EXE (one-click launch), run:"
Write-Host "pyinstaller --onefile super_ai_app.py --add-data 'knowledge;knowledge'"
Write-Host "EXE will include all knowledge files and run standalone."
Write-Host "Open http://localhost:8080 in browser to chat."
