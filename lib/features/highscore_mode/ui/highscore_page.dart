import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home/data/countries_data.dart';

class HighscoreScreen extends StatefulWidget {
  const HighscoreScreen({super.key});

  @override
  State<HighscoreScreen> createState() => _HighscoreScreenState();
}

class _HighscoreScreenState extends State<HighscoreScreen> {
  late String correctCountry;
  late String flagPath;
  final TextEditingController _controller = TextEditingController();
  TextEditingController? _autoCompleteController;
  List<String> currentSuggestions = [];

  int score = 0;
  int highscore = 0;
  int timeLeft = 60;
  String feedback = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadHighscore();
    _generateQuestion();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHighscore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highscore = prefs.getInt('highscore') ?? 0;
    });
  }

  Future<void> _updateHighscore() async {
    if (score > highscore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highscore', score);
      setState(() {
        highscore = score;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    timeLeft = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          timer.cancel();
          _updateHighscore();
          _showEndDialog();
        }
      });
    });
  }

  void _generateQuestion() {
    final random = Random();
    final countries = CountryData.countries.keys.toList();
    correctCountry = countries[random.nextInt(countries.length)];
    final flag = CountryData.countries[correctCountry]!;
    flagPath = 'lib/features/Guess_the_flag_multiple_choice/assets/flags/$flag';

    feedback = '';
    _controller.clear();
    _autoCompleteController?.clear();
  }

  void _checkAnswer([String? submitted]) {
    final answer = (submitted ?? _controller.text).trim();

    if (answer.toLowerCase() == correctCountry.toLowerCase()) {
      score++;
      feedback = '✅ Richtig!';
      if (score > highscore) {
        highscore = score;
        _updateHighscore();
      }
    }
    else {
      feedback = '❌ Falsch! Richtige Antwort: $correctCountry';
    }

    setState(() {
      _controller.clear();
      _autoCompleteController?.clear();
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _generateQuestion();
      });
    });
  }

  void _showEndDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("⏰ Zeit abgelaufen"),
        content: Text("Dein Score: $score\nHighscore: $highscore"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Zurück"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                score = 0;
                feedback = '';
                _generateQuestion();
                _startTimer();
              });
            },
            child: const Text("Nochmal spielen"),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Punkte: $score", style: const TextStyle(fontSize: 20)),
        Text("Bestwert: $highscore", style: const TextStyle(fontSize: 20)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Highscore Hero', textAlign: TextAlign.center,),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Text(
                "🕒 $timeLeft s",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            const SizedBox(height: 4),
            _buildScoreRow(),
            const SizedBox(height: 20),
            Center(child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200], // Heller neutraler Hintergrund, damit weiße flaggen besser erkennt
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(flagPath, height: 150),
            ),
            ),
            const SizedBox(height: 20),
            Autocomplete<String>(
              optionsBuilder: (value) {
                if (value.text.isEmpty) return const Iterable<String>.empty();
                currentSuggestions = CountryData.countries.keys.where((country) {
                  return country.toLowerCase().contains(value.text.toLowerCase());
                }).toList();
                return currentSuggestions;
              },
              onSelected: (selection) {
                _controller.text = selection;
                _checkAnswer(selection);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _autoCompleteController = controller;
                controller.addListener(() {
                  _controller.text = controller.text;
                });

                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: _checkAnswer,
                  decoration: InputDecoration(
                    labelText: 'Land eingeben',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Antwort prüfen', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                feedback,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
