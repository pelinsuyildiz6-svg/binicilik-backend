// lib/screens/cashier_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  double _totalCash = 0.0;
  bool _isLoading = true;
  String _errorMessage = '';

  // GÜNCELLENEN URL: Render üzerindeki canlı adresin
  // Toplam kasa bilgisi genellikle /api/cashier/total ucundan gelir.
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
          // Flask tarafındaki anahtar kelimenin 'total_amount' olduğundan emin ol
          _totalCash = (data['total_amount'] ?? 0.0).toDouble();
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
        _errorMessage = 'Bağlantı Başarısız: Sunucuya ulaşılamıyor.\nHata: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '💵 Kasa Toplamı',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFe74c3c),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              else ...[
                const Text(
                  'Toplam Kasa (Net Gelir):',
                  style: TextStyle(fontSize: 22, color: Color(0xFF2c3e50)),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_totalCash.toStringAsFixed(2)} TL',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2ecc71),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _fetchTotalCash,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Yenile',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498db),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
