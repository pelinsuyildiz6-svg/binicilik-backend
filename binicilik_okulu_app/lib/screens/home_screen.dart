import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'student_registration_screen.dart';
import 'cashier_screen.dart';
import 'student_detail_screen.dart'; // Detay ekranı import edildi

// API ve JSON işlemleri için gerekli kütüphaneler
import 'package:http/http.dart' as http;
import 'dart:convert';

// TableCalendar'ın Türkçe dil desteği için dart:intl kütüphanesini import et
import 'package:intl/date_symbol_data_local.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Takvim ayarları için gerekli değişkenler
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // API'den çekilen TÜM öğrencileri tutan liste
  List<Map<String, dynamic>> _allStudents = [];

  // Takvimi doldurmak için kullanılan Map
  Map<DateTime, List<String>> _events = {};

  // API adresi (Güncel IP ve PORT: 192.168.1.5:5000)
  final String _apiUrl =
      'https://web-production-73831.up.railway.app/api/students';
  final String _apiBaseUrl =
      'https://web-production-73831.up.railway.app/api/students/'; // Detay ekranı için

  @override
  void initState() {
    super.initState();
    // Türkçe takvim formatını başlat
    initializeDateFormatting('tr_TR', null);
    // Başlangıçta verileri çek
    _fetchStudentData();
  }

  // Dersleri seçilen güne göre filtreleme
  List<String> _getEventsForDay(DateTime day) {
    // Önemli: Seçilen günü de UTC ve Saatsiz olarak normalize etmeliyiz
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  // Kullanıcı takvimde bir gün seçtiğinde çalışacak fonksiyon
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  // ---------------------------------------------------------------------
  // API VE VERİ İŞLEME FONKSİYONLARI
  // ---------------------------------------------------------------------

  // API'den öğrenci verilerini çeken fonksiyon (GET İsteği)
  Future<void> _fetchStudentData() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> studentsList = json.decode(response.body);

        setState(() {
          _allStudents = studentsList.cast<Map<String, dynamic>>();
          _groupEvents(); // Veri geldikten sonra takvimi güncelle
        });

        print('--- API Çıktısı Kontrolü ---');
        print('Toplam çekilen öğrenci sayısı: ${_allStudents.length}');
      } else {
        print('Öğrenci çekme başarısız! Hata: ${response.statusCode}');
      }
    } catch (e) {
      print('Öğrenci çekme bağlantı hatası: $e');
    }
  }

  // API'den gelen tarihi takvim formatına dönüştürür
  void _groupEvents() {
    _events = {};

    for (var student in _allStudents) {
      String dateString = student['tarih'];
      DateTime date;

      try {
        date = DateTime.parse(dateString);
      } catch (e) {
        continue;
      }

      // KRİTİK ADIM: Saati, dakikası ve saniyesi sıfırlanmış UTC tarihine dönüştür.
      final day = DateTime.utc(date.year, date.month, date.day);

      final studentName = student['ad_soyad'];
      // Saat bilgisini al
      final studentTime = student.containsKey('saat') ? student['saat'] : '';

      if (_events[day] == null) {
        _events[day] = [];
      }
      // GÜNCELLENDİ: Saati başlığın başına ekle (örn: "15:00 - Ayşe Yılmaz Dersi")
      _events[day]!.add(
        '${studentTime.isNotEmpty ? studentTime + " - " : ""}$studentName Dersi',
      );
    }
  }

  // ---------------------------------------------------------------------
  // WIDGET AĞACI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🗓️ Ders Takvimi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2ecc71),
        actions: [
          // Kasa Butonu
          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
            tooltip: 'Kasa Toplamı',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CashierScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. TABLE CALENDAR Widget'ı
          Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month, // Aylık görünüm
              locale: 'tr_TR', // Türkçe gün ve ay adları için
              startingDayOfWeek:
                  StartingDayOfWeek.monday, // Haftayı Pazartesi başlat

              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              // Gün Seçimi
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },

              // Olay İşaretleme (Events)
              eventLoader: _getEventsForDay,
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Color(0xFFe67e22), // Seçili gün (Turuncu)
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFF95a5a6), // Bugün (Gri)
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.red, // Olay olan günler (Kırmızı nokta)
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 2. ÖĞRENCİ EKLEME BUTONU
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                // Seçilen günü gönderirken saat bilgisini temizleyerek gönderelim.
                final normalizedSelectedDay = DateTime(
                  _selectedDay.year,
                  _selectedDay.month,
                  _selectedDay.day,
                );

                // Navigator.push sonucu geri dönen değeri bekliyoruz (Silme kontrolü için)
                // Bu kısım, StudentDetailScreen'den silme işlemi sonrası 'true' dönmesini yakalar.
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentRegistrationScreen(
                      selectedDate: normalizedSelectedDay,
                    ),
                  ),
                );

                // Kayıt tamamlandıktan sonra (veya detay ekranından silme sonrası) verileri tekrar çek
                if (result == true || result == null) {
                  _fetchStudentData();
                }
              },
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(
                '${_selectedDay.day}.${_selectedDay.month}.${_selectedDay.year} İçin Öğrenci Kayıt',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498db), // Mavi
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 50), // Butonu genişlet
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. SEÇİLİ GÜNÜN DERSLERİNİ LİSTELEME
          Padding(
            padding: const EdgeInsets.only(left: 15.0, bottom: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_selectedDay.day}.${_selectedDay.month}.${_selectedDay.year} Dersleri:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2c3e50),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _getEventsForDay(_selectedDay).length,
              itemBuilder: (context, index) {
                // O gün için listelenen ders başlığı (örn: "15:00 - Ayşe Yılmaz Dersi")
                final eventTitle = _getEventsForDay(_selectedDay)[index];

                // Başlıktan sadece isim kısmını ayıklama mantığı:
                String studentNameFromEvent = eventTitle;
                if (eventTitle.contains(' - ')) {
                  studentNameFromEvent = eventTitle.substring(
                    eventTitle.indexOf(' - ') + 3,
                  );
                }
                studentNameFromEvent = studentNameFromEvent.replaceAll(
                  ' Dersi',
                  '',
                );

                int originalIndex = -1;

                // Seçilen günün UTC formatı
                final normalizedSelectedDay = DateTime.utc(
                  _selectedDay.year,
                  _selectedDay.month,
                  _selectedDay.day,
                );

                // Tüm öğrenciler listesinde bu kaydın orijinal indeksini bul
                // Not: Aynı gün aynı isimde kayıt olabilir, bu yüzden saat bilgisiyle filtreleme yapmıyoruz.
                // Sadece tarih ve isim eşleşmesini yapıyoruz.
                for (int i = 0; i < _allStudents.length; i++) {
                  final student = _allStudents[i];

                  if (student['ad_soyad'] == studentNameFromEvent) {
                    try {
                      // Kaydın tarihini de kontrol et
                      final studentDate = DateTime.parse(student['tarih']);
                      final normalizedStudentDay = DateTime.utc(
                        studentDate.year,
                        studentDate.month,
                        studentDate.day,
                      );

                      // Hem isim hem de tarih eşleşiyorsa indeksi bulduk demektir.
                      if (isSameDay(
                        normalizedStudentDay,
                        normalizedSelectedDay,
                      )) {
                        originalIndex = i;
                        break;
                      }
                    } catch (e) {
                      // Hata durumunda atla
                      continue;
                    }
                  }
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 5.0,
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.sports, color: Color(0xFFe67e22)),
                    title: Text(
                      eventTitle, // Artık saat bilgisini içeriyor (örn: 15:00 - Ayşe Yılmaz Dersi)
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Detaylar için dokunun'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      if (originalIndex != -1) {
                        // Yönlendirme ve doğru indeksi gönderme
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentDetailScreen(
                              studentIndex:
                                  originalIndex, // Flask'ın isteyeceği indeks
                              apiUrlBase:
                                  _apiBaseUrl, // Flask base adresi (IP ve PORT ile güncel)
                            ),
                          ),
                        );
                        // Eğer detay ekranından silme başarılı olduysa (result == true), ana ekranı yenile
                        if (result == true) {
                          _fetchStudentData();
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('HATA: Öğrenci detayı bulunamadı.'),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
