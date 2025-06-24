
import 'package:latlong2/latlong.dart';

class Ccountry{
  String name;
  String capital;
  String cca3;
  final LatLng? capitalLatLng;
  final List<List<LatLng>> polygons;

  Ccountry({required this.name, required this.capital,required this.cca3,this.capitalLatLng,required this.polygons});
}