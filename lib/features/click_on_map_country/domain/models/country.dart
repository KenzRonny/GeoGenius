import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

class Country{
  final String name;
  final List<List<LatLng>> polygons;

  Country({required this.name, required this.polygons});
}