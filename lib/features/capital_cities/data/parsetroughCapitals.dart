// lib/data/country_data_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/Countries_capital.dart';

// Hilfsfunktion für Polygon-Konvertierung
List<LatLng> _convertPolygonCoordinates(List<dynamic> coordinates){
  if (coordinates.isEmpty ||  (coordinates[0] is! List)) {
    return [];
  }
  // GeoJSON-Koordinaten sind oft [Longitude, Latitude]
  // LatLng ist LatLng(Latitude, Longitude)
  final List<dynamic> pointsList = coordinates[0];
  return pointsList.map<LatLng>((point) {
    if (point is List && point.length >= 2 && point[0] is num && point[1] is num) {
      return LatLng(point[1].toDouble(), point[0].toDouble());
    }

    //print('Warnung: Ungültiger Koordinatenpunkt im Polygon: $point');
    return LatLng(0,0);
  }).toList();
}

class RawCountryData {
  final String detailedJsonString;
  final String geoJsonString;

  RawCountryData({required this.detailedJsonString, required this.geoJsonString});
}
Future<List<Ccountry>> _loadAndMergeCountryDataInBackground(RawCountryData rawData) async {
  final String detailedGeoString = rawData.detailedJsonString;
  final String geoJsonWithPolygonsString = rawData.geoJsonString;


  final List<dynamic> rawDetailedCountries = json.decode(detailedGeoString);
  List<Ccountry> detailedCountries = [];
  for (var rawCountry in rawDetailedCountries) {
    if (rawCountry is! Map<String, dynamic>) continue;


    String name = 'N/A';
    if (rawCountry.containsKey('name') && rawCountry['name'] is Map && rawCountry['name'].containsKey('common')) {
      name = rawCountry['name']['common'];
    }
    if (rawCountry.containsKey('translations') && rawCountry['translations'] is Map && rawCountry['translations'].containsKey('deu') && rawCountry['translations']['deu'] is Map && rawCountry['translations']['deu'].containsKey('common')) {
      name = rawCountry['translations']['deu']['common'];
    }


    String capital = 'N/A';
    if (rawCountry.containsKey('capital') && rawCountry['capital'] is List && rawCountry['capital'].isNotEmpty) {
      capital = rawCountry['capital'].first.toString();
    } else if (rawCountry.containsKey('capital') && rawCountry['capital'] is String) {
      capital = rawCountry['capital'];
    }


    LatLng? capitalLatLng;
    if (rawCountry.containsKey('capitalInfo') && rawCountry['capitalInfo'] is Map && rawCountry['capitalInfo'].containsKey('latlng') && rawCountry['capitalInfo']['latlng'] is List && rawCountry['capitalInfo']['latlng'].length >=2) {
      capitalLatLng = LatLng(rawCountry['capitalInfo']['latlng'][0].toDouble(), rawCountry['capitalInfo']['latlng'][1].toDouble());
    } else if (rawCountry.containsKey('latlng') && rawCountry['latlng'] is List && rawCountry['latlng'].length >=2) {

      capitalLatLng = LatLng(rawCountry['latlng'][0].toDouble(), rawCountry['latlng'][1].toDouble());
    }


    String cca3 = rawCountry['cca3'] ?? 'N/A';


    detailedCountries.add(Ccountry(
      name: name,
      capital: capital,
      cca3: cca3,
      capitalLatLng: capitalLatLng,
      polygons: [],
    ));
  }
  //print('Detaillierte Länder geladen: ${detailedCountries.length}');



  final Map<String, dynamic> geoJsonData = json.decode(geoJsonWithPolygonsString);
  if (!geoJsonData.containsKey('features') || geoJsonData['features'] is! List) {
    //print('Warnung: GeoJSON Polygon-Datei hat keine oder ungültige "features"-Liste.');
    return detailedCountries;
  }


  for (var rawFeature in geoJsonData['features']) {
    if (rawFeature is! Map<String, dynamic>) continue;
    Map<String, dynamic> feature = rawFeature;

    final properties = feature['properties'];
    final geometry = feature['geometry'];

    if (properties is! Map<String, dynamic> || !properties.containsKey('adm0_a3')) {
      continue; // Brauchen 'adm0_a3' zum Verknüpfen
    }
    String cca3FromGeoJson = properties['adm0_a3'];

    Ccountry? matchingCountry = detailedCountries.firstWhere(
          (country) => country.cca3 == cca3FromGeoJson,
      orElse: () => Ccountry(name: 'NotFound', capital: 'NotFound', cca3: 'NotFound', polygons: []), // Dummy-Objekt oder null
    );

    if (matchingCountry.cca3 == 'NotFound') {
      // print('Keine passende detaillierte Landinfo für CCA3: $cca3FromGeoJson gefunden.');
      continue;
    }

    List<List<LatLng>> countryPolygons = [];
    if (geometry is Map<String, dynamic> && geometry.containsKey('type') && geometry.containsKey('coordinates')) {
      if (geometry['type'] == 'Polygon') {
        if (geometry['coordinates'] is List && geometry['coordinates'].isNotEmpty) {
          countryPolygons.add(_convertPolygonCoordinates(geometry['coordinates']));
        }
      } else if (geometry['type'] == 'MultiPolygon') {
        for (var polygonCoordinates in geometry['coordinates']) {
          if (polygonCoordinates is List && polygonCoordinates.isNotEmpty) {
            countryPolygons.add(_convertPolygonCoordinates(polygonCoordinates));
          }
        }
      }
    }

   int index = detailedCountries.indexOf(matchingCountry);
    if (index != -1) {
      detailedCountries[index] = Ccountry(
        name: matchingCountry.name,
        capital: matchingCountry.capital,
        capitalLatLng: matchingCountry.capitalLatLng,
        cca3: matchingCountry.cca3,
        polygons: countryPolygons,
      );
    }
  }

  //print('Geladene und zusammengeführte Länder: ${detailedCountries.length}');
  return detailedCountries;
}


class CountryDataLoader {

  final String detailedCountriesPath;
  final String geoJsonPolygonsPath;




  CountryDataLoader({required this.detailedCountriesPath, required this.geoJsonPolygonsPath});

  Future<List<Ccountry>> loadCountriesWithPolygons() async {
    try {

      final String detailedGeoString = await rootBundle.loadString(detailedCountriesPath);
      final String geoJsonWithPolygonsString = await rootBundle.loadString(geoJsonPolygonsPath);

      final RawCountryData dataToProcess = RawCountryData(
        detailedJsonString: detailedGeoString,
        geoJsonString: geoJsonWithPolygonsString,
      );


      return compute(_loadAndMergeCountryDataInBackground, dataToProcess);

    } catch (e) {
      //print('Fehler beim Laden oder Zusammenführen der Länderdaten: $e');
      return [];
    }
  }
}
