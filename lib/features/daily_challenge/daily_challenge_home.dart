import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'daily_challenge.dart'; 

/*
*
*A calendar page where the user can tap on a day to open the challenge.
*/

class DailyChallengeHomePage extends StatefulWidget {
  const DailyChallengeHomePage({super.key});

  @override
  _DailyChallengeHomePageState createState() => _DailyChallengeHomePageState();
}

class _DailyChallengeHomePageState extends State<DailyChallengeHomePage> {
  DateTime _focusedDay = DateTime.now();
  
  DateTime? _selectedDay;
  // The calendar format (month view)
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DAILY CHALLENGE'),
        backgroundColor: Colors.orange, 
      ),
      body: Column(
        children: [
          
          TableCalendar(
            // Define the first and last days for the calendar.
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            
            onDaySelected: (selectedDay, focusedDay) {
              // Check if the selected day is the same as today 
              if (!isSameDay(selectedDay, DateTime.now())) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Fehler"),
                    content: const Text("Bitte wählen Sie das heutige Datum aus!"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              } else {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                // Navigate to the challenge page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChallengePage()),
                );
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            headerStyle: HeaderStyle(
              
              formatButtonVisible: true,
              // Center the header title.
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontSize: 20,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: CalendarStyle(
              
              selectedDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              
              todayDecoration: BoxDecoration(
                color: Colors.orange.shade200,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 
        ],
      ),
    );
  }
}
