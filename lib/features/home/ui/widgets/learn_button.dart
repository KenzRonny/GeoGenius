import 'package:flutter/material.dart';
import '../../../lernen/ui/learn_page.dart';
class LearnButton extends StatelessWidget {
  const LearnButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context)=>LearnPage()),
        );
      },
      child: Container(
        width: 200,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            "Lernen",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}