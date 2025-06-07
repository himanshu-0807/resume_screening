import os
from flask import Flask, request, jsonify, send_from_directory
from resume_utils import (
    extract_text_from_pdf, extract_text_from_docx, extract_contact, extract_name,
    extract_skills, rank_resume, categorize_text, clean_text
)
import logging

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config["MAX_CONTENT_LENGTH"] = 50 * 1024 * 1024
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

@app.route('/upload', methods=['POST'])
def upload_resumes():
    if 'resumes' not in request.files:
        return jsonify({"error": "No resumes uploaded"}), 400

    resumes = request.files.getlist('resumes')
    required_skills = request.form.get('skills', "").split(',')
    required_skills = [skill.strip().lower() for skill in required_skills if skill.strip()]

    results = []

    for resume in resumes:
        resume.stream.seek(0)
        resume_filename = os.path.join(app.config['UPLOAD_FOLDER'], resume.filename)
        resume.save(resume_filename)

        if resume.filename.endswith('.pdf'):
            text = extract_text_from_pdf(resume.stream)
        elif resume.filename.endswith('.docx'):
            text = extract_text_from_docx(resume)
        else:
            return jsonify({"error": f"Unsupported file type: {resume.filename}"}), 400

        phone, email = extract_contact(text)
        extracted_skills = extract_skills(text, required_skills)
        matched_skills, match_percentage = rank_resume(extracted_skills, required_skills)
        category = categorize_text(text)

        results.append({
            "name": extract_name(text),
            "resume": resume.filename,
            "phone": phone,
            "email": email,
            "matched_skills": matched_skills,
            "match_percentage": match_percentage,
            "category": category,
            "resume_url": f'/resume/{resume.filename}'
        })

    results = sorted(results, key=lambda x: x["match_percentage"], reverse=True)
    return jsonify({"ranked_resumes": results})

@app.route('/resume/<filename>', methods=['GET'])
def view_resume(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/pred', methods=['POST'])
def extract_details():
    if 'resume' not in request.files:
        return jsonify({"error": "No resume file uploaded"}), 400

    resume = request.files['resume']
    skills = request.form.get('skills', '').split(',')
    skills = [s.strip().lower() for s in skills if s.strip()]

    resume.stream.seek(0)
    if resume.filename.endswith('.pdf'):
        text = extract_text_from_pdf(resume.stream)
    elif resume.filename.endswith('.docx'):
        text = extract_text_from_docx(resume)
    else:
        return jsonify({"error": f"Unsupported file type: {resume.filename}"}), 400

    phone, email = extract_contact(text)
    extracted_skills = extract_skills(text, skills)
    category = categorize_text(text)

    return jsonify({
        "name": extract_name(text),
        "email": email,
        "phone": phone,
        "skills": extracted_skills,
        "category": category,
        "resume_url": f'/resume/{resume.filename}'
    })

@app.route('/categorize', methods=['POST'])
def categorize_resume():
    if 'resume' not in request.files:
        return jsonify({"error": "No resume file uploaded"}), 400

    resume = request.files['resume']
    resume.stream.seek(0)
    if resume.filename.endswith('.pdf'):
        text = extract_text_from_pdf(resume.stream)
    elif resume.filename.endswith('.docx'):
        text = extract_text_from_docx(resume)
    else:
        return jsonify({"error": f"Unsupported file type: {resume.filename}"}), 400

    category = categorize_text(text)
    return jsonify({"category": category})

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)

# import os
# from flask import Flask, request, jsonify, send_from_directory
# from PyPDF2 import PdfReader
# import pdfplumber
# import spacy
# import docx
# import pytesseract
# from PIL import Image
# import pickle
# import logging
# from io import BytesIO
# import re

# app = Flask(__name__)

# # Directory to store original resumes temporarily
# UPLOAD_FOLDER = 'uploads'
# os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# # Load ML models
# rf_classifier_categorization = pickle.load(open('models/rf_classifier_categorization.pkl', 'rb'))
# tfidf_vectorizer_categorization = pickle.load(open('models/tfidf_vectorizer_categorization.pkl', 'rb'))

# # Load spaCy NLP model
# try:
#     nlp = spacy.load("en_core_web_sm")
# except OSError:
#     logging.error("spaCy model 'en_core_web_sm' not found. Run: python -m spacy download en_core_web_sm")

# app.config["MAX_CONTENT_LENGTH"] = 50 * 1024 * 1024
# app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# # Set up logging
# logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# # Predefined skills
# cached_skills = set([  # skills should be adjusted as per your requirements
#     "Python", "Machine Learning", "SQL", "Java", "Flutter", "React", "Django",
#     "Communication", "Problem Solving", "Data Analysis", "Leadership", "Cloud", "AWS"
# ])

# # ----------------- Helper Functions -----------------

# def clean_text(text):
#     text = re.sub(r"[\r\f]+", " ", text)
#     text = re.sub(r"[\u2013\u2014]", "-", text)  # replace special dashes
#     text = re.sub(r"[\u2018\u2019\u201c\u201d]", '"', text)  # smart quotes
#     text = re.sub(r"[^\x00-\x7F]+", " ", text)  # remove non-ASCII
#     text = re.sub(r"[\n\r]+", "\n", text)  # normalize new lines
#     text = re.sub(r"\s+", " ", text)
#     return text.strip()

# def extract_text_from_pdf(file):
#     try:
#         reader = PdfReader(file)
#         text = ''.join(page.extract_text() or '' for page in reader.pages)
#         return clean_text(text) if text else extract_text_from_pdf_with_ocr(file)
#     except Exception as e:
#         logging.error(f"Error extracting PDF text: {e}")
#         return extract_text_from_pdf_with_ocr(file)

