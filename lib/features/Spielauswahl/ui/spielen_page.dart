import 'package:flutter/material.dart';
//import 'package:geo_genius/features/home/ui/widgets/logout_button.dart';
//import '../../home/ui/widgets/logout_button.dart';
import 'widgets/logout_button.dart';
import 'widgets/flaggen_multiple_choice_button.dart';



class SpielenPage extends StatelessWidget{
  const SpielenPage({super.key});
  void _logout(BuildContext context){
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ausgeloggt')),
    );

  }

  @override
  Widget build(BuildContext context) {
    const title = 'Spielmodie';
    final List<String> gameModes = [
      'Guess the Flag: Multiple Choice'
    ];
    return MaterialApp(
      title: title,
      home: Scaffold(
      body:CustomScrollView(
        slivers:[
           SliverAppBar(
            pinned: true,
             backgroundColor: Theme.of(context).primaryColor,
              expandedHeight: 50,
              title: Text(
                title,
                style:TextStyle(color:Colors.white),
              ),
             leading: IconButton(
               icon: const Icon(Icons.arrow_back),
               color: Colors.white,// Zurück-Pfeil
               onPressed: () {
                 Navigator.pop(context); // Zurück zur vorherigen Seite
               },
             ),
              actions: [
                LogoutButton(
                    onLogout: () => _logout(context)
                ),
              ],
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context,int index){
                return MultipleChoiceFlags(
                    gameMode: gameModes[index],
                  );


                  },
                  childCount: gameModes.length,
                ),
              ),
            ],
          ),
        ),
      );
  }
}