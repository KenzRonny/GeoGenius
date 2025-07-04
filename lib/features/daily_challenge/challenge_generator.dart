/*
  challenge-generation logic:
  - ChallengeQuestion holds the randomized quiz data for one country.
  - generateChallenge(countries) picks a random country,
    decides which field to show (flag, name, or capital),
    builds standard and inverted question options.
  - String/int option generators ensure exactly three choices.
  - displayOption formats any given option .
*/

import 'dart:math';
import '../daily_challenge/countries_data.dart';

/// Represents one question block within the Daily Challenge.
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

////// Generates a list of string options excluding the correct value.
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

  ////Standard options for language, population, area, and continent.
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

  //// Standard capital question is shown only if givenType is not "capital"
  if (givenType != 'capital') {
    final capitalCandidates = countries
        .where((c) => c.name != selectedCountry.name)
        .map((c) => c.capital)
        .toList();
    stdCapitalOptions = generateStringOptions(selectedCountry.capital, capitalCandidates);
  } else {
    stdCapitalOptions = [];
  }

  //// Inverted questions
  if (givenType == 'flag') {
    //// If the main index is "flag", then ask for the country's name.
    List<String> wrongNames = countries.map((c) => c.name).toList();
    invNameOptions = generateStringOptions(selectedCountry.name, wrongNames);
  }
  if (givenType == 'name') {
    /// If the main index is "name", then ask for the flag.
    List<String> wrongFlags = countries.map((c) => c.flagAsset).toList();
    invFlagOptions = generateStringOptions(selectedCountry.flagAsset, wrongFlags);
  }
  if (givenType == 'capital') {
    //// For "capital", add two inverted questions: one for the name and one for the flag.
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

/////Formats any option for display.
String displayOption(String questionKey, dynamic option) {
  return option.toString();
}
