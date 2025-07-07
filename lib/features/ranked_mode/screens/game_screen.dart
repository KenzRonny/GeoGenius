import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geo_genius/features/ranked_mode/screens/ranked_lobby_screen.dart';

bool? isCorrectAnswer;
bool showAnswerFeedback = false;


class GameScreen extends StatefulWidget {
  final String matchId;
  const GameScreen({super.key, required this.matchId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<Map<String, dynamic>> countries;
  Map<String, dynamic>? selectedCountry;
  int currentQuestion = 0;
  int score = 0;
  List<Map<String, dynamic>> questions = [];
  String? selectedOption;
  int remainingSeconds = 60;
  late Timer timer;
  bool hasPlayed = false;

  @override
  void initState() {
    super.initState();
    loadGameData();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds == 0) {
        timer.cancel();
        handleTimeout();
      } else {
        setState(() {
          remainingSeconds--;
        });
      }
    });
  }

  void handleTimeout() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('⏰ Zeit abgelaufen'),
        content: const Text('Die Zeit ist abgelaufen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    updatePlayerScore();
    if(!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Spiel beendet'),
        content: Text('Du hast $score von ${questions.length} richtig!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RankedRivalPage()),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }



  Future<void> loadGameData() async {

    setState(() {
      currentQuestion = 0;
      score = 0;
      selectedOption = null;
      showAnswerFeedback = false;
      isCorrectAnswer = null;
      questions = [];
      remainingSeconds = 60;
    });

    final matchSnapshot = await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).get();
    final countryId = matchSnapshot.data()?['countryId'];

    final String jsonStr = await rootBundle.loadString('assets/json/countries/countries.json');
    final List<dynamic> countryList = json.decode(jsonStr);
    countries = countryList.cast<Map<String, dynamic>>();

    selectedCountry = countries.firstWhere(
          (c) => c['cca3'].toString().toUpperCase() == countryId.toString().toUpperCase(),
    );

    generateQuestions();
    setState(() {
      remainingSeconds = 60;
      startTimer();
    });
  }
  void generateQuestions() {
    final rnd = Random();

    questions = [
      {
        'question': 'Welches Land gehört zu dieser Flagge?',
        'flag': selectedCountry!['flags']['png'],
        'correct': selectedCountry!['translations']?['deu']?['common'] ?? selectedCountry!['name']['common'],
        'options': List.generate(4, (_) {
          final rand = countries[rnd.nextInt(countries.length)];
          return rand['translations']?['deu']?['common'] ?? rand['name']['common'];
        })..[rnd.nextInt(4)] = selectedCountry!['translations']?['deu']?['common'] ?? selectedCountry!['name']['common'],
        'type': 'flag-to-country',
      },
      {
        'question': 'Was ist die Hauptstadt von ${selectedCountry!['translations']?['deu']?['common'] ?? selectedCountry!['name']['common']}?',
        'correct': selectedCountry!['capital']?[0] ?? 'Keine Hauptstadt',
        'options': List.generate(4, (_) => countries[rnd.nextInt(countries.length)]['capital']?.first ?? 'Keine')
          ..[rnd.nextInt(4)] = selectedCountry!['capital']?[0] ?? 'Keine Hauptstadt',
      },
      {
        'question': 'Welche Sprache wird in ${selectedCountry!['translations']?['deu']?['common'] ?? selectedCountry!['name']['common']} gesprochen?',
        'correct': (selectedCountry!['languages'] as Map).values.first,
        'options': (() {
          final correctLang = (selectedCountry!['languages'] as Map).values.first;
          final Set<String> optionsSet = {correctLang}; // beginne mit korrekter Antwort
          final rand = Random();

          while (optionsSet.length < 4) {
            final langMap = countries[rand.nextInt(countries.length)]['languages'];
            if (langMap == null || langMap is! Map || langMap.values.isEmpty) continue;

            final lang = langMap.values.first;
            if (lang != correctLang) optionsSet.add(lang);
          }

          final options = optionsSet.toList()..shuffle();
          return options;
        })(),
      },
      {
        'question': 'Wie viele Einwohner hat ${selectedCountry!['translations']?['deu']?['common'] ?? selectedCountry!['name']['common']} ungefähr?',
        'correct': (() {
          final pop = selectedCountry!['population'];
          return pop >= 1000000
              ? '${(pop / 1000000).round()} Mio.'
              : pop.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]}.');
        })(),
        'options': (() {
          final pop = selectedCountry!['population'];
          final correctFormatted = pop >= 1000000
              ? '${(pop / 1000000).round()} Mio.'
              : pop.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]}.');

          final Set<String> optionsSet = {};

          while (optionsSet.length < 3) {
            final randCountry = countries[Random().nextInt(countries.length)];
            final randPop = randCountry['population'];

            if (randPop == null || randPop == 0) continue;

            if (randPop == pop) continue;

            final formatted = randPop >= 1000000
                ? '${(randPop / 1000000).round()} Mio.'
                : randPop.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]}.');

            optionsSet.add(formatted);
          }

          final options = optionsSet.toList()
            ..add(correctFormatted)
            ..shuffle();

          return options;
        })(),
      },
      {
        'question': 'Welche Währung wird in ${selectedCountry!['translations']?['deu']?['common'] ?? selectedCountry!['name']['common']} verwendet?',
        'correct': ((selectedCountry!['currencies'] as Map).entries.first.value as Map)['name'],
        'options': List.generate(3, (_) {
          final rand = countries[rnd.nextInt(countries.length)];
          final curr = rand['currencies'];
          return curr != null
              ? ((curr as Map).entries.first.value as Map)['name']
              : 'Unbekannt';
        })..add(((selectedCountry!['currencies'] as Map).entries.first.value as Map)['name'])..shuffle(),
      },

    ];
  }

  void checkAnswer(String answer) {
    final correct = questions[currentQuestion]['correct'];

    setState(() {
      isCorrectAnswer = (answer == correct);
      showAnswerFeedback = true;
    });

    // Warte kurz, dann weiter
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (currentQuestion < questions.length - 1) {
        setState(() {
          currentQuestion++;
          selectedOption = null;
          isCorrectAnswer = null;
          showAnswerFeedback = false;
        });
      } else {
        timer.cancel();
        updatePlayerScore();
        if(!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Spiel beendet'),
            content: Text('Du hast $score von ${questions.length} richtig!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RankedRivalPage()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });

    if (isCorrectAnswer == true) score++;
  }


  void submitAnswer() {
    if (selectedOption != null) {
      checkAnswer(selectedOption!);
    }
  }

  Future<void> updatePlayerScore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final matchRef = FirebaseFirestore.instance.collection('matches').doc(widget.matchId);
    final snapshot = await matchRef.get();
    final data = snapshot.data();

    if (data == null) return;

    final players = Map<String, dynamic>.from(data['players'] ?? {});
    String? playerKey;

    if (players['player1']?['id'] == userId) {
      playerKey = 'player1';
    } else if (players['player2']?['id'] == userId) {
      playerKey = 'player2';
    }

    if (playerKey == null) return;

    // Setze den Score und "hasPlayed: true"
    players[playerKey]['score'] = score;
    players[playerKey]['hasPlayed'] = true;

    // Prüfe, ob beide gespielt haben
    final bothPlayed = players['player1']?['hasPlayed'] == true &&
        players['player2']?['hasPlayed'] == true;

    // Baue Update-Map
    final Map<String, dynamic> updateData = {
      'players': players,
    };


    if (bothPlayed) {
      updateData['status'] = 'finished';

      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update(updateData);

      final finalMatchSnapshot = await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).get();
      final finalMatchData = finalMatchSnapshot.data();

      if (finalMatchData != null) {
        await updateRankedPoints(matchId: widget.matchId, matchData: finalMatchData);
      }

      return;

    }

    await matchRef.update(updateData);
  }
  Future<void> updateRankedPoints({
    required String matchId,
    required Map<String, dynamic> matchData,
  }) async {
    final player1 = matchData['players']['player1'];
    final player2 = matchData['players']['player2'];

    final String uid1 = player1['id'];
    final String uid2 = player2['id'];

    final int score1 = player1['score'] ?? 0;
    final int score2 = player2['score'] ?? 0;

    String winnerId;
    String loserId;
    int diff = (score1 - score2).abs();

    if (score1 > score2) {
      winnerId = uid1;
      loserId = uid2;
    } else if (score2 > score1) {
      winnerId = uid2;
      loserId = uid1;
    } else {
      // Unentschieden – keine Änderung
      return;
    }

    final bonus = diff * 2;

    final winnerRef = FirebaseFirestore.instance.collection('users').doc(winnerId);
    final loserRef = FirebaseFirestore.instance.collection('users').doc(loserId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final winnerSnap = await tx.get(winnerRef);
      final loserSnap = await tx.get(loserRef);

      final currentWinnerPoints = winnerSnap.data()?['rankedPoints'] ?? 0;
      final currentLoserPoints = loserSnap.data()?['rankedPoints'] ?? 0;

      tx.update(winnerRef, {
        'rankedPoints': currentWinnerPoints + 10 + bonus,
      });
      final newLoserPoints = (currentLoserPoints - 5).clamp(0, double.infinity).toInt();

      tx.update(loserRef, {
        'rankedPoints': newLoserPoints,
      });

    });
  }




  @override
  Widget build(BuildContext context) {
    if (selectedCountry == null || questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = questions[currentQuestion];
    final options = List<String>.from(question['options']);
    final progress = (currentQuestion + 1) / questions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Frage ${currentQuestion + 1}/${questions.length}",
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text("Zeit: 00:${remainingSeconds.toString().padLeft(2, '0')}"),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade300,
                color: const Color(0xFFF1A059),
              ),
              const SizedBox(height: 24),

              // Flaggenbild bei Typ "flag-to-country"
              if (question['type'] == 'flag-to-country')
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      question['flag'],
                      height: 180,
                      width: 280,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Frage
              Text(
                question['question'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Antworten
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isCorrect = option == questions[currentQuestion]['correct'];
                    final isSelected = selectedOption == option;

                    Color? tileColor;

                    if (showAnswerFeedback) {
                      if (isCorrect) {
                        tileColor = Colors.green.shade100;
                      } else if (isSelected) {
                        tileColor = Colors.red.shade100;
                      }
                    } else if (isSelected) {
                      tileColor = Colors.orange.shade50;
                    } else {
                      tileColor = Colors.grey.shade100;
                    }

                    return RadioListTile<String>(
                      value: option,
                      groupValue: selectedOption,
                      onChanged: showAnswerFeedback ? null : (val) => setState(() => selectedOption = val),
                      title: Text(option),
                      tileColor: tileColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    );
                  },
                ),
              ),



              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedOption != null ? submitAnswer : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1A059),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Bestätigen"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
