import 'package:flutter/material.dart';
import 'package:geo_genius/features/Guess_the_flag_multiple_choice/ui/multiple_choice_flags_page.dart';
import 'package:geo_genius/features/highscore_mode/ui/highscore_page.dart';
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
    final List<Map<String, dynamic>> gameModes = [
      {
        'title': 'Guess the Flag: Multiple Choice',
        'page': () => const MultipleChoiceScreen(),
      },
      {
        'title': 'Highscore Mode',
        'page': () => const HighscoreScreen(),
      },
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
                return ListTile(
                    title: Text(gameModes[index]['title']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => gameModes[index]['page'](),
                        ),
                      );
                    }
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