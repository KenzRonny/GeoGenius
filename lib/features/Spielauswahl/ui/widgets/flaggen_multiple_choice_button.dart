import 'package:flutter/material.dart';


class MultipleChoiceFlags extends StatelessWidget{
  final String gameMode;
  const MultipleChoiceFlags({
  super.key,
    required this.gameMode,
});
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
        //Navigator.push(context,MaterialPageRoute(builder: (context)=>FlagsMultipleChoice()),
       // print('Flags Multiple Choice');

      },

    ),
    );
  }
}
