import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //for loading assets

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

   //loads the JSON file containing the countries' data from the assets.
  Future<void> loadCountries() async {
    // Load the JSON content as a string from the assets directory.
    String jsonString = await rootBundle.loadString('assets/json/countries/countries.json');
    // Decode the JSON string into a List of dynamic objects.
    final List<dynamic> jsonData = jsonDecode(jsonString);
    jsonData.sort((a, b) => (a["name"]["common"] as String).compareTo(b["name"]["common"] as String));
    setState(() {
      allCountries = jsonData;
      filteredCountries = jsonData;
    });
  }

  void filterCountries() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredCountries = allCountries.where((country) {
        final String name = (country["name"]["common"] as String).toLowerCase();
        return name.contains(query);
      }).toList();
    });
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
        body: CustomScrollView(
          slivers: [
            // collapsible app bar integrated into the scrollable view.
            SliverAppBar(
              pinned: true,
              backgroundColor: Theme.of(context).primaryColor,
              expandedHeight: 50,
              title: const Text(
                title,
                style: TextStyle(color: Colors.white),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
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
            filteredCountries.isEmpty
                ? const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final country = filteredCountries[index];
                        // Extract the country's name using the JSON structure.
                        final String name = country["name"]?["common"] ?? "Unknown";
                        // Extract the capital as a list, if available.
                        final List? capitalList = country["capital"] as List?;
                        final String capital = (capitalList != null && capitalList.isNotEmpty)
                            ? capitalList.first
                            : "No capital";
                        // Get the URL for the country's flag image.
                        final String flagUrl = country["flags"]?["png"] ?? "";
                        return ListTile(
                          leading: Container(
                            width: 83,
                            child: Row(
                              children: [
                                Text(
                                  '${index + 1}.',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                flagUrl.isNotEmpty
                                    ? Image.network(flagUrl, width: 50, height: 50)
                                    : const Icon(Icons.flag),
                              ],
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text("Capital: $capital"),
                        );
                      },
                      childCount: filteredCountries.length,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
