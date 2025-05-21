import 'package:flutter/material.dart';

class CountryItemGrid extends StatelessWidget {
  final int index;
  final dynamic country;

  const CountryItemGrid({
    super.key,
    required this.index,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    // Retrieve country's name and flag URL.
    final String name = country["translations"]["deu"]["common"] ?? "Unknown";
    final String flagUrl = country["flags"]?["png"] ?? "";
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            flagUrl.isNotEmpty
                ? Image.network(flagUrl, width: 80, height: 80)
                : const Icon(Icons.flag, size: 80),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
