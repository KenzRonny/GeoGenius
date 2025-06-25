import 'package:flutter/material.dart';
import 'package:geo_genius/features/home/ui/widgets/gameModeCard.dart';
import 'package:geo_genius/features/Guess_the_flag_multiple_choice/ui/multiple_choice_flags_page.dart';
import 'package:geo_genius/features/highscore_mode/ui/highscore_page.dart';
import 'package:geo_genius/features/ranked_mode/screens/ranked_lobby_screen.dart';

class GameModesOverview extends StatelessWidget {
  const GameModesOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Explore the World',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                GameModeCard(
                  title: 'Flag Frenzy',
                  imagePath: 'lib/assets/images/game_modes/flag_frenzy.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MultipleChoiceScreen(),
                      ),
                    );
                  },
                ),
                GameModeCard(
                  title: 'Daily Globe Trotter',
                  imagePath: 'lib/assets/images/game_modes/daily_globe_trotter.png',
                  onTap: () {},
                ),
                GameModeCard(
                  title: 'Capital Conquest',
                  imagePath: 'lib/assets/images/game_modes/capital_conquest.png',
                  onTap: () {},
                ),
                GameModeCard(
                  title: 'World Explorer',
                  imagePath: 'lib/assets/images/game_modes/world_explorer.png',
                  onTap: () {},
                ),
                GameModeCard(
                  title: 'Highscore Hero',
                  imagePath: 'lib/assets/images/game_modes/highscore_hero.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HighscoreScreen(),
                      ),
                    );
                  },
                ),
                GameModeCard(
                  title: 'Ranked Rival',
                  imagePath: 'lib/assets/images/game_modes/ranked_rival.png',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RankedRivalPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
