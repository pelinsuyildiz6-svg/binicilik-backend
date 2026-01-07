from flask import Flask, request, jsonify
from flask_cors import CORS
import json
from datetime import datetime, timedelta
import os 

app = Flask(__name__)
CORS(app) 

DATA_FILE = 'students.json'

# --- VERİ YÖNETİMİ FONKSİYONLARI ---

def load_data():
    if not os.path.exists(DATA_FILE):
        return []
    try:
        with open(DATA_FILE, 'r', encoding='utf-8') as f:
            content = f.read()
            if not content:
                return []
            data = json.loads(content)
            
            # Otomatik Kredi Sıfırlama Kontrolü (1 Ay dolunca)
            updated = False
            now = datetime.now()
            for s in data:
                reg_date = datetime.fromisoformat(s.get('kayit_zamani', now.isoformat()))
                # Eğer kayıt üzerinden 30 gün geçmişse ve kredisi varsa sıfırla
                if (now - reg_date).days >= 30 and s.get('lesson_credits', 0) > 0:
                    s['lesson_credits'] = 0
                    updated = True
            if updated:
                save_data(data)
            return data
    except Exception as e:
        print(f"Veri yükleme hatası: {e}")
        return []

def save_data(data):
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

# --- ENDPOINT'LER ---

# 1. TÜM ÖĞRENCİLERİ GETİR
@app.route('/api/students', methods=['GET'])
def get_all_students():
    students = load_data()
    return jsonify(students), 200

# 2. YENİ ÖĞRENCİ KAYDI (Yeni alanlar eklendi)
@app.route('/api/students/register', methods=['POST'])
def register_student():
    students = load_data()
    try:
        data = request.get_json()
        
        # Orijinal alanların yanına yeni yönetim alanlarını ekliyoruz
        new_student = {
            'ad_soyad': data['ad_soyad'],
            'veli_telefon': data['veli_telefon'],
            'sinif': data.get('sinif', ''),
            'at_bilgisi': data.get('at_bilgisi', ''),
            'ucret_turu': data.get('ucret_turu', ''),
            'odenen_tutar': float(data.get('odenen_tutar', 0)),
            'ogretmen': data.get('ogretmen', ''),
            'kayit_zamani': datetime.now().isoformat(),
            'tarih': data.get('tarih', ''),
            'saat': data.get('saat', ''),
            # --- YENİ TALEPLER ---
            'payment_status': 'Ödenmedi', # Varsayılan durum
            'lesson_credits': 8,           # Başlangıç kredisi
            'lesson_schedule': f"{data.get('tarih', '')} {data.get('saat', '')}" # Ders saati
        }
        
        students.append(new_student)
        save_data(students)
        return jsonify({'message': 'Kayıt başarılı', 'data': new_student}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# 3. KREDİ DÜŞÜRME (Butona basınca 8'den 7'ye düşer)
@app.route('/api/students/<int:index>/decrease-credit', methods=['POST'])
def decrease_credit(index):
    students = load_data()
    if 0 <= index < len(students):
        if students[index].get('lesson_credits', 0) > 0:
            students[index]['lesson_credits'] -= 1
            save_data(students)
            return jsonify({'success': True, 'new_credit': students[index]['lesson_credits']}), 200
        return jsonify({'error': 'Kredi zaten 0!'}), 400
    return jsonify({'error': 'Öğrenci bulunamadı'}), 404

# 4. ÖDEME ONAYLAMA (Ödenmedi -> Ödendi yapar)
@app.route('/api/students/<int:index>/mark-paid', methods=['POST'])
def mark_paid(index):
    students = load_data()
    if 0 <= index < len(students):
        students[index]['payment_status'] = 'Ödendi'
        save_data(students)
        return jsonify({'success': True, 'message': 'Ödeme alındı'}), 200
    return jsonify({'error': 'Öğrenci bulunamadı'}), 404

# 5. KASA DETAYLI (Ödenen vs Beklenen)
@app.route('/api/cashier/total', methods=['GET'])
def get_total_cash():
    students = load_data()
    total_paid = sum(s.get('odenen_tutar', 0) for s in students if s.get('payment_status') == 'Ödendi')
    total_pending = sum(s.get('odenen_tutar', 0) for s in students if s.get('payment_status') == 'Ödenmedi')
    
    return jsonify({
        'total_amount': total_paid,       # Kasadaki net para
        'pending_amount': total_pending, # Beklenen para
        'grand_total': total_paid + total_pending,
        'record_count': len(students)
    }), 200

# 6. SİLME İŞLEMİ
@app.route('/api/students/<int:index>', methods=['DELETE'])
def delete_student(index):
    students = load_data()
    if 0 <= index < len(students):
        deleted = students.pop(index)
        save_data(students)
        return jsonify({'message': 'Silindi', 'deleted': deleted}), 200
    return jsonify({'error': 'Geçersiz indeks'}), 404

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)