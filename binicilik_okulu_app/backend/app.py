from flask import Flask, jsonify, request
from flask_cors import CORS
import json
import os

app = Flask(__name__)
# Flutter uygulamasının backend ile sorunsuz konuşması için CORS aktif
CORS(app)

DATA_FILE = 'students.json'

def load_students():
    if not os.path.exists(DATA_FILE):
        return []
    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        try:
            return json.load(f)
        except json.JSONDecodeError:
            return []

def save_students(students):
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(students, f, ensure_ascii=False, indent=4)

@app.route('/api/students', methods=['GET', 'POST', 'OPTIONS'])
def manage_students():
    if request.method == 'POST':
        students = load_students()
        new_student = request.json
        students.append(new_student)
        save_students(students)
        return jsonify({"message": "Öğrenci başarıyla kaydedildi"}), 201
    return jsonify(load_students())

# 405 HATASINI ÇÖZEN VE DETAY/SİLME İŞLEMLERİNİ YAPAN KRİTİK ROUTE
@app.route('/api/students/<int:index>', methods=['GET', 'POST', 'DELETE', 'OPTIONS'])
def student_detail_api(index):
    students = load_students()
    
    if request.method == 'OPTIONS':
        return jsonify({"status": "ok"}), 200

    # 1. ÖĞRENCİ SİLME (DELETE)
    # Flutter'dan gelen silme isteğini karşılar
    if request.method == 'DELETE':
        if 0 <= index < len(students):
            removed = students.pop(index)
            save_students(students)
            return jsonify({"message": "Öğrenci silindi", "student": removed}), 200
        return jsonify({"error": "Öğrenci bulunamadı"}), 404

    # 2. ÖĞRENCİ DETAYI GETİRME (GET)
    # Takvimden bir isme tıklandığında bilgileri getirir
    if 0 <= index < len(students):
        return jsonify(students[index]), 200
    
    return jsonify({"error": "Öğrenci bulunamadı"}), 404

@app.route('/')
def index():
    return "Binicilik Okulu Yönetim Sistemi Backend Aktif!"

if __name__ == '__main__':
    # Render üzerinde çalışması için gerekli port yapılandırması
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)