  import 'package:flutter/material.dart';
  import 'package:flutter_map/flutter_map.dart';

  import 'package:latlong2/latlong.dart';
  import 'dart:convert';
  import '../data/geojson_parse_through.dart';
  import '../domain/models/country.dart';
  import '../../home/ui/widgets/logout_button.dart';
  import 'package:syncfusion_flutter_maps/maps.dart';
  import 'dart:math';
  import 'dart:typed_data';

  class ClickOnMapPage extends StatefulWidget{
    @override
    _ClickOnMapPage createState() => _ClickOnMapPage();
  }



  class _ClickOnMapPage extends State<ClickOnMapPage> {
    void _logout(BuildContext context) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ausgeloggt')),
      );
    }

    late MapZoomPanBehavior _zoomPanBehavior;
    int selectedIndex = -1;

    List<Country> _countries = [];
    late MapShapeLayerController _controller;
    Map<String, Color> _countryColors = {};
    List<LatLng> _polygon = [];
    List<Country> _remainingCountries = [];
    String _currentCountry = '';
    String? _selectedCountry;
    bool _isCorrect = false;
    int _attemptCounter = 0;
    bool _isdoing = true;
    late MapShapeSource? _mapShapeSource;
    int _tappedIndex = 0;
    String? _geoJsonRawString;



    @override
    void initState() {
      super.initState();
      _controller = MapShapeLayerController();
      _zoomPanBehavior = MapZoomPanBehavior(
        enableDoubleTapZooming: true,
        enablePinching:true,
        enableMouseWheelZooming: true,
        toolbarSettings: MapToolbarSettings(
          position: MapToolbarPosition.topLeft,
      ),
      );


      _remainingCountries = [];
      _mapShapeSource = null;
      _loadGeoJsonData();

    }


    Future<void> _loadGeoJsonData() async {
      try {
        _geoJsonRawString = await DefaultAssetBundle.of(context).loadString(
            'lib/features/click_on_map_country/assets/custom.geo.json');
        GeoJsonParser parser = GeoJsonParser(
            'lib/features/click_on_map_country/assets/custom.geo.json');

        List<Country> countries = await parser.parseGeoJsonFromString(_geoJsonRawString!);


        if (countries.isEmpty) {
          print("Fehler: Keine Länder geladen");
          setState(() {
            _isdoing = false; // Set loading to false even if empty
          });
          return;
        }
        setState(() {
          _countries = countries;
          _countryColors = { for (var country in _countries) country.name!: Colors.transparent };
          _mapShapeSource = MapShapeSource.memory(
            Uint8List.fromList(utf8.encode(_geoJsonRawString!)),
            shapeDataField: "name_de",
            primaryValueMapper: (int index) {
              if (index >= 0 && index < _countries.length) {
                return _countries[index].name;
              }
              return 'Unknown';
            },
            dataCount: _countries.length,
            shapeColorValueMapper: (int index) {
              if (index >= 0 && index < _countries.length) {
                final countryName = _countries[index].name;
                return _countryColors[countryName] ?? Colors.transparent;
              }
              return Colors.transparent;
            },
          );

          _setNextCountry();
          _isdoing = false;
        });

      } catch (e) {
        print("Fehler beim Laden der GeoJson-Daten: $e");
        setState(() {
          _isdoing = false;
        });
        return;
      }
    }

    void _initializeMapSource() {



      _mapShapeSource = MapShapeSource.memory(

        Uint8List.fromList(utf8.encode(_geoJsonRawString!)),

        shapeDataField: "name_de",

        primaryValueMapper: (int index) {

          if (index >= 0 && index < _countries.length) {

            return _countries[index].name;

          }

          return 'Unknown';

        },

        dataCount: _countries.length,

        shapeColorValueMapper: (int index) {

          if (index >= 0 && index < _countries.length) {

            final countryName = _countries[index].name;

            return _countryColors[countryName] ?? Colors.transparent;

          }

          return Colors.transparent;

        },

      );





    }





    void _countryTapped(int index) async {

      //if (_isdoing) return;
      if (_countries.isEmpty) {
        print("Error: No countries loaded into _countries list.");
      }

      String tappedCountryName = _countries[index].name;

      if (tappedCountryName == _currentCountry) {
        setState(() {
          _isdoing = true;
          _polygon = _countries.firstWhere((country) => country.name == tappedCountryName).polygons[0];
          _countryColors[tappedCountryName] = Colors.green;

          selectedIndex = index;
          _remainingCountries.removeWhere((country) =>
          country.name == tappedCountryName);
        });

        await Future.delayed(Duration(seconds: 1));
        if (_zoomPanBehavior != null) {
          _zoomPanBehavior.reset();

        } else {
          print("Error: _zoomPanBehavior is null.");
        }
        _setNextCountry();
      }
      else {
        setState(() {
          _countryColors[_countries[index].name] = Colors.red;
          _attemptCounter++;
          selectedIndex = index;

        });


        if (_attemptCounter >= 3) {

          setState(() {
            _zoomPanBehavior.reset();
            _countryColors[_currentCountry] = Colors.green;
            _countryColors[_countries[index].name] = Colors.red;
            selectedIndex = _countries.indexWhere((country) =>
            country.name == _currentCountry);
            _remainingCountries.removeWhere((country) =>
            country.name == _currentCountry);
            _isdoing = true;
          });

          await Future.delayed(Duration(seconds:1));
          if (mounted && _zoomPanBehavior != null) {
          }


          await Future.delayed(Duration(seconds: 2));
          if(_zoomPanBehavior != null) {
            _zoomPanBehavior.reset();


            if (_remainingCountries.isNotEmpty) {
              _setNextCountry();
            }
          }

        } else {
          await Future.delayed(Duration(seconds: 1));
          setState(() {
            selectedIndex = -1;
            if (_countryColors.containsKey(tappedCountryName)) {
              _countryColors.remove(tappedCountryName);
            }
            _isdoing = false;

          });
        }
      }
      setState(() {
        _isdoing = false;
      });
    }


    void _setNextCountry() {

      //if (_isdoing) return;
      if (_remainingCountries.isEmpty) {
        setState(() {
          _remainingCountries = List.from(_countries);
        });
      }
      if (_remainingCountries.isEmpty) {
        print("Remaining List is empty:reinitializing");
         _remainingCountries = List.from(_countries);

      }
      if (_remainingCountries.isEmpty) {
        print("Remaining Countries are still empty");
        return;
      }
      setState(() {
        _isdoing = false;
        if(_countries.isNotEmpty) {
          _currentCountry = (_countries.toList()..shuffle()).first.name;
          _selectedCountry = _currentCountry;
          _countryColors = { for (var country in _countries) country.name!: Colors.transparent};
        }

      });


      final Random random = Random();
      int randomindex = random.nextInt(_remainingCountries.length);
      final Country newCountry = _remainingCountries[randomindex];
      setState(() {
        _currentCountry = newCountry.name!;
        _selectedCountry = _currentCountry;
        _attemptCounter = 0;
        selectedIndex = -1;
        _isdoing = false;

        _countryColors = { for (var country in _countries) country.name!: Colors.transparent };

      });
    }


    @override
    Widget build(BuildContext context) {


          if(_mapShapeSource == null){
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Theme
                    .of(context)
                    .primaryColor,
                title: Text(
                  'Country Quiz',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return Scaffold(
            appBar: AppBar(backgroundColor: Theme
                .of(context)
                .primaryColor,
              title: Text('Country Quiz',
                style: TextStyle(color: Colors.white),
              ),
              leading: IconButton(icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              actions: [
                LogoutButton(onLogout: () => _logout(context)),
              ],


            ),
            body: Stack(
              children: [
                SfMaps(
                  layers: <MapShapeLayer>[

                    MapShapeLayer(
                      source: _mapShapeSource!,
                      zoomPanBehavior: _zoomPanBehavior,
                      controller: _controller,
                      selectedIndex: selectedIndex,
                      selectionSettings: MapSelectionSettings(
                        color:  selectedIndex != -1
                            ? _countryColors[_countries[selectedIndex].name] ?? Colors.transparent
                            : Colors.transparent,/*Color.fromRGBO(252, 177, 0, 1),*/
                        strokeColor: Colors.white,
                        strokeWidth: 2,
                      ),

                      onSelectionChanged: (int index) {
                        if(!_isdoing) {
                          setState(() {
                            selectedIndex = (selectedIndex == index) ? -1 : index;
                            if (selectedIndex != -1) {
                              _countryTapped(index);
                            }
                          });

                        }
                      },



                    ),


                  ],
                ),



                Positioned(top: 20, right: 20,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${3 -_attemptCounter} Versuche übrig\nAktuelles Land: $_currentCountry',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                      ],
                    ),
                  ),

                ),
              ],

            ),




      );
    }
  }

