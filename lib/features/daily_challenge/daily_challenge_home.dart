import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../daily_challenge/firebase_service.dart';
import 'daily_challenge.dart';

/// A calendar page where the user can tap on a day to open the challenge.
class DailyChallengeHomePage extends StatefulWidget {
  const DailyChallengeHomePage({super.key});

  @override
  _DailyChallengeHomePageState createState() =>
      _DailyChallengeHomePageState();
}

class _DailyChallengeHomePageState extends State<DailyChallengeHomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  /// Holds scores for days the user has completed
  Map<DateTime, int> _completedScores = {};

  @override
  void initState() {
    super.initState();

    /// Ensure today's document exists, then load completed challenges
    Future.microtask(() async {
      try {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await DailyChallengeService.ensureDailyChallengeExists(uid);
        final data = await DailyChallengeService.getMonthlyChallenges(uid);
        setState(() => _completedScores = data);
      } catch (e) {
        debugPrint('Error during daily challenge init: $e');
      }
    });
  }

  /// Returns an event list for a day
  List<int> _eventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final score = _completedScores[key];
    return score != null ? [score] : [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TÄGLICHE HERAUSFORDERUNG'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          TableCalendar<int>(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) =>
                isSameDay(_selectedDay, day),

            // show marker for days with events
            eventLoader: _eventsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            onDaySelected: (selectedDay, focusedDay) async {
              final uid =
                  FirebaseAuth.instance.currentUser!.uid;
              final isToday =
                  isSameDay(selectedDay, DateTime.now());

              if (!isToday) {
                showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text("Ungültiges Datum"),
                    content: Text("Bitte wähle das heutige Datum aus!"),
                  ),
                );
                return;
              }

              final alreadyDone =
                  await DailyChallengeService.isChallengeDone(uid);
              if (alreadyDone) {
                showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text("Bereits erledigt"),
                    content: Text(
                        "Du hast die heutige Herausforderung bereits abgeschlossen."),
                  ),
                );
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChallengePage()),
                );
                // Reload markers after returning
                final data = await DailyChallengeService
                    .getMonthlyChallenges(uid);
                setState(() => _completedScores = data);
              }

              setState(() {
                _focusedDay = focusedDay;
                _selectedDay = selectedDay;
              });
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
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontSize: 20,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange.shade200,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
