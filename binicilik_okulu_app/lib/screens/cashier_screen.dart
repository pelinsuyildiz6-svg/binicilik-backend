import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  double _totalPaid = 0.0; // Kasada olan (Ödenen)
  double _totalPending = 0.0; // Dışarıda olan (Beklenen)
  bool _isLoading = true;
  String _errorMessage = '';

  final String _apiUrl =
      'https://binicilik-backend.onrender.com/api/cashier/total';

  @override
  void initState() {
    super.initState();
    _fetchTotalCash();
  }

  Future<void> _fetchTotalCash() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Backend'den gelen anahtarlara göre eşliyoruz
          _totalPaid = (data['total_amount'] ?? 0.0).toDouble();
          _totalPending = (data['pending_amount'] ?? 0.0).toDouble();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Sunucu Hatası: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
        _isLoading = false;
      });
    }
  }

  // Bilgi kartı oluşturmak için yardımcı tasarım widget'ı
  Widget _buildCashCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        subtitle: Text(
          '${amount.toStringAsFixed(2)} TL',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💵 Muhasebe / Kasa'),
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTotalCash,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage.isNotEmpty)
                Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else ...[
                // TALEP: Kasada ödenen miktar
                _buildCashCard(
                  'Kasada Olan (Ödenen)',
                  _totalPaid,
                  Colors.green,
                  Icons.account_balance_wallet,
                ),

                // TALEP: Ödenmesi beklenen miktar
                _buildCashCard(
                  'Dışarıda Olan (Beklenen)',
                  _totalPending,
                  Colors.orange,
                  Icons.hourglass_empty,
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // Genel Toplam (Opsiyonel)
                Text(
                  'Genel Toplam: ${(_totalPaid + _totalPending).toStringAsFixed(2)} TL',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _fetchTotalCash,
                icon: const Icon(Icons.refresh),
                label: const Text('Verileri Güncelle'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF3498db),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
