import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geo_genius/features/home/ui/home_page.dart';
import 'package:geo_genius/features/ranked_mode/screens/game_screen.dart';
import 'package:geo_genius/features/ranked_mode/screens/start_new_game.dart';

class RankedRivalPage extends StatelessWidget {
  const RankedRivalPage({super.key});

  Widget buildMatchItem(String opponent, String status, VoidCallback onTap, {String? subtitle}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F2F0),
            borderRadius: BorderRadius.circular(8),
          ),
          width: 48,
          height: 48,
          child: const Icon(Icons.sports_esports, color: Color(0xFF181411)),
        ),
        title: Text('Spiel gegen $opponent', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: Text(status, style: const TextStyle(color: Color(0xFF181411))),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF181411)),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder:(_) => MyHomePage())),
        ),
        title: Text('Ranked Rival', style: theme.textTheme.titleLarge?.copyWith(color: const Color(0xFF181411))),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser?.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text('Profil konnte nicht geladen werden.');
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  final name = userData['name'] ?? 'Unbekannt';
                  final avatarUrl = userData['avatarUrl'] ?? '';
                  final rankedPoints = userData['rankedPoints'] ?? 0;
                  String rank;
                  if (rankedPoints >= 200) {
                    rank = 'Gold 🥇';
                  } else if (rankedPoints >= 100) {
                    rank = 'Silber 🥈';
                  } else if (rankedPoints >=1) {
                    rank = 'Bronze 🥉';
                  } else { rank = ''; }


                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : const AssetImage('lib/assets/default_avatar.png') as ImageProvider,
                      ),
                      const SizedBox(height: 12),
                      Text(name, style: theme.textTheme.titleLarge),
                      Text('Rang $rank', style: theme.textTheme.titleMedium),
                      Text('$rankedPoints Punkte', style: theme.textTheme.titleMedium),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1A059),
                    foregroundColor: const Color(0xFF181411),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StartNewGameScreen()),
                    );
                  },
                  child: const Text('Neues Spiel starten'),
                ),
              ),
              const SizedBox(height: 20),
              Text('Aktive Spiele', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('matches')
                    .where('players.player1.id', isEqualTo: currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot1) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('matches')
                        .where('players.player2.id', isEqualTo: currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot2) {
                      if (!snapshot1.hasData || !snapshot2.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final docs = [...snapshot1.data!.docs, ...snapshot2.data!.docs];
                      final uniqueDocs = {
                        for (var d in docs) d.id: d,
                      }.values.toList();

                      final active = uniqueDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['status'] == 'playing';
                      }).toList();

                      final finished = uniqueDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['status'] == 'finished';
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (active.isEmpty)
                            const Text('Keine aktiven Spiele.', style: TextStyle(color: Colors.grey)),
                          ...active.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final opponent = currentUser?.uid == data['players']['player1']['id']
                                ? (data['players']['player2']?['name'] ?? 'Gegner gesucht')
                                : (data['players']['player1']?['name'] ?? 'Gegner gesucht');

                            return buildMatchItem(opponent, 'Läuft', () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => GameScreen(matchId: doc.id)),
                              );
                            });
                          }),
                          const SizedBox(height: 20),
                          Text('Abgeschlossene Spiele', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          if (finished.isEmpty)
                            const Text('Noch keine abgeschlossenen Spiele.', style: TextStyle(color: Colors.grey)),
                          ...finished.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final score1 = data['players']['player1']['score'];
                            final score2 = data['players']['player2']['score'];
                            final players = data['players'];

                            final isPlayer1 = currentUser?.uid == players['player1']['id'];
                            final myScore = isPlayer1 ? score1 : score2;
                            final opponentScore = isPlayer1 ? score2 : score1;

                            final opponent = isPlayer1
                                ? (players['player2']?['name'] ?? 'Gegner gesucht')
                                : (players['player1']?['name'] ?? 'Gegner gesucht');

                            String result = 'Unentschieden';
                            if (score1 != null && score2 != null) {
                              if ((isPlayer1 && score1 > score2) || (!isPlayer1 && score2 > score1)) {
                                result = 'Gewonnen';
                              } else if (score1 != score2) {
                                result = 'Verloren';
                              }
                            }

                            final subtitle = 'Du: $myScore – Gegner: $opponentScore';
                            return buildMatchItem(opponent, result, () {}, subtitle: subtitle);
                          }),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
