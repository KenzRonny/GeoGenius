

  import 'package:geo_genius/features/capital_cities/data/parsetroughCapitals.dart';
  import 'package:geo_genius/features/capital_cities/domain/models/Countries_capital.dart';
  import 'package:syncfusion_flutter_maps/maps.dart';
  import 'package:flutter/material.dart';
  import 'package:syncfusion_flutter_core/theme.dart';
  import 'dart:math';


  class ClickOnCapitalPage extends StatefulWidget {
    const ClickOnCapitalPage({super.key});

    @override
    _ClickOnCapitalPage createState() => _ClickOnCapitalPage();
  }

  class _ClickOnCapitalPage extends State<ClickOnCapitalPage> {
    late MapZoomPanBehavior _zoomPanBehavior;
    late MapShapeLayerController _controller;

    int _selectedIndex = -1; // Der Index des aktuell ausgewählten (getippten) Shapes

    String _currentCapitalQuestion = ''; // Die Hauptstadt, die gesucht wird
    Ccountry? _correctCountryForQuestion; // Das Land, dessen Hauptstadt gesucht wird

    List<Ccountry> _allCountries = []; // Alle geladenen Länder mit Polygonen und Details
    List<Ccountry> _remainingCountriesForGame = []; // Länder, die noch nicht "gefunden" wurden

    bool _isLoading = true;
    String _errorMessage = '';
    int _attemptCounter = 0; // Versuche für die aktuelle Frage

    // Die Anzahl der Marker, die wir auf der Karte haben möchten.
    // Standardmäßig 0, wird aktualisiert, wenn eine Hauptstadt angezeigt werden soll.
    int _markerCount = 0;
    final double _dataLabelMinZoomLevel = 3.0;
    double _currentZoomLevel = 1.0;
    bool get _shouldShowLabels => _currentZoomLevel >= _dataLabelMinZoomLevel;
    @override
    void initState() {
      super.initState();
      _zoomPanBehavior = MapZoomPanBehavior(
        enableDoubleTapZooming: true,
        enablePinching: true,
        enableMouseWheelZooming: true,
        toolbarSettings: const MapToolbarSettings(
          position: MapToolbarPosition.topLeft,

        ),



      );
      _controller = MapShapeLayerController();
      _loadAllCountryData();
    }

  @override
  void dispose() {


    _controller.dispose();
    super.dispose();
  }

    // Listener callback function

    Future<void> _loadAllCountryData() async {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final dataLoader = CountryDataLoader(
          detailedCountriesPath: 'assets/json/countries/countries.json',
          geoJsonPolygonsPath: 'lib/features/click_on_map_country/assets/custom.geo.json',
        );
        final loadedCountries = await dataLoader.loadCountriesWithPolygons();

        final validCountries = loadedCountries.where(
                (country) => country.polygons.isNotEmpty && country.capital != 'N/A' && country.capitalLatLng != null
        ).toList();

        if (validCountries.isEmpty) {
          setState(() {
            _errorMessage = 'Keine gültigen Länderdaten (Polygone/Hauptstädte) zum Spielen gefunden. Überprüfe JSON-Pfade und Daten.';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _allCountries = validCountries;
          _remainingCountriesForGame = List.from(_allCountries);
          _isLoading = false;
        });

        _setNextCapitalQuestion();
      } catch (e) {
        //print("Fehler beim Laden oder Parsen der Länderdaten: $e");
        setState(() {
          _errorMessage = 'Fehler beim Laden der Länderdaten: $e';
          _isLoading = false;
        });
      }
    }

    void _setNextCapitalQuestion() {
      setState(() {
        _markerCount = 0; // Marker zurücksetzen, wenn eine neue Frage gestellt wird
        _selectedIndex = -1; // Auswahl zurücksetzen
      });

      if (_remainingCountriesForGame.isEmpty) {
        _remainingCountriesForGame = List.from(_allCountries);
        if (_remainingCountriesForGame.isEmpty) {
          setState(() {
            _currentCapitalQuestion = 'Keine Länder zum Spielen.';
            _correctCountryForQuestion = null;
          });
          return;
        }
      }

      final Random random = Random();
      if (_remainingCountriesForGame.isEmpty) {
        _currentCapitalQuestion = 'Keine Länder mehr übrig.';
        _correctCountryForQuestion = null;
        return;
      }
      final int randomIndex = random.nextInt(_remainingCountriesForGame.length);
      final Ccountry countryToGuess = _remainingCountriesForGame[randomIndex];

      setState(() {
        _currentCapitalQuestion = countryToGuess.capital;
        _correctCountryForQuestion = countryToGuess;
        _attemptCounter = 0;
        _zoomPanBehavior.reset();
      });

    }

    void _onCountryTapped(int index) async {
      if (_isLoading || _correctCountryForQuestion == null || index < 0 || index >= _allCountries.length) {
        return;
      }

      final Ccountry tappedCountry = _allCountries[index];

      if (tappedCountry.name == _correctCountryForQuestion!.name) {
        setState(() {
          _selectedIndex = index;
          _remainingCountriesForGame.removeWhere((country) => country.name == tappedCountry.name);
          _zoomPanBehavior.reset();
          _currentZoomLevel = _zoomPanBehavior.zoomLevel;
        });

        if (_correctCountryForQuestion!.capitalLatLng != null) {
          final MapLatLng targetLatLng = MapLatLng(
            _correctCountryForQuestion!.capitalLatLng!.latitude,
            _correctCountryForQuestion!.capitalLatLng!.longitude,
          );
          _zoomPanBehavior.zoomLevel = 5.0;
          _zoomPanBehavior.focalLatLng = targetLatLng;
          setState(() {
            _currentZoomLevel = _zoomPanBehavior.zoomLevel;
          });
        }

        await Future.delayed(const Duration(seconds: 1));
        _setNextCapitalQuestion();
      } else {
        setState(() {
          _selectedIndex = index;
          _attemptCounter++;
        });

        if (_attemptCounter >= 3) {
          setState(() {
            if (_correctCountryForQuestion != null) {
              _selectedIndex = _allCountries.indexOf(_correctCountryForQuestion!);
              if (_correctCountryForQuestion!.capitalLatLng != null) {
                final MapLatLng targetLatLng = MapLatLng(
                  _correctCountryForQuestion!.capitalLatLng!.latitude,
                  _correctCountryForQuestion!.capitalLatLng!.longitude,
                );
                _zoomPanBehavior.zoomLevel = 5.0;
                _zoomPanBehavior.focalLatLng = targetLatLng;


              }
            }
          });
          setState(() {});
          await Future.delayed(const Duration(seconds: 2));

            _zoomPanBehavior.reset();
          _currentZoomLevel = _zoomPanBehavior.zoomLevel;
          _remainingCountriesForGame.removeWhere((country) => country.name == _correctCountryForQuestion!.name);
          _setNextCapitalQuestion();
        } else {
          await Future.delayed(const Duration(milliseconds: 700));
          setState(() {
            _selectedIndex = -1;
            });
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      if (_isLoading || _errorMessage.isNotEmpty) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            title: const Text('Capital Quiz', style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Fehler: $_errorMessage'),
                ElevatedButton(
                  onPressed: _loadAllCountryData,
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        );
      }


      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: const Text(
            'Capital Quiz',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),

        body: Stack(

          children: [
            SfMapsTheme(
              data:const SfMapsThemeData(
                shapeHoverColor: Colors.transparent,
              ),


            child:SfMaps(
              layers: <MapLayer>[

                MapShapeLayer(





                  source: MapShapeSource.asset(
                    'lib/features/click_on_map_country/assets/custom.geo.json',
                    shapeDataField: 'adm0_a3',
                    dataLabelMapper: _shouldShowLabels
                        ? (int index) {
                      if (index >= 0 && index < _allCountries.length) {
                        return _allCountries[index].name;
                      }
                      return '';
                    }
                        : null,

                    primaryValueMapper: (int index) {
                      if (index >= 0 && index < _allCountries.length) {
                        return _allCountries[index].cca3;
                      }
                      return '';
                    },






                    dataCount: _allCountries.length,
                    shapeColorValueMapper: (int index) {
                      if (index < 0 || index >= _allCountries.length) {
                        return Colors.transparent;
                      }
                      if (index == _selectedIndex) {
                        final Ccountry tappedCountry = _allCountries[index];

                        if (_correctCountryForQuestion != null && tappedCountry.name == _correctCountryForQuestion!.name) {
                          return Colors.green.withAlpha((255 * 0.7).round());
                        } else {
                          return Colors.red.withAlpha((255 * 0.7).round());
                        }


                      }

                      if (_remainingCountriesForGame.any((c) => c.name == _allCountries[index].name)) {
                        return Colors.grey.withAlpha((255 * 0.3).round());
                      }
                      return Colors.blueGrey.withAlpha((255 * 0.1).round());
                    },

                  ),
                  zoomPanBehavior: _zoomPanBehavior,
                  controller: _controller,
                  selectedIndex: _selectedIndex,
                  onSelectionChanged: (int index) {
                    _onCountryTapped(index);
                  },
                  onWillZoom: (MapZoomDetails details) {

                    if (_currentZoomLevel != details.newZoomLevel!) {
                      setState(() {
                        _currentZoomLevel = details.newZoomLevel!;
                         //print('onWillZoom: New Zoom Level: $_currentZoomLevel'); // Debugging
                      });
                    }
                    return true;
                  },
                  selectionSettings:  MapSelectionSettings(

                    color: Colors.transparent,
                    strokeColor: Colors.white,
                    strokeWidth: 2,
                  ),
                  color: Colors.grey.withAlpha((255 * 0.3).round()),
                  strokeColor: Colors.black,
                  strokeWidth: 0.5,
                  showDataLabels: _currentZoomLevel >= _dataLabelMinZoomLevel,
                  dataLabelSettings: MapDataLabelSettings(
                    textStyle: TextStyle(
                      color: Colors.black,
                      fontSize: 5,
                      fontWeight: FontWeight.bold,
                    ),


                  ),
                ),

          ],
            ),
          ),





            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
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
                    Text(
                      '${3 - _attemptCounter} Versuche übrig\nAktuelle Hauptstadt: $_currentCapitalQuestion',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
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



