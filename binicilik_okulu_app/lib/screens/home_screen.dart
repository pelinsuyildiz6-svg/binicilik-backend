import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'student_registration_screen.dart';
import 'cashier_screen.dart';
import 'student_detail_screen.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/date_symbol_data_local.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Map<String, dynamic>> _allStudents = [];
  Map<DateTime, List<String>> _events = {};

  // DÜZELTME: URL'lerin sonuna mutlaka / eklendi
  final String _apiUrl = 'https://binicilik-backend.onrender.com/api/students/';
  final String _apiBaseUrl =
      'https://binicilik-backend.onrender.com/api/students/';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _fetchStudentData();
  }

  List<String> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _fetchStudentData() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> studentsList = json.decode(response.body);
        setState(() {
          _allStudents = studentsList.cast<Map<String, dynamic>>();
          _groupEvents();
        });
      }
    } catch (e) {
      print('Bağlantı hatası: $e');
    }
  }

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

      final day = DateTime.utc(date.year, date.month, date.day);
      final studentName = student['ad_soyad'];
      final studentTime = student.containsKey('saat') ? student['saat'] : '';

      if (_events[day] == null) {
        _events[day] = [];
      }
      _events[day]!.add(
        '${studentTime.isNotEmpty ? studentTime + " - " : ""}$studentName Dersi',
      );
    }
  }

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
          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
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
              calendarFormat: CalendarFormat.month,
              locale: 'tr_TR',
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: _getEventsForDay,
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Color(0xFFe67e22),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFF95a5a6),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final normalizedSelectedDay = DateTime(
                  _selectedDay.year,
                  _selectedDay.month,
                  _selectedDay.day,
                );
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentRegistrationScreen(
                      selectedDate: normalizedSelectedDay,
                    ),
                  ),
                );
                if (result == true || result == null) {
                  _fetchStudentData();
                }
              },
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(
                '${_selectedDay.day}.${_selectedDay.month}.${_selectedDay.year} İçin Kayıt',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498db),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _getEventsForDay(_selectedDay).length,
              itemBuilder: (context, index) {
                final eventTitle = _getEventsForDay(_selectedDay)[index];
                String studentNameFromEvent = eventTitle;
                if (eventTitle.contains(' - ')) {
                  studentNameFromEvent = eventTitle.substring(
                    eventTitle.indexOf(' - ') + 3,
                  );
                }
                studentNameFromEvent = studentNameFromEvent
                    .replaceAll(' Dersi', '')
                    .trim();

                int originalIndex = -1;
                final normalizedSelectedDay = DateTime.utc(
                  _selectedDay.year,
                  _selectedDay.month,
                  _selectedDay.day,
                );

                for (int i = 0; i < _allStudents.length; i++) {
                  if (_allStudents[i]['ad_soyad'] == studentNameFromEvent) {
                    try {
                      final studentDate = DateTime.parse(
                        _allStudents[i]['tarih'],
                      );
                      final normalizedStudentDay = DateTime.utc(
                        studentDate.year,
                        studentDate.month,
                        studentDate.day,
                      );
                      if (isSameDay(
                        normalizedStudentDay,
                        normalizedSelectedDay,
                      )) {
                        originalIndex = i;
                        break;
                      }
                    } catch (e) {
                      continue;
                    }
                  }
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 5.0,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.sports, color: Color(0xFFe67e22)),
                    title: Text(
                      eventTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Detaylar için dokunun'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      if (originalIndex != -1) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentDetailScreen(
                              studentIndex: originalIndex,
                              apiUrlBase: _apiBaseUrl, // ARTIK / İÇERİYOR
                            ),
                          ),
                        );
                        if (result == true) {
                          _fetchStudentData();
                        }
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
