import re
import logging
import pickle
import pytesseract
import pdfplumber
from PIL import Image
from PyPDF2 import PdfReader
import docx
import spacy
import json

# Load models and config
nlp = spacy.load("en_core_web_sm")

with open('models/rf_classifier_categorization.pkl', 'rb') as f:
    rf_classifier_categorization = pickle.load(f)

with open('models/tfidf_vectorizer_categorization.pkl', 'rb') as f:
    tfidf_vectorizer_categorization = pickle.load(f)

with open('skills.json') as f:
    cached_skills = set(json.load(f))

logging.basicConfig(level=logging.INFO)

def clean_text(text):
    text = re.sub(r"[\r\f]+", " ", text)
    text = re.sub(r"[\u2013\u2014]", "-", text)
    text = re.sub(r"[\u2018\u2019\u201c\u201d]", '"', text)
    text = re.sub(r"[^\x00-\x7F]+", " ", text)
    text = re.sub(r"[\n\r]+", "\n", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()

def extract_text_from_pdf(file):
    try:
        reader = PdfReader(file)
        text = ''.join(page.extract_text() or '' for page in reader.pages)
        return clean_text(text) if text else extract_text_from_pdf_with_ocr(file)
    except Exception as e:
        logging.error(f"Error extracting PDF text: {e}")
        return extract_text_from_pdf_with_ocr(file)

def extract_text_from_pdf_with_ocr(file):
    try:
        file.seek(0)
        with pdfplumber.open(file) as pdf:
            text = ''.join([
                pytesseract.image_to_string(Image.fromarray(page.to_image().original))
                for page in pdf.pages
            ])
        return clean_text(text)
    except Exception as e:
        logging.error(f"OCR error: {e}")
        return ""

def extract_text_from_docx(file):
    try:
        doc = docx.Document(file)
        return clean_text('\n'.join([para.text for para in doc.paragraphs]))
    except Exception as e:
        logging.error(f"Error extracting DOCX text: {e}")
        return ""

def extract_contact(text):
    phone_regex = re.compile(r"\b(?:\+\d{1,3}[- ]?)?(?:\(?\d{2,4}\)?[- ]?)?\d{3,5}[- ]?\d{4,5}\b")
    email_regex = re.compile(r"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+")
    phone = phone_regex.findall(text)
    email = email_regex.findall(text)
    return phone[0] if phone else None, email[0] if email else None

def extract_name(text):
    lines = text.split("\n")[:5]
    name_regex = re.compile(r"([A-Z][a-zA-Z]+ [A-Z][a-zA-Z]+)")
    for line in lines:
        match = name_regex.search(line)
        if match:
            return match.group(0)
    return "Unknown"

def extract_skills(text, required_skills=None):
    text_lower = text.lower()
    found_skills = set()
    if required_skills:
        for skill in required_skills:
            if skill.lower() in text_lower:
                found_skills.add(skill)
    for skill in cached_skills:
        if skill.lower() in text_lower:
            found_skills.add(skill)
    return list(found_skills)

def rank_resume(extracted_skills, required_skills):
    matched_skills = set(required_skills).intersection(set(extracted_skills))
    match_percentage = (len(matched_skills) / len(required_skills)) * 100 if required_skills else 0
    return list(matched_skills), round(match_percentage, 2)

def categorize_text(text):
    cleaned = clean_text(text)
    vectorized = tfidf_vectorizer_categorization.transform([cleaned])
    return rf_classifier_categorization.predict(vectorized)[0]
