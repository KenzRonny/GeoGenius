/*
  This page displays a "Daily Challenge" quiz that tests the user’s knowledge about countries.
  It loads country data from an "countries.json" file in assets, randomly generates a challenge with 6 questions,
  and displays the questions  Depending on the randomly selected main index (flag, name, or capital),
  one or two "inverted" questions are generated (asking for the missing information), and the rest are standard questions.
  The user must answer all questions before validation is allowed.
  When the "Validieren" button is pressed, the correct answers are highlighted in green; any wrong answer chosen
  appears in red.
*/


import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../daily_challenge/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model for Country data 
class Country {
  final String name;
  final List<String> languages;
  final int population;
  final int area;
  final String continent;
  final String flagAsset;
  final String capital;

  Country({
    required this.name,
    required this.languages,
    required this.population,
    required this.area,
    required this.continent,
    required this.flagAsset,
    required this.capital,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    // Get the common german name or default to 'Unknown'
    final name = (json['name'] is Map && json["translations"]["deu"]["common"] != null)
        ? json["translations"]["deu"]["common"] as String
        : 'Unknown';

    // Process languages if available, otherwise an empty list.
    final languagesData = json['languages'];
    List<String> languages = [];
    if (languagesData is Map<String, dynamic>) {
      languages = List<String>.from(languagesData.values);
    }

    // Get population and area (with default values if missing)
    final population = json['population'] is int ? json['population'] as int : 0;
    final area = json['area'] is num ? (json['area'] as num).toInt() : 0;

    // Get the first continent from the list or default to 'Unknown'
    final continentsData = json['continents'];
    final continent =
        (continentsData is List && continentsData.isNotEmpty)
            ? continentsData[0] as String
            : 'Unknown';

    // Get flag asset  from the 'png' field.
    final flagData = json['flags'];
    final flagAsset = (flagData is Map && flagData['png'] != null)
        ? flagData['png'] as String
        : '';

    // Get capital (first element of the capital list) or default to 'Unknown'
    final capitalData = json['capital'];
    final capital =
        (capitalData is List && capitalData.isNotEmpty)
            ? capitalData[0] as String
            : 'Unknown';

    return Country(
      name: name,
      languages: languages,
      population: population,
      area: area,
      continent: continent,
      flagAsset: flagAsset,
      capital: capital,
    );
  }
}

/// Loads the JSON file  from assets.
Future<List<Country>> loadCountries() async {
  try {
    final jsonString = await rootBundle.loadString('assets/json/countries/countries.json');
    final List<dynamic> data = jsonDecode(jsonString);
    return data
        .where((item) => item != null)
        .map((item) => Country.fromJson(item as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print("Error loading or parsing JSON: $e");
    rethrow;
  }
}


class ChallengeQuestion {
  final Country country;
  final String givenType; // "flag", "name", or "capital"
  final List<String>? invertedNameOptions;
  final List<String>? invertedFlagOptions;
  final List<String> languageOptions;
  final List<int> populationOptions;
  final List<int> areaOptions;
  final List<String> continentOptions;
  final List<String> capitalOptions; // Shown only if givenType is not "capital"

  ChallengeQuestion({
    required this.country,
    required this.givenType,
    this.invertedNameOptions,
    this.invertedFlagOptions,
    required this.languageOptions,
    required this.populationOptions,
    required this.areaOptions,
    required this.continentOptions,
    required this.capitalOptions,
  });
}

/// Generates a list of string options excluding the correct value.
List<String> generateStringOptions(String correctValue, List<String> allValues) {
  final filtered = allValues.where((v) => v != correctValue).toList();
  if (filtered.length < 2) return [correctValue];
  filtered.shuffle();
  List<String> options = [correctValue, filtered[0], filtered[1]];
  options.shuffle();
  return options;
}

/// Generates a list of integer options excluding the correct value.
List<int> generateIntOptions(int correctValue, List<int> allValues) {
  final filtered = allValues.where((v) => v != correctValue).toList();
  if (filtered.length < 2) return [correctValue];
  filtered.shuffle();
  List<int> options = [correctValue, filtered[0], filtered[1]];
  options.shuffle();
  return options;
}

/// Generates a full challenge based on the list of countries.
ChallengeQuestion generateChallenge(List<Country> countries) {
  final random = Random();
  final Country selectedCountry = countries[random.nextInt(countries.length)];
  const possibleIndices = ["flag", "name", "capital"];
  final String givenType = possibleIndices[random.nextInt(possibleIndices.length)];

  List<String>? invNameOptions;
  List<String>? invFlagOptions;
  List<String> stdCapitalOptions;

  // Standard options for language, population, area, and continent.
  final languageCandidates = countries
      .where((c) => c.name != selectedCountry.name && c.languages.isNotEmpty)
      .map((c) => c.languages.first)
      .toList();
  final languageOptions = generateStringOptions(
    selectedCountry.languages.isNotEmpty ? selectedCountry.languages.first : 'Unknown',
    languageCandidates,
  );

  final populationCandidates = countries
      .where((c) => c.name != selectedCountry.name)
      .map((c) => c.population)
      .toList();
  final populationOptions = generateIntOptions(selectedCountry.population, populationCandidates);

  final areaCandidates = countries
      .where((c) => c.name != selectedCountry.name)
      .map((c) => c.area)
      .toList();
  final areaOptions = generateIntOptions(selectedCountry.area, areaCandidates);

  final continentCandidates = countries
      .where((c) => c.name != selectedCountry.name)
      .map((c) => c.continent)
      .toList();
  final continentOptions = generateStringOptions(selectedCountry.continent, continentCandidates);

  // Standard capital question is shown only if givenType is not "capital"
  if (givenType != 'capital') {
    final capitalCandidates = countries
        .where((c) => c.name != selectedCountry.name)
        .map((c) => c.capital)
        .toList();
    stdCapitalOptions = generateStringOptions(selectedCountry.capital, capitalCandidates);
  } else {
    stdCapitalOptions = [];
  }

  // Inverted questions
  if (givenType == 'flag') {
    // If the main index is "flag", then ask for the country's name.
    List<String> wrongNames = countries.map((c) => c.name).toList();
    invNameOptions = generateStringOptions(selectedCountry.name, wrongNames);
  }
  if (givenType == 'name') {
    // If the main index is "name", then ask for the flag.
    List<String> wrongFlags = countries.map((c) => c.flagAsset).toList();
    invFlagOptions = generateStringOptions(selectedCountry.flagAsset, wrongFlags);
  }
  if (givenType == 'capital') {
    // For "capital", add two inverted questions: one for the name and one for the flag.
    List<String> wrongNames = countries.map((c) => c.name).toList();
    invNameOptions = generateStringOptions(selectedCountry.name, wrongNames);
    List<String> wrongFlags = countries.map((c) => c.flagAsset).toList();
    invFlagOptions = generateStringOptions(selectedCountry.flagAsset, wrongFlags);
  }

  return ChallengeQuestion(
    country: selectedCountry,
    givenType: givenType,
    invertedNameOptions: invNameOptions,
    invertedFlagOptions: invFlagOptions,
    languageOptions: languageOptions,
    populationOptions: populationOptions,
    areaOptions: areaOptions,
    continentOptions: continentOptions,
    capitalOptions: stdCapitalOptions,
  );
}


String displayOption(String questionKey, dynamic option) {
  return option.toString();
}


class ChallengePage extends StatefulWidget {
  const ChallengePage({super.key});

  @override
  _ChallengePageState createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  ChallengeQuestion? _challenge;
  // Stores the user's selected answers by question key.
  final Map<String, dynamic> _selectedAnswers = {};
  bool _submitted = false; // Becomes true when the user clicks "Validieren"

  @override
  void initState() {
    super.initState();
    loadCountries().then((countries) {
      setState(() {
        _challenge = generateChallenge(countries);
      });
    }).catchError((error) {
      print("Error in initState: $error");
    });
  }

  /// Builds the main index widget based on the chosen type.
  Widget buildIndicePrincipal() {
    if (_challenge!.givenType == 'flag') {
      final flag = _challenge!.country.flagAsset;
      return flag.startsWith('http')
          ? Image.network(flag, height: 150)
          : Image.asset(flag, height: 150);
    } else if (_challenge!.givenType == 'name') {
      return Text(
        _challenge!.country.name,
        style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
      );
    } else if (_challenge!.givenType == 'capital') {
      return Text(
        _challenge!.country.capital,
        style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    if (_challenge == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Map of correct answers for each question, using English keys.
    final Map<String, Object> correctAnswers = {
      'name': _challenge!.country.name,
      'flag': _challenge!.country.flagAsset,
      'language': _challenge!.country.languages.isNotEmpty ? _challenge!.country.languages.first : '',
      'population': _challenge!.country.population,
      'area': _challenge!.country.area,
      'continent': _challenge!.country.continent,
      'capital': _challenge!.country.capital,
    };

    return Scaffold(
      backgroundColor: Colors.amber[100],
      appBar: AppBar(title: const Text('Daily Challenge'),backgroundColor: Colors.orange,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the main index.
            buildIndicePrincipal(),
            const SizedBox(height: 50),
            // Inverted questions based on givenType.
            if (_challenge!.givenType == 'flag')
              buildQuestionSection<String>(
                questionKey: 'name',
                questionText: "Wie lautet der Name des Landes?",
                options: _challenge!.invertedNameOptions!,
                selectedOption: _selectedAnswers['name'] as String?,
                correctAnswer: correctAnswers['name'] as String,
                onOptionSelected: (value) {
                  setState(() { _selectedAnswers['name'] = value; });
                },
              ),
            if (_challenge!.givenType == 'name')
              buildFlagQuestionSection(
                questionKey: 'flag',
                questionText: "Welche Flagge gehört zu dem Land?",
                options: _challenge!.invertedFlagOptions!,
                selectedOption: _selectedAnswers['flag'] as String?,
                correctAnswer: correctAnswers['flag'] as String,
                onOptionSelected: (value) {
                  setState(() { _selectedAnswers['flag'] = value; });
                },
              ),
            if (_challenge!.givenType == 'capital') ...[
              buildQuestionSection<String>(
                questionKey: 'name',
                questionText: "Wie lautet der Name des Landes?",
                options: _challenge!.invertedNameOptions!,
                selectedOption: _selectedAnswers['name'] as String?,
                correctAnswer: correctAnswers['name'] as String,
                onOptionSelected: (value) {
                  setState(() { _selectedAnswers['name'] = value; });
                },
              ),
              buildFlagQuestionSection(
                questionKey: 'flag',
                questionText: "Welche Flagge gehört zu dem Land?",
                options: _challenge!.invertedFlagOptions!,
                selectedOption: _selectedAnswers['flag'] as String?,
                correctAnswer: correctAnswers['flag'] as String,
                onOptionSelected: (value) {
                  setState(() { _selectedAnswers['flag'] = value; });
                },
              ),
            ],
            // Standard questions.
            buildQuestionSection<String>(
              questionKey: 'language',
              questionText: "Welche Sprache wird gesprochen?",
              options: _challenge!.languageOptions,
              selectedOption: _selectedAnswers['language'] as String?,
              correctAnswer: correctAnswers['language'] as String,
              onOptionSelected: (value) {
                setState(() { _selectedAnswers['language'] = value; });
              },
            ),
            buildQuestionSection<int>(
              questionKey: 'population',
              questionText: "Wie viele Einwohner hat das Land?",
              options: _challenge!.populationOptions,
              selectedOption: _selectedAnswers['population'] as int?,
              correctAnswer: correctAnswers['population'] as int,
              onOptionSelected: (value) {
                setState(() { _selectedAnswers['population'] = value; });
              },
            ),
            buildQuestionSection<int>(
              questionKey: 'area',
              questionText: "Wie groß ist die Fläche (in km²)?",
              options: _challenge!.areaOptions,
              selectedOption: _selectedAnswers['area'] as int?,
              correctAnswer: correctAnswers['area'] as int,
              onOptionSelected: (value) {
                setState(() { _selectedAnswers['area'] = value; });
              },
            ),
            buildQuestionSection<String>(
              questionKey: 'continent',
              questionText: "Auf welchem Kontinent liegt das Land?",
              options: _challenge!.continentOptions,
              selectedOption: _selectedAnswers['continent'] as String?,
              correctAnswer: correctAnswers['continent'] as String,
              onOptionSelected: (value) {
                setState(() { _selectedAnswers['continent'] = value; });
              },
            ),
            // Show the capital question only if givenType is not "capital"
            if (_challenge!.givenType != 'capital')
              buildQuestionSection<String>(
                questionKey: 'capital',
                questionText: "Wie lautet die Hauptstadt?",
                options: _challenge!.capitalOptions,
                selectedOption: _selectedAnswers['capital'] as String?,
                correctAnswer: correctAnswers['capital'] as String,
                onOptionSelected: (value) {
                  setState(() { _selectedAnswers['capital'] = value; });
                },
              ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  //
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) return;
                  //
                  // Determine required keys based on givenType.
                  List<String> requiredKeys;
                  if (_challenge!.givenType == 'capital') {
                    requiredKeys = ['name', 'flag', 'language', 'population', 'area', 'continent'];
                  } else if (_challenge!.givenType == 'flag') {
                    requiredKeys = ['name', 'language', 'population', 'area', 'continent', 'capital'];
                  } else { // givenType == 'name'
                    requiredKeys = ['flag', 'language', 'population', 'area', 'continent', 'capital'];
                  }
                  // Check whether all required questions have been answered.
                  bool allAnswered = requiredKeys.every(
                    (key) => _selectedAnswers.containsKey(key) && _selectedAnswers[key] != null
                  );
                  if (!allAnswered) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Error"),
                        content: const Text("Bitte beantworten Sie alle Fragen.",
                          style: TextStyle(fontSize: 20),),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("OK",
                            
                          style: TextStyle(fontSize: 20, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    );
                    return; // Do not continue.
                  }

                  setState(() { _submitted = true; });
                  bool isCorrect = true;
                  int correctCount = 0; /// Counter for corrects Answers
                  _selectedAnswers.forEach((key, value) {
                    if (value == correctAnswers[key]) {
                      correctCount++;
                      }else{
                      isCorrect = false;
                    }
                  });

                  final int finalScore = correctCount;
                  final List<dynamic> userAnswers =
                      requiredKeys
                          .map((key) => {
                                'question': key,
                                'answer': _selectedAnswers[key]
                              }).toList();

                  await DailyChallengeService
                      .submitChallenge(
                    uid: uid,
                    score: finalScore,
                    answers: userAnswers,
                  );
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(isCorrect ? "Gut gemacht!" : "Versuchen Sie es noch einmal"),
                      content: Text(isCorrect? 
                      "Alle Antworten sind korrekt.\nScore: $finalScore/${requiredKeys.length}"
                      :"Einige Antworten sind falsch.\nScore: $finalScore/${requiredKeys.length}",
                          
                          style: TextStyle(fontSize: 20),
                          ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("OK",
                          style: TextStyle(fontSize: 20, color: Colors.black),
                          ),
                        )
                      ],
                    ),
                  );
                },
                
                child: const Text("Validieren",
                  style: TextStyle(fontSize: 40, color: Colors.orange),
                
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generic widget for a text-based question using ChoiceChips.
  Widget buildQuestionSection<T>({
    required String questionKey,
    required String questionText,
    required List<T> options,
    required T? selectedOption,
    required T correctAnswer,
    required void Function(T) onOptionSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionText,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 8.0,
            children: options.map((option) {
              final bool isCorrectOption = option == correctAnswer;
              final bool isUserSelected = (selectedOption == option);
              final bool showAsSelected = _submitted ? (isCorrectOption || isUserSelected) : isUserSelected;
              Color chipColor;
              if (_submitted) {
                if (isCorrectOption) {
                  chipColor = Colors.green;
                } else if (isUserSelected && !isCorrectOption) {
                  chipColor = Colors.red;
                } else {
                  chipColor = Colors.grey.shade300;
                }
              } else {
                chipColor = Colors.grey.shade300;
              }
              return ChoiceChip(
                label: Text(displayOption(questionKey, option),
                style: TextStyle(color:Colors.black, fontSize: 20),
                ),
                selected: showAsSelected,
                selectedColor: chipColor,
                backgroundColor: chipColor,
                onSelected: _submitted ? null : (_) => onOptionSelected(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Widget for a flag-based question using ChoiceChips.
  Widget buildFlagQuestionSection({
    required String questionKey,
    required String questionText,
    required List<String> options,
    required String? selectedOption,
    required String correctAnswer,
    required void Function(String) onOptionSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionText,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 8.0,
            children: options.map((flagPath) {
              final bool isCorrectOption = flagPath == correctAnswer;
              final bool isUserSelected = selectedOption == flagPath;
              final bool showAsSelected = _submitted ? (isCorrectOption || isUserSelected) : isUserSelected;
              Color chipColor;
              if (_submitted) {
                if (isCorrectOption) {
                  chipColor = Colors.green;
                } else if (isUserSelected && !isCorrectOption) {
                  chipColor = Colors.red;
                } else {
                  chipColor = Colors.grey.shade300;
                }
              } else {
                chipColor = Colors.grey.shade300;
              }
              return ChoiceChip(
                label: flagPath.startsWith('http')
                    ? Image.network(flagPath, width: 70, height: 50, fit: BoxFit.cover)
                    : Image.asset(flagPath, width: 70, height: 50, fit: BoxFit.cover),
                selected: showAsSelected,
                selectedColor: chipColor,
                backgroundColor: chipColor,
                onSelected: _submitted ? null : (_) => onOptionSelected(flagPath),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

