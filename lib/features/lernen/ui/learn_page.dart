import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Provides rootBundle for loading assets

class LearnPage extends StatelessWidget {
 const LearnPage({super.key});

  /// Asynchronously loads the JSON file containing the countries' data from the assets.
  Future<List<dynamic>> loadCountries() async {
    // Load the JSON content as a string from the assets directory.
    String jsonString = await rootBundle.loadString('assets/json/countries/countries.json');
    // Decode the JSON string into a List of dynamic objects.
    final List<dynamic> jsonData = jsonDecode(jsonString);
    return jsonData;
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
            // SliverToBoxAdapter allows insertion of a normal widget into the sliver list.
            SliverToBoxAdapter(
              child: FutureBuilder<List<dynamic>>(
                future: loadCountries(),
                builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                  // While waiting for the asynchronous call to complete, show a loading indicator.
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    // If an error occurred, display the error message.
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    // If the data is empty, display a message indicating no data was found.
                    return const Center(child: Text("No data found"));
                  } else {
                    // build a ListView to display the country information.
                    final countries = snapshot.data!;
                    // Sort the countries alphabetically by the common name.
                    countries.sort((a, b) => 
                      (a["name"]["common"] as String).compareTo(b["name"]["common"] as String)
                    );
                    return ListView.builder(
                      shrinkWrap: true, // Allows the ListView to size itself according to its content.
                      // Disable internal scrolling since CustomScrollView handles scrolling.
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: countries.length,
                      itemBuilder: (context, index) {
                        final country = countries[index];
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
                          leading: flagUrl.isNotEmpty
                              ? Image.network(flagUrl, width: 50, height: 50)
                              : const Icon(Icons.flag),
                          title: Text(name),
                          subtitle: Text("Capital: $capital"),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
