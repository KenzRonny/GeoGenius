
import 'package:latlong2/latlong.dart';


class Country{
  final String name;
  final List<List<LatLng>> polygons;

  Country({required this.name, required this.polygons});
}