# def extract_text_from_pdf_with_ocr(file):
#     try:
#         file.seek(0)
#         with pdfplumber.open(file) as pdf:
#             text = ''.join([pytesseract.image_to_string(Image.fromarray(page.to_image().original)) for page in pdf.pages])
#         return clean_text(text)
#     except Exception as e:
#         logging.error(f"Error performing OCR on PDF: {e}")
#         return ""

# def extract_text_from_docx(file):
#     try:
#         doc = docx.Document(file)
#         return clean_text('\n'.join([para.text for para in doc.paragraphs]))
#     except Exception as e:
#         logging.error(f"Error extracting DOCX text: {e}")
#         return ""

# def extract_contact(text):
#     phone_regex = re.compile(r"\b(?:\+\d{1,3}[- ]?)?(?:\(?\d{2,4}\)?[- ]?)?\d{3,5}[- ]?\d{4,5}\b")
#     email_regex = re.compile(r"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+")
#     phone = phone_regex.findall(text)
#     email = email_regex.findall(text)
#     return phone[0] if phone else None, email[0] if email else None

# def extract_name(text):
#     lines = text.split("\n")[:5]  # First 5 lines
#     name_regex = re.compile(r"([A-Z][a-zA-Z]+ [A-Z][a-zA-Z]+)")
    
#     for line in lines:
#         match = name_regex.search(line)
#         if match:
#             return match.group(0)
    
#     return "Unknown"

# def extract_skills(text, required_skills=None):
#     text_lower = text.lower()
#     found_skills = set()
#     if required_skills:
#         for skill in required_skills:
#             if skill.lower() in text_lower:
#                 found_skills.add(skill)
#     for skill in cached_skills:
#         if skill.lower() in text_lower:
#             found_skills.add(skill)
#     return list(found_skills)

# def rank_resume(extracted_skills, required_skills):
#     matched_skills = set(required_skills).intersection(set(extracted_skills))
#     match_percentage = (len(matched_skills) / len(required_skills)) * 100 if required_skills else 0
#     return list(matched_skills), round(match_percentage, 2)

# def categorize_text(text):
#     cleaned = clean_text(text)
#     vectorized = tfidf_vectorizer_categorization.transform([cleaned])
#     return rf_classifier_categorization.predict(vectorized)[0]

# # ----------------- Routes -----------------

# @app.route('/upload', methods=['POST'])
# def upload_resumes():
#     if 'resumes' not in request.files:
#         return jsonify({"error": "No resumes uploaded"}), 400

#     resumes = request.files.getlist('resumes')
#     required_skills = request.form.get('skills', "").split(',')
#     required_skills = [skill.strip().lower() for skill in required_skills if skill.strip()]

#     results = []

#     for resume in resumes:
#         resume.stream.seek(0)
#         # Save original resume to disk for future retrieval
#         resume_filename = os.path.join(app.config['UPLOAD_FOLDER'], resume.filename)
#         resume.save(resume_filename)

#         if resume.filename.endswith('.pdf'):
#             text = extract_text_from_pdf(resume.stream)
#         elif resume.filename.endswith('.docx'):
#             text = extract_text_from_docx(resume)
#         else:
#             return jsonify({"error": f"Unsupported file type: {resume.filename}"}), 400

#         phone, email = extract_contact(text)
#         extracted_skills = extract_skills(text, required_skills)
#         matched_skills, match_percentage = rank_resume(extracted_skills, required_skills)
#         category = categorize_text(text)

#         results.append({
#             "name": extract_name(text),
#             "resume": resume.filename,
#             "phone": phone,
#             "email": email,
#             "matched_skills": matched_skills,
#             "match_percentage": match_percentage,
#             "category": category,
#             "resume_url": f'/resume/{resume.filename}'  # Provide URL to view/download the resume
#         })

#     results = sorted(results, key=lambda x: x["match_percentage"], reverse=True)
#     return jsonify({"ranked_resumes": results})

# @app.route('/resume/<filename>', methods=['GET'])
# def view_resume(filename):
#     return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# @app.route('/pred', methods=['POST'])
# def extract_details():
#     if 'resume' not in request.files:
#         return jsonify({"error": "No resume file uploaded"}), 400

#     resume = request.files['resume']
#     skills = request.form.get('skills', '').split(',')
#     skills = [s.strip().lower() for s in skills if s.strip()]

#     resume.stream.seek(0)
#     if resume.filename.endswith('.pdf'):
#         text = extract_text_from_pdf(resume.stream)
#     elif resume.filename.endswith('.docx'):
#         text = extract_text_from_docx(resume)
#     else:
#         return jsonify({"error": f"Unsupported file type: {resume.filename}"}), 400

#     phone, email = extract_contact(text)
#     extracted_skills = extract_skills(text, skills)
#     category = categorize_text(text)

#     return jsonify({
#         "name": extract_name(text),
#         "email": email,
#         "phone": phone,
#         "skills": extracted_skills,
#         "category": category,
#         "resume_url": f'/resume/{resume.filename}'  # Provide URL to view/download the resume
#     })

# @app.route('/categorize', methods=['POST'])
# def categorize_resume():
#     if 'resume' not in request.files:
#         return jsonify({"error": "No resume file uploaded"}), 400

#     resume = request.files['resume']
#     resume.stream.seek(0)
#     if resume.filename.endswith('.pdf'):
#         text = extract_text_from_pdf(resume.stream)
#     elif resume.filename.endswith('.docx'):
#         text = extract_text_from_docx(resume)
#     else:
#         return jsonify({"error": f"Unsupported file type: {resume.filename}"}), 400

#     category = categorize_text(text)
#     return jsonify({"category": category})

# # ----------------- Run Server -----------------

# if __name__ == '__main__':
#     app.run(host="0.0.0.0", port=5000, debug=True)
