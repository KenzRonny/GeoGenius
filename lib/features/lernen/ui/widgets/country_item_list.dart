import 'package:flutter/material.dart';

class CountryItemList extends StatelessWidget {
  final int index;
  final dynamic country;

  const CountryItemList({
    super.key,
    required this.index,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    // Retrieve country's name, capital, and flag URL.
    final String name = country["translations"]["deu"]["common"] ?? "Unknown";
    final dynamic capitalData = country["capital"];
    List<dynamic> capitalList = [];
    if (capitalData is List) {
      capitalList = capitalData;
    } else if (capitalData is String) {
      capitalList = [capitalData];
    } else {
      capitalList = [];
    }
    final String capital = (capitalList.isNotEmpty)
        ? capitalList.first.toString()
        : "No capital";
    final String flagUrl = country["flags"]?["png"] ?? "";
    
    return ListTile(
      leading: SizedBox(
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
  }
}
