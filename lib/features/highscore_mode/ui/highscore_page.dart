import 'package:flutter/material.dart';
import 'dart:math';
import '../../home/data/countries_data.dart';

class HighscoreScreen extends StatefulWidget {
  const HighscoreScreen({super.key});

  @override
  _HighscoreScreenState createState() => _HighscoreScreenState();
}

class _HighscoreScreenState extends State<HighscoreScreen> {
  late String correctCountry;
  late String flagPath;
  final TextEditingController _controller = TextEditingController();
  TextEditingController? _autoCompleteController;
  List<String> currentSuggestions = [];

  int score = 0;
  String feedback = '';

  @override
  void initState() {
    super.initState();
    _generateQuestion();
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

    setState(() {});
  }

  void _checkAnswer([String? submitted]) {
    final answer = (submitted ?? _controller.text).trim();

    if (answer.toLowerCase() == correctCountry.toLowerCase()) {
      score++;
      feedback = 'Richtig!';
    } else {
      score = 0;
      feedback = 'Falsch: $correctCountry';
    }

    setState(() {
      _controller.clear();
      _autoCompleteController?.clear(); // Sichtbares Feld leeren
    });

    Future.delayed(const Duration(seconds: 2), () {
      _generateQuestion();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Highscore Mode'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Highscore: $score', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            Image.asset(flagPath, height: 150),
            const SizedBox(height: 20),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  currentSuggestions = [];
                  return const Iterable<String>.empty();
                }

                currentSuggestions = CountryData.countries.keys.where((String country) {
                  return country.toLowerCase().contains(textEditingValue.text.toLowerCase());
                }).toList();

                return currentSuggestions;
              },
              onSelected: (String selection) {
                _controller.text = selection;
                _checkAnswer(selection); // Direkt checken bei Auswahl
              },
              fieldViewBuilder:
                  (context, textEditingController, focusNode, onFieldSubmitted) {
                _autoCompleteController = textEditingController;

                // Synchronisiere alle Eingaben mit dem Hauptcontroller
                textEditingController.addListener(() {
                  _controller.text = textEditingController.text;
                });

                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  onSubmitted: (value) {
                    final trimmed = value.trim();

                    // Wenn die Eingabe exakt einem Land entspricht, checke direkt
                    if (CountryData.countries.keys.any((country) =>
                    country.toLowerCase() == trimmed.toLowerCase())) {
                      _checkAnswer(trimmed);
                    }
                    // Falls Tipp + Suggestion übereinstimmen, nutze das erste Matching
                    else if (currentSuggestions.isNotEmpty) {
                      final bestMatch = currentSuggestions.firstWhere(
                            (c) => c.toLowerCase().startsWith(trimmed.toLowerCase()),
                        orElse: () => trimmed,
                      );
                      _checkAnswer(bestMatch);
                    } else {
                      // Wenn nichts passt, prüfe trotzdem das Eingegebene
                      _checkAnswer(trimmed);
                    }
                  },

                  decoration: const InputDecoration(
                    labelText: 'Land eingeben',
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkAnswer,
              child: const Text('Antwort prüfen'),
            ),
            const SizedBox(height: 10),
            Text(feedback, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
