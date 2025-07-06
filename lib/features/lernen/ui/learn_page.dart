import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //for loading assets
import 'widgets/country_item_list.dart';
import 'widgets/country_item_grid.dart';
import 'widgets/country_item_flashcard.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LearnPageState createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  List<dynamic> allCountries = [];
  List<dynamic> filteredCountries = [];
  TextEditingController searchController = TextEditingController();

  String selectedContinent = "All";
  final List<String> continents = [
    "All",
    "Africa",
    "Americas",
    "Asia",
    "Europe",
    "Oceania",
    "Antarctica",
  ];

  String displayMode = "list"; // default display mode

  //loads the JSON file containing the countries' data from the assets.
  Future<void> loadCountries() async {
    // Load the JSON content as a string from the assets directory.
    String jsonString = await rootBundle.loadString(
      'assets/json/countries/countries.json',
    );
    // Decode the JSON string into a List of dynamic objects.
    final List<dynamic> jsonData = jsonDecode(jsonString);

    String normalizeName(String name) {
  return name.toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll('å', 'ae');
}
    
    jsonData.sort((a, b) {
  final String aName = normalizeName(a["translations"]["deu"]["common"] as String);
  final String bName = normalizeName(b["translations"]["deu"]["common"] as String);
  return aName.compareTo(bName);
});

    setState(() {
      allCountries = jsonData;
      filteredCountries = jsonData;
    });
  }

  void filterCountries() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredCountries =
          allCountries.where((country) {
            //filtering by name
            final String name =
                (country["translations"]["deu"]["common"] as String).toLowerCase();
            bool matchesName = name.contains(query);

            final dynamic continentData = country["region"];
            List<dynamic> continentList = [];
            if (continentData is List) {
              continentList = continentData;
            } else if (continentData is String) {
              continentList = [continentData];
            }
            final String countryContinent =
                (continentList.isNotEmpty)
                    ? continentList.first.toString()
                    : "";
            bool matchesContinent =
                (selectedContinent == "All") ||
                (countryContinent.toLowerCase() ==
                    selectedContinent.toLowerCase());
            return matchesName && matchesContinent;
          }).toList();
    });
  }
  
/// Displays a detailed info dialog for the tapped country
  void _showCountryDetails(dynamic country) {
    final String name =
        country["translations"]["deu"]["common"] ?? "Unknown";
    final dynamic capitalData = country["capital"];
    List<dynamic> capitalList = [];
    if (capitalData is List) {
      capitalList = capitalData;
    } else if (capitalData is String) {
      capitalList = [capitalData];
    }
    final String capital = capitalList.isNotEmpty
        ? capitalList.first.toString()
        : "No capital";
    final String flagUrl = country["flags"]?["png"] ?? "";
    final String continent = (country["region"] is List
            ? (country["region"] as List).first
            : country["region"])
        .toString();
    final String population =
        (country["population"] ?? "Unknown").toString();
    final String area = (country["area"] ?? "Unknown").toString();
    final List<dynamic> langData = country["languages"] is Map
        ? (country["languages"] as Map).values.toList()
        : [];
    final String languages =
        langData.map((l) => l.toString()).join(', ');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (flagUrl.isNotEmpty)
                Image.network(flagUrl, height: 100)
              else
                const Icon(Icons.flag, size: 100),
              const SizedBox(height: 12),
              Text("Hauptstadt: $capital"),
              Text("Kontinent: $continent"),
              Text("Einwohner: $population"),
              Text("Fläche (km²): $area"),
              Text("Sprachen: $languages"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Schließen", 
            style: TextStyle(color: Colors.deepOrange),
            ),
          ),
        ],
      ),
    );
  }
  

  @override
  void initState() {
    super.initState();
    loadCountries();
    searchController.addListener(filterCountries);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Learn Countries';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.amber[50],
        body: CustomScrollView(
          slivers: [
            // collapsible app bar integrated into the scrollable view.
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.amber[800],
              expandedHeight: 50,
              title: const Text(title, style: TextStyle(color: Colors.white)),
              
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Text(
                      "view",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                // Popup menu for display mode selection
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    setState(() {
                      displayMode = value;
                    });
                  },
                  icon: const Icon(Icons.view_compact),
                  tooltip: "Select display mode",
                  itemBuilder:
                      (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: "list",
                          child: Text("List"),
                        ),
                        const PopupMenuItem<String>(
                          value: "grid",
                          child: Text("Grid"),
                        ),
                        const PopupMenuItem<String>(
                          value: "flashcard",
                          child: Text("Flashcard"),
                        ),
                      ],
                ),
              ],
            ),
            //Dropdown for continent filtering.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Text("Region : "),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: selectedContinent,
                      items:
                          continents.map((String cont) {
                            return DropdownMenuItem<String>(
                              value: cont,
                              child: Text(cont),
                            );
                          }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            selectedContinent = value;
                          });
                          filterCountries();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            // TextField for searching countries.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Countries',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ),
            //Display countries based on selected display mode.
            filteredCountries.isEmpty
                ? const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
                : displayMode == "grid"
                ? SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate((
                    BuildContext context,
                    int index,) {
                    final country = filteredCountries[index];
                    
                    // wrap grid item with tap to show Countries Details
                    return
                    InkWell(
                      onTap: () => _showCountryDetails(country),
                      child: CountryItemGrid(index: index, country: country),
                    );
                  }, childCount: filteredCountries.length),
                )
                : displayMode == "flashcard"
                ? SliverList(
                  delegate: SliverChildBuilderDelegate((
                    BuildContext context,
                    int index,
                  ) {
                    final country = filteredCountries[index];
                    

                    ///wrap flashcard item with tap to show Countries Details
                    return
                    InkWell(
                      onTap: ()=>_showCountryDetails(country),
                      child: CountryItemFlashcard(index: index, country: country),
                    );
                  }, childCount: filteredCountries.length),
                )
                : // Default list display
                SliverList(
                  delegate: SliverChildBuilderDelegate((
                    BuildContext context,
                    int index,
                  ) {
                    final country = filteredCountries[index];
                    
                    ///wrap flashcard item with tap to show Countries Details
                    return
                    InkWell(
                      onTap: ()=>_showCountryDetails(country),
                      child: CountryItemList(index: index, country: country),
                    );
                  }, childCount: filteredCountries.length),
                ),
          ],
        ),
      ),
    );
  }
}
