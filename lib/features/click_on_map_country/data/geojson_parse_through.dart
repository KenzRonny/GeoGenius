import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../domain/models/country.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:flutter_map/flutter_map.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

List<LatLng> _convertCoordinates(List<dynamic> coordinates){

  return coordinates[0].map<LatLng>((point){

      return LatLng(point[1].toDouble(), point[0].toDouble());

  }).toList();
}


List<Country> parseGeoJsonInBackground(String geoJsonString) {
  final Map<String, dynamic> geoJsonData = json.decode(geoJsonString);
  List<Country> countries = [];

  for (var feature in geoJsonData['features']) {
    final String name = feature['properties']['name_de'];
    final geometry = feature['geometry'];


    List<List<LatLng>> polygons = [];
    if (geometry['type'] == 'Polygon') {
      polygons.add(_convertCoordinates(geometry['coordinates']));
    }
    else if (geometry['type'] == 'MultiPolygon') {
      for (var polygon in geometry['coordinates']) {
        polygons.add(_convertCoordinates(polygon));
      }
    }

    countries.add(Country(name: name, polygons: polygons));
  }
  return countries;
}


class GeoJsonParser{
  final String filepath;
  GeoJsonParser(this.filepath);

  Future<List<Country>> parseGeoJson()async {
    try {
      final String geoJsonString = await rootBundle.loadString(
          'lib/features/click_on_map_country/assets/custom.geo.json');
      return compute(parseGeoJsonInBackground, geoJsonString);

    }catch(e){
      print('Fehler beim Laden oder Parsen der GeoJson-Datei: $e');
      return[];
    }

  }

Future<List<Country>> parseGeoJsonFromString(String geoJsonString)async{
  try {
    return compute(parseGeoJsonInBackground, geoJsonString);
  } catch (e) {
    // Fehler beim Parsen der GeoJson-Zeichenkette.
    return [];
  }
}

}