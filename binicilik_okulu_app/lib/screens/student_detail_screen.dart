import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentDetailScreen extends StatefulWidget {
  final int studentIndex;
  final String apiUrlBase;

  const StudentDetailScreen({
    super.key,
    required this.studentIndex,
    required this.apiUrlBase,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  Map<String, dynamic>? _studentData;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  // ---------------------------------------------------------------------
  // API FONKSİYONLARI (GET, POST, DELETE)
  // ---------------------------------------------------------------------

  // Detayları Çek
  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final url = Uri.parse('${widget.apiUrlBase}${widget.studentIndex}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _studentData = json.decode(response.body) as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Detay çekilemedi. Kod: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Bağlantı hatası: $e';
        _isLoading = false;
      });
    }
  }

  // Talep: Kredi Düşürme (Ders İşle)
  Future<void> _decreaseCredit() async {
    final url = Uri.parse(
      '${widget.apiUrlBase}${widget.studentIndex}/decrease-credit',
    );
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        _fetchDetail(); // Veriyi güncelle
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ders işlendi, kredi düştü.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Kredi düşürülemedi.')));
    }
  }

  // Talep: Ödeme Durumu Güncelleme
  Future<void> _markAsPaid() async {
    final url = Uri.parse(
      '${widget.apiUrlBase}${widget.studentIndex}/mark-paid',
    );
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        _fetchDetail(); // Veriyi güncelle
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ödeme durumu güncellendi.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Ödeme kaydedilemedi.')));
    }
  }

  // Silme İşlemi
  Future<void> _deleteStudent() async {
    final url = Uri.parse('${widget.apiUrlBase}${widget.studentIndex}');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Kayıt silindi.')));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Silme başarısız.')));
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Kaydı Sil'),
        content: const Text('Bu işlem geri alınamaz. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteStudent();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TASARIM (WIDGETS)
  // ---------------------------------------------------------------------

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3498db), size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int credits = _studentData?['lesson_credits'] ?? 8; //
    String paymentStatus = _studentData?['payment_status'] ?? "Ödenmedi"; //

    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğrenci Detayı'),
        backgroundColor: const Color(0xFF3498db),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _showDeleteDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Text(
                'Hata: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Talep: Kredi bitince öğretmen bildirimi
                  if (credits == 0)
                    Container(
                      width: double.infinity,
                      color: Colors.red,
                      padding: const EdgeInsets.all(12),
                      child: const Text(
                        "⚠️ DERS KREDİSİ BİTTİ! ÖĞRETMEN DİKKAT!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                _studentData!['ad_soyad'] ?? 'Bilinmiyor',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2ecc71),
                                ),
                              ),
                            ),
                            const Divider(height: 30),

                            // Talep: Sabit Ders Saati Gösterimi
                            _buildDetailRow(
                              'Sabit Ders Saati',
                              _studentData!['lesson_schedule'] ??
                                  'Belirlenmedi',
                              Icons.access_time,
                            ),
                            _buildDetailRow(
                              'Veli Telefon',
                              _studentData!['veli_telefon'] ?? 'Yok',
                              Icons.phone,
                            ),

                            const Divider(),

                            // KREDİ BÖLÜMÜ
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    "Kalan Ders Hakkı",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    "$credits / 8",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: credits < 2
                                          ? Colors.red
                                          : Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: credits > 0
                                        ? _decreaseCredit
                                        : null,
                                    icon: const Icon(Icons.check),
                                    label: const Text("Dersi İşle (-1 Kredi)"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(),

                            // ÖDEME BÖLÜMÜ
                            _buildDetailRow(
                              'Ödeme Durumu',
                              paymentStatus,
                              Icons.payments,
                              valueColor: paymentStatus == "Ödendi"
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            if (paymentStatus == "Ödenmedi")
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _markAsPaid,
                                  child: const Text(
                                    "Ödeme Alındı Olarak İşaretle",
                                  ),
                                ),
                              ),

                            const Divider(),
                            _buildDetailRow(
                              'Ödenen Tutar',
                              '${_studentData!['odenen_tutar'] ?? '0.00'} TL',
                              Icons.monetization_on,
                            ),
                            _buildDetailRow(
                              'Kayıt Tarihi',
                              _studentData!['tarih'] ?? 'Yok',
                              Icons.calendar_today,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
