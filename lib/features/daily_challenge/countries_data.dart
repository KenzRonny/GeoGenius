/*
  Defines the Country data model and JSON loader.
  - Country.fromJson maps a raw JSON entry to a Country instance.
  - loadCountries() reads the countries.json asset,
    decodes its content, and returns a list of Country objects.
*/

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    /// Get the common german name or default to 'Unknown'
    final name = (json['name'] is Map && json["translations"]["deu"]["common"] != null)
        ? json["translations"]["deu"]["common"] as String
        : 'Unknown';

    
    final languagesData = json['languages'];
    List<String> languages = [];
    if (languagesData is Map<String, dynamic>) {
      languages = List<String>.from(languagesData.values);
    }

    
    final population = json['population'] is int ? json['population'] as int : 0;
    final area = json['area'] is num ? (json['area'] as num).toInt() : 0;

   
    final continentsData = json['continents'];
    final continent =
        (continentsData is List && continentsData.isNotEmpty)
            ? continentsData[0] as String
            : 'Unknown';

    //// Get flag asset from the 'png' field.
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

//// Loads the JSON file from assets.
Future<List<Country>> loadCountries() async {
  try {
    final jsonString = await rootBundle.loadString('assets/json/countries/countries.json');
    final List<dynamic> data = jsonDecode(jsonString);
    return data
        .where((item) => item != null)
        .map((item) => Country.fromJson(item as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint("Error loading or parsing JSON: $e");
    rethrow;
  }
}
