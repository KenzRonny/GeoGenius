import 'package:flutter/material.dart';
import '../../../Guess_the_flag_multiple_choice/ui/multiple_choice_flags_page.dart';

import '../../../click_on_map_country/ui/click_on_map_country_page.dart';

class MultipleChoiceFlags extends StatelessWidget{
  final String gameMode;
  const MultipleChoiceFlags({
  Key? key,
    required this.gameMode,
}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10,horizontal: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
      title: Center(
        child:Text(gameMode),
      ),
      onTap: (){
          if(gameMode == 'Guess the Flag: Multiple Choice'){
    Navigator.push(context,MaterialPageRoute(builder: (context)=>MultipleChoiceScreen()),
    );
    }

          else if(gameMode == 'Guess the Country via Map'){
            Navigator.push(context,MaterialPageRoute(builder: (context)=>ClickOnMapPage()),
    );

    }




      },

    ),
    );
  }
}
