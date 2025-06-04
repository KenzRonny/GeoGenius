
import 'package:flutter/material.dart';

import 'widgets/logout_button.dart';
import 'dart:math';
import 'package:geo_genius/features/home/data/countries_data.dart';

class MultipleChoiceScreen extends StatefulWidget{
  const MultipleChoiceScreen ({super.key});
  @override
  _MultipleChoiceScreenState createState() => _MultipleChoiceScreenState();

}


class _MultipleChoiceScreenState extends State<MultipleChoiceScreen>{
  void _logout(BuildContext context){
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ausgeloggt')),
    );
  }
  late String correctCountry;
  late String flagPath;
  late List<String> options;
  Map<String, Color> boxColors = {};
  int streak = 0;
  @override
  void initState(){
    super.initState();
    _generateQuestion();
  }
  void _generateQuestion(){
    final random = Random();
    final countries = CountryData.countries.keys.toList();
    final flagCountry = countries[random.nextInt(countries.length)];
    final flag = CountryData.countries[flagCountry]!;
    correctCountry = flagCountry;
    flagPath = 'lib/features/Guess_the_flag_multiple_choice/assets/flags/$flag';

    final wrongOptions = <String>{};
    while(wrongOptions.length < 3){
      final wrongCountry = countries[random.nextInt(countries.length)];
      if(wrongCountry != correctCountry){
        wrongOptions.add(wrongCountry);
      }
    }
    options = [correctCountry,...wrongOptions];
    options.shuffle();
    boxColors ={for(var option in options) option: Colors.blue};


  }
  void _checkAnswer(String selectedCountry){
    if(selectedCountry == correctCountry){

      setState(() {
        boxColors[selectedCountry] = Colors.green;
        streak++;
      });
    }else {

      setState(() {
        boxColors[selectedCountry] = Colors.red;
        boxColors[correctCountry] = Colors.green;
        streak = 0;
      });

    }
    Future.delayed(Duration(seconds: 1),() {
      setState(() {
        _generateQuestion();
      });
    });

  }
  @override
  Widget build(BuildContext context){
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
          title: Text('Multiple Choice Flaggen',
          style:TextStyle(color: Colors.white),
          ),
        leading: IconButton(icon: const Icon(Icons.arrow_back),
          onPressed: (){
          Navigator.pop(context);
          },
        ),
        actions: [
          LogoutButton(onLogout: () => _logout(context)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(

          children:[
            Row(
              children: [
            Container(
              width: screenSize.width *0.17,
              height:120,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width:1),
              ),
              alignment: Alignment.center,
              child:Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Streak',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$streak',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                ],

              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Container(
              width: double.infinity,
              height: 150,


            child:Image.asset(
              flagPath,

              fit: BoxFit.contain,
              alignment: Alignment.center,

            ),

              ),
            ),
            ],
        ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2,
            crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: screenSize.height * 0.2,
              ),
              itemCount: options.length,
              itemBuilder: (context,index){
                final option = options[index];


                  return GestureDetector(
                    onTap: () => _checkAnswer(option),
                    child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: boxColors[option],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width:1),
                    ),
                    alignment: Alignment.center,


                    child:Text(
                      option,
                      style: TextStyle(fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    ),

                  );
                },
            ),
          ),
        ],

      ),
    ),





    );
  }
}